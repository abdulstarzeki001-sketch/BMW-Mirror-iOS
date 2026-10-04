import SwiftUI
import AVKit

struct LiveCaptureTestView: View {
    @StateObject private var captureManager =
        PlaygroundCaptureManager()

    @StateObject private var playerManager =
        PlaygroundAirPlayPlayer()

    @State private var didLoadLiveURL = false
    @State private var validationStatus = "بانتظار HLS"
    @State private var validationDetails = "—"
    @State private var validationPassed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Live Capture → AirPlay")
                    .font(.title2.bold())
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                Text("هذا الاختبار يلتقط محتوى BMW Mirror Pad نفسه عبر ReplayKit، يحوله إلى H.264/HLS محلي (فيديو فقط حاليًا)، ثم يشغله عبر AVPlayer ويخرجه إلى AirPlay.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                animatedCaptureTarget
                captureStatusCard
                hlsMetricsCard
                airPlayCard

                if let errorText = captureManager.errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding()
                        .background(.red.opacity(0.08))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                }

                ShareLink(item: liveDiagnosticReport) {
                    Label(
                        "مشاركة تقرير Live HLS",
                        systemImage: "square.and.arrow.up"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                Text("النجاح الكامل هنا يعني أن شاشة الاختبار المتحركة تظهر على مستقبل AirPlay، مع External Playback = نشط وExternal HLS Requests > 0.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .padding()
        }
        .navigationTitle("Live Capture Test")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: captureManager.hlsReady) {
            _, ready in

            if ready {
                validateAndAutoplay()
            } else {
                didLoadLiveURL = false
                validationPassed = false
                validationStatus = "بانتظار HLS"
                validationDetails = "—"
            }
        }
        .onDisappear {
            playerManager.stop()
            captureManager.shutdown()
        }
    }

