import Foundation
import AVFoundation

@MainActor
final class AirPlayVideoManager: ObservableObject {
    @Published private(set) var statusText = "جاهز لاختبار AirPlay"
    @Published private(set) var isPlaying = false
    @Published private(set) var playbackStateText = "متوقف"
    @Published private(set) var waitingReasonText = "—"
    @Published private(set) var currentTimeText = "0.0 s"
    @Published private(set) var playerRateText = "0.0"
    @Published private(set) var isExternalPlaybackActive = false
    @Published private(set) var isPlaybackLikelyToKeepUp = false
    @Published private(set) var playbackStallCount = 0
    @Published private(set) var playerItemStatusText = "لم يبدأ"
    @Published private(set) var currentSourceLabel = "لا يوجد مصدر"
    @Published private(set) var externalPlaybackTransitionText = "لم يبدأ"
    @Published private(set) var errorText: String?
    @Published private(set) var errorDetailsText = "—"

    let player = AVPlayer()

    private var timer: Timer?
    private var currentItemObservation: NSKeyValueObservation?
    private var stalledObserver: NSObjectProtocol?
    private var previousExternalPlaybackState = false
    private var desiredPlayback = false
    private var lastPlayRequestAt = Date.distantPast

    init(prepareProbeOnInit: Bool = true) {
        configurePlayer()

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

        if prepareProbeOnInit {
            prepareProbe()
        }

        startMonitoring()
    }

    deinit {
        timer?.invalidate()
        currentItemObservation?.invalidate()

        if let stalledObserver {
            NotificationCenter.default.removeObserver(stalledObserver)
        }
    }

    func prepareProbe() {
        guard let url = URL(string: AppConstants.airPlayProbeURL) else {
            statusText = "رابط الاختبار غير صالح"
            errorText = "تعذر تكوين رابط HLS التجريبي."
            return
        }

        load(
            url: url,
            label: "Apple HLS Probe"
        )
    }

    func load(url: URL, label: String) {
        errorText = nil
        errorDetailsText = "—"
        currentSourceLabel = label
        playbackStallCount = 0
        previousExternalPlaybackState = false
        externalPlaybackTransitionText = "لم يبدأ"

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 0.5
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = true

        observe(item: item)
        player.replaceCurrentItem(with: item)

        playerItemStatusText = "جارٍ التحضير"
        statusText = "تم تحميل \(label)"
    }

    func play() {
        desiredPlayback = true
        requestImmediatePlayback()
    }

    func ensurePlayback() {
        desiredPlayback = true

        if player.currentItem?.status == .readyToPlay {
            seekNearLiveEdgeIfNeeded()
            requestImmediatePlayback()
        }
    }

    func togglePlayback() {
        if desiredPlayback || player.timeControlStatus == .playing {
            desiredPlayback = false
            player.pause()
        } else {
            desiredPlayback = true
            requestImmediatePlayback()
        }

        refreshState()
    }

    func stop() {
        desiredPlayback = false
        player.pause()
        refreshState()
    }

