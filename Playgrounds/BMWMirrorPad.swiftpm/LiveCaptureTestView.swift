import SwiftUI

struct LiveCaptureTestView: View {
    @StateObject private var captureManager =
        PlaygroundCaptureManager()

    @StateObject private var playerManager =
        PlaygroundAirPlayPlayer()

    @State private var didLoadLiveURL = false

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
                loadLiveStreamIfNeeded()
            } else {
                didLoadLiveURL = false
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
                        "تشغيل Live HLS",
                        systemImage:
                            "dot.radiowaves.left.and.right"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!captureManager.hlsReady)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
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