    private var animatedCaptureTarget: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0
            )
        ) { context in
            let value =
                context.date
                .timeIntervalSinceReferenceDate

            let progress =
                value.truncatingRemainder(
                    dividingBy: 4
                ) / 4

            VStack(spacing: 12) {
                HStack {
                    Text("LIVE CAPTURE TARGET")
                        .font(.headline.monospaced())

                    Spacer()

                    Text(
                        context.date,
                        style: .timer
                    )
                    .font(.body.monospacedDigit())
                }

                GeometryReader { proxy in
                    let width =
                        max(
                            proxy.size.width - 70,
                            1
                        )

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.secondary.opacity(0.18))

                        RoundedRectangle(
                            cornerRadius: 12
                        )
                        .fill(.primary)
                        .frame(
                            width: 70,
                            height: 26
                        )
                        .offset(
                            x: width * progress
                        )
                    }
                }
                .frame(height: 26)

                HStack {
                    ForEach(
                        0..<8,
                        id: \.self
                    ) { index in
                        RoundedRectangle(
                            cornerRadius: 4
                        )
                        .fill(
                            index.isMultiple(of: 2)
                                ? .primary
                                : .secondary
                        )
                        .frame(height: 28)
                    }
                }
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )
        }
    }

    private var captureStatusCard: some View {
        VStack(spacing: 10) {
            metricRow(
                "ReplayKit",
                captureManager.isReplayKitAvailable
                    ? "متاح"
                    : "غير متاح"
            )

            metricRow(
                "Capture",
                captureManager.isCapturing
                    ? "يعمل"
                    : "متوقف"
            )

            metricRow(
                "Status",
                captureManager.statusText
            )

            metricRow(
                "Video frames",
                "\(captureManager.capturedVideoFrames)"
            )

            metricRow(
                "Audio buffers",
                "\(captureManager.capturedAudioBuffers) (غير مستخدمة في HLS)"
            )

            Button {
                captureManager.toggleCapture()
            } label: {
                Label(
                    captureManager.isCapturing
                        ? "إيقاف الالتقاط"
                        : "بدء Live Capture",
                    systemImage:
                        captureManager.isCapturing
                        ? "stop.fill"
                        : "record.circle"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(captureManager.isBusy)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private var hlsMetricsCard: some View {
        VStack(spacing: 10) {
            metricRow(
                "HLS Ready",
                captureManager.hlsReady
                    ? "نعم"
                    : "لا"
            )

            metricRow(
                "Self Validation",
                validationStatus
            )

            metricRow(
                "Validation Details",
                validationDetails
            )

            metricRow(
                "First Ready",
                captureManager.firstReadyLatencyText
            )

            metricRow(
                "Segments",
                "\(captureManager.segmentCount)"
            )

            metricRow(
                "Buffer",
                ByteCountFormatter.string(
                    fromByteCount:
                        Int64(captureManager.bufferBytes),
                    countStyle: .file
                )
            )

            metricRow(
                "HTTP Requests",
                "\(captureManager.httpRequests)"
            )

            metricRow(
                "Media Requests",
                "\(captureManager.mediaRequests)"
            )

            metricRow(
                "External HLS Requests",
                "\(captureManager.externalClientRequests)"
            )

            metricRow(
                "Last Client",
                captureManager.lastClientEndpoint
            )

            metricRow(
                "Last Path",
                captureManager.lastRequestPath
            )

            metricRow(
                "Init Bytes",
                "\(captureManager.initializationBytes)"
            )

            metricRow(
                "Latest Segment Bytes",
                "\(captureManager.latestSegmentBytes)"
            )

            if let url = captureManager.playbackURL {
                Text(url.absoluteString)
                    .font(.caption2.monospaced())
                    .textSelection(.enabled)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private var airPlayCard: some View {
        VStack(spacing: 12) {
            if validationPassed {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Local Preview")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    VideoPlayer(player: playerManager.player)
                        .frame(minHeight: 220)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                        .onAppear {
                            playerManager.ensurePlayback()
                        }
                }
            }
            metricRow(
                "Player",
                playerManager.itemStatusText
            )

            metricRow(
                "Playback",
                playerManager.isPlaying
                    ? "يعمل"
                    : "متوقف"
            )

            metricRow(
                "Playback State",
                playerManager.playbackStateText
            )

            metricRow(
                "Player Rate",
                playerManager.playerRateText
            )

            metricRow(
                "Current Time",
                playerManager.currentTimeText
            )

            metricRow(
                "Waiting Reason",
                playerManager.waitingReasonText
            )

            metricRow(
                "External Playback",
                playerManager.isExternalPlaybackActive
                    ? "نشط"
                    : "غير نشط"
            )

            metricRow(
                "Keep Up",
                playerManager.isPlaybackLikelyToKeepUp
                    ? "نعم"
                    : "لا"
            )

            metricRow(
                "Stalls",
                "\(playerManager.playbackStallCount)"
            )

            metricRow(
                "Player Error Details",
                playerManager.errorDetailsText
            )

            if let playerError = playerManager.errorText {
                Text("AVPlayer: \(playerError)")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .textSelection(.enabled)
            }

            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    PlaygroundAirPlayRoutePicker()
                        .frame(
                            width: 58,
                            height: 48
                        )

                    Text("AirPlay")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    loadLiveStreamIfNeeded()

                    if !playerManager.isPlaying {
                        playerManager.togglePlayback()
                    }
                } label: {
                    Label(
                        validationPassed
                            ? "إعادة تشغيل عند الحاجة"
                            : "بانتظار التحقق الذاتي",
                        systemImage:
                            "dot.radiowaves.left.and.right"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!validationPassed)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }

    private func validateAndAutoplay() {
        guard
            !didLoadLiveURL,
            let url = captureManager.playbackURL
        else {
            return
        }

        validationStatus = "جارٍ التحقق الذاتي…"
        validationDetails = "master/media/init/segment/AVFoundation"

        Task {
            let result =
                await PlaygroundHLSValidator.validate(
                    masterURL: url
                )

            await MainActor.run {
                validationPassed = result.passed
                validationStatus = result.message
                validationDetails = result.details

                guard result.passed else {
                    return
                }

                playerManager.load(
                    url: url,
                    label: "iPad Live Capture HLS"
                )
                playerManager.play()
                didLoadLiveURL = true
            }
        }
    }

    private func loadLiveStreamIfNeeded() {
        guard
            !didLoadLiveURL,
            let url = captureManager.playbackURL
        else {
            return
        }

        playerManager.load(
            url: url,
            label: "iPad Live Capture HLS"
        )

        didLoadLiveURL = true
    }

    private var liveDiagnosticReport: String {
        """
        BMW Mirror Pad — Live HLS Diagnostic
        ====================================
        Time: \(ISO8601DateFormatter().string(from: Date()))

        Capture
        -------
        Capturing: \(captureManager.isCapturing)
        Video frames: \(captureManager.capturedVideoFrames)
        Audio buffers: \(captureManager.capturedAudioBuffers)

        HLS
        ---
        Ready: \(captureManager.hlsReady)
        Validation status: \(validationStatus)
        Validation details: \(validationDetails)
        First ready: \(captureManager.firstReadyLatencyText)
        Segments: \(captureManager.segmentCount)
        Buffer bytes: \(captureManager.bufferBytes)
        Init bytes: \(captureManager.initializationBytes)
        Latest segment bytes: \(captureManager.latestSegmentBytes)
        HTTP requests: \(captureManager.httpRequests)
        Media requests: \(captureManager.mediaRequests)
        External HLS requests: \(captureManager.externalClientRequests)
        Last client: \(captureManager.lastClientEndpoint)
        Last path: \(captureManager.lastRequestPath)
        URL: \(captureManager.playbackURL?.absoluteString ?? "—")

        Player
        ------
        Item: \(playerManager.itemStatusText)
        Playing: \(playerManager.isPlaying)
        Playback state: \(playerManager.playbackStateText)
        Player rate: \(playerManager.playerRateText)
        Current time: \(playerManager.currentTimeText)
        Waiting reason: \(playerManager.waitingReasonText)
        External: \(playerManager.isExternalPlaybackActive)
        Keep up: \(playerManager.isPlaybackLikelyToKeepUp)
        Stalls: \(playerManager.playbackStallCount)
        Error: \(playerManager.errorText ?? "—")
        Error details: \(playerManager.errorDetailsText)

        Media playlist
        --------------
        \(captureManager.playlistText)
        """
    }

    private func metricRow(
        _ title: String,
        _ value: String
    ) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 14)

            Text(value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.footnote)
    }
}
