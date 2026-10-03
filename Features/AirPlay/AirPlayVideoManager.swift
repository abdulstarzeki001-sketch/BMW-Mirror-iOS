import Foundation
import AVFoundation

@MainActor
final class AirPlayVideoManager: ObservableObject {
    @Published private(set) var statusText = "جاهز لاختبار AirPlay"
    @Published private(set) var isPlaying = false
    @Published private(set) var isExternalPlaybackActive = false
    @Published private(set) var playerItemStatusText = "لم يبدأ"
    @Published private(set) var errorText: String?

    let player = AVPlayer()

    private var timer: Timer?
    private var currentItemObservation: NSKeyValueObservation?

    init() {
        configurePlayer()
        prepareProbe()
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
        currentItemObservation?.invalidate()
    }

    func prepareProbe() {
        errorText = nil

        guard let url = URL(string: AppConstants.airPlayProbeURL) else {
            statusText = "رابط الاختبار غير صالح"
            errorText = "تعذر تكوين رابط HLS التجريبي."
            return
        }

        let item = AVPlayerItem(url: url)
        observe(item: item)
        player.replaceCurrentItem(with: item)

        playerItemStatusText = "جارٍ التحضير"
        statusText = "تم تحميل فيديو HLS تجريبي لـ AirPlay"
    }

    func togglePlayback() {
        switch player.timeControlStatus {
        case .playing:
            player.pause()
        default:
            player.play()
        }

        refreshState()
    }

    func stop() {
        player.pause()
        player.seek(to: .zero)
        refreshState()
    }

    func refreshState() {
        isPlaying = player.timeControlStatus == .playing
        isExternalPlaybackActive = player.isExternalPlaybackActive

        if isExternalPlaybackActive {
            statusText = "AirPlay Video خارجي نشط"
        } else if isPlaying {
            statusText = "الفيديو يعمل محليًا — اختر AirPlay من زر المسار"
        } else if player.currentItem?.status == .readyToPlay {
            statusText = "الفيديو جاهز — اختر جهاز AirPlay"
        }
    }

    private func configurePlayer() {
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
        currentItemObservation?.invalidate()

        currentItemObservation = item.observe(
            \.status,
            options: [.initial, .new]
        ) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }

                switch item.status {
                case .unknown:
                    self.playerItemStatusText = "جارٍ التحضير"

                case .readyToPlay:
                    self.playerItemStatusText = "جاهز"
                    self.statusText = "فيديو AirPlay التجريبي جاهز"

                case .failed:
                    self.playerItemStatusText = "فشل"
                    self.statusText = "فشل تحميل فيديو الاختبار"
                    self.errorText = item.error?.localizedDescription ?? "خطأ غير معروف"

                @unknown default:
                    self.playerItemStatusText = "غير معروف"
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
                self?.refreshState()
            }
        }
    }
}