    func refreshState() {
        let timeControlStatus = player.timeControlStatus

        isPlaying = timeControlStatus == .playing
        currentTimeText = String(
            format: "%.1f s",
            max(CMTimeGetSeconds(player.currentTime()), 0)
        )
        playerRateText = String(
            format: "%.1f",
            player.rate
        )
        isExternalPlaybackActive = player.isExternalPlaybackActive
        isPlaybackLikelyToKeepUp =
            player.currentItem?.isPlaybackLikelyToKeepUp ?? false

        switch timeControlStatus {
        case .paused:
            playbackStateText = desiredPlayback
                ? "متوقف مؤقتًا — إعادة تشغيل تلقائية"
                : "متوقف"
            waitingReasonText = "—"

        case .waitingToPlayAtSpecifiedRate:
            playbackStateText = "ينتظر بدء التشغيل"
            waitingReasonText = Self.waitingReasonText(
                player.reasonForWaitingToPlay
            )

        case .playing:
            playbackStateText = "يعمل"
            waitingReasonText = "—"

        @unknown default:
            playbackStateText = "غير معروف"
            waitingReasonText = "—"
        }

        if isExternalPlaybackActive != previousExternalPlaybackState {
            previousExternalPlaybackState = isExternalPlaybackActive

            externalPlaybackTransitionText = isExternalPlaybackActive
                ? "تفعّل External Playback عند \(Self.clockText())"
                : "توقف External Playback عند \(Self.clockText())"

            if desiredPlayback {
                requestImmediatePlayback()
            }
        }

        if desiredPlayback,
           player.currentItem?.status == .readyToPlay,
           timeControlStatus == .paused,
           Date().timeIntervalSince(lastPlayRequestAt) > 1.0 {
            seekNearLiveEdgeIfNeeded()
            requestImmediatePlayback()
        }

        if isExternalPlaybackActive {
            statusText = "AirPlay Video خارجي نشط"
        } else if isPlaying {
            statusText = "\(currentSourceLabel) يعمل محليًا — اختر AirPlay"
        } else if timeControlStatus == .waitingToPlayAtSpecifiedRate {
            statusText = "\(currentSourceLabel) ينتظر: \(waitingReasonText)"
        } else if player.currentItem?.status == .readyToPlay {
            statusText = desiredPlayback
                ? "\(currentSourceLabel) يعيد بدء التشغيل"
                : "\(currentSourceLabel) جاهز — اختر جهاز AirPlay"
        }
    }

    private func configurePlayer() {
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        player.automaticallyWaitsToMinimizeStalling = false

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
                    self.statusText = "\(self.currentSourceLabel) جاهز"

                    if self.desiredPlayback {
                        self.requestImmediatePlayback()
                    }

                case .failed:
                    self.playerItemStatusText = "فشل"
                    self.statusText = "فشل تحميل \(self.currentSourceLabel)"

                    if let nsError = item.error as NSError? {
                        self.errorText = nsError.localizedDescription
                        self.errorDetailsText =
                            "\(nsError.domain) (\(nsError.code)): \(nsError.localizedDescription)"
                    } else {
                        self.errorText = "خطأ غير معروف"
                        self.errorDetailsText =
                            "AVPlayerItem failed without NSError"
                    }

                    if let event = item.errorLog()?.events.last {
                        let comment = event.errorComment ?? "—"
                        self.errorDetailsText +=
                            "\nLog domain=\(event.errorDomain) code=\(event.errorStatusCode) comment=\(comment)"
                    }

                @unknown default:
                    self.playerItemStatusText = "غير معروف"
                }
            }
        }
    }

    private func seekNearLiveEdgeIfNeeded() {
        guard
            let item = player.currentItem,
            let range = item.seekableTimeRanges.last?.timeRangeValue
        else {
            return
        }

        let liveEdge = CMTimeRangeGetEnd(range)
        let current = player.currentTime()
        let delta = CMTimeGetSeconds(
            CMTimeSubtract(liveEdge, current)
        )

        if delta.isFinite, delta > 3.0 {
            let target = CMTimeSubtract(
                liveEdge,
                CMTime(
                    seconds: 1.0,
                    preferredTimescale: 600
                )
            )

            player.seek(
                to: target,
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        }
    }

    private func requestImmediatePlayback() {
        lastPlayRequestAt = Date()

        guard let item = player.currentItem else {
            playbackStateText = "لا يوجد عنصر تشغيل"
            return
        }

        if item.status == .readyToPlay {
            player.playImmediately(atRate: 1.0)
        } else {
            player.play()
        }

        refreshState()
    }

    private static func waitingReasonText(
        _ reason: AVPlayer.WaitingReason?
    ) -> String {
        guard let reason else { return "غير محدد" }

        switch reason {
        case .toMinimizeStalls:
            return "انتظار لتقليل التوقف"
        case .noItemToPlay:
            return "لا يوجد عنصر تشغيل"
        case .evaluatingBufferingRate:
            return "تقييم معدل التخزين المؤقت"
        default:
            return reason.rawValue
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

    private static func clockText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
