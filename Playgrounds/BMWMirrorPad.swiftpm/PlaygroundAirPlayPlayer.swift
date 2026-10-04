import Foundation
import AVFoundation

@MainActor
final class PlaygroundAirPlayPlayer: ObservableObject {
    @Published private(set) var statusText = "جاهز"
    @Published private(set) var sourceLabel = "لا يوجد مصدر"
    @Published private(set) var itemStatusText = "لم يبدأ"
    @Published private(set) var isPlaying = false
    @Published private(set) var isExternalPlaybackActive = false
    @Published private(set) var isPlaybackLikelyToKeepUp = false
    @Published private(set) var playbackStallCount = 0
    @Published private(set) var externalTransitionText = "لم يبدأ"
    @Published private(set) var errorText: String?
    @Published private(set) var errorDetailsText = "—"

    let player = AVPlayer()

    private var timer: Timer?
    private var itemObservation: NSKeyValueObservation?
    private var stalledObserver: NSObjectProtocol?
    private var previousExternalState = false

    init() {
        configureAudioAndPlayer()

        stalledObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard
                    let self,
                    let item = notification.object as? AVPlayerItem,
                    item === self.player.currentItem
                else {
                    return
                }

                self.playbackStallCount += 1
                self.statusText = "توقف مؤقت في تدفق الفيديو"
            }
        }

        startMonitoring()
    }

    deinit {
        timer?.invalidate()
        itemObservation?.invalidate()

        if let stalledObserver {
            NotificationCenter.default.removeObserver(stalledObserver)
        }
    }

    func load(url: URL, label: String) {
        errorText = nil
        errorDetailsText = "—"
        sourceLabel = label
        playbackStallCount = 0
        previousExternalState = false
        externalTransitionText = "لم يبدأ"

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 1.5

        observe(item: item)
        player.replaceCurrentItem(with: item)

        itemStatusText = "جارٍ التحضير"
        statusText = "تم تحميل \(label)"
    }

    func loadAppleProbe() {
        guard let url = URL(
            string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"
        ) else {
            errorText = "تعذر إنشاء رابط Apple HLS."
            return
        }

        load(url: url, label: "Apple HLS Probe")
    }

    func togglePlayback() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }

        refresh()
    }

    func stop() {
        player.pause()
        player.seek(to: .zero)
        refresh()
    }

    func refresh() {
        isPlaying = player.timeControlStatus == .playing
        isExternalPlaybackActive = player.isExternalPlaybackActive
        isPlaybackLikelyToKeepUp = player.currentItem?.isPlaybackLikelyToKeepUp ?? false

        if isExternalPlaybackActive != previousExternalState {
            previousExternalState = isExternalPlaybackActive
            externalTransitionText = isExternalPlaybackActive
                ? "تفعّل عند \(Self.clockText())"
                : "توقف عند \(Self.clockText())"
        }

        if isExternalPlaybackActive {
            statusText = "External AirPlay نشط"
        } else if isPlaying {
            statusText = "\(sourceLabel) يعمل محليًا"
        } else if player.currentItem?.status == .readyToPlay {
            statusText = "\(sourceLabel) جاهز"
        }
    }

    private func configureAudioAndPlayer() {
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            errorText = "AVAudioSession: \(error.localizedDescription)"
        }
    }

    private func observe(item: AVPlayerItem) {
        itemObservation?.invalidate()

        itemObservation = item.observe(
            \.status,
            options: [.initial, .new]
        ) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }

                switch item.status {
                case .unknown:
                    self.itemStatusText = "جارٍ التحضير"

                case .readyToPlay:
                    self.itemStatusText = "جاهز"
                    self.statusText = "\(self.sourceLabel) جاهز"

                case .failed:
                    self.itemStatusText = "فشل"
                    self.statusText = "فشل تشغيل \(self.sourceLabel)"

                    if let nsError = item.error as NSError? {
                        self.errorText = nsError.localizedDescription
                        self.errorDetailsText =
                            "\(nsError.domain) (\(nsError.code)): \(nsError.localizedDescription)"
                    } else {
                        self.errorText = "خطأ غير معروف"
                        self.errorDetailsText = "AVPlayerItem failed without NSError"
                    }

                    if let event = item.errorLog()?.events.last {
                        let comment = event.errorComment ?? "—"
                        self.errorDetailsText +=
                            "\nLog domain=\(event.errorDomain) code=\(event.errorStatusCode) comment=\(comment)"
                    }

                @unknown default:
                    self.itemStatusText = "غير معروف"
                }
            }
        }
    }

    private func startMonitoring() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    private static func clockText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
