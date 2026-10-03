import SwiftUI
import AVKit

struct LiveAirPlayBridgeView: View {
    @ObservedObject var captureManager: ScreenCaptureManager
    @StateObject private var playerManager = AirPlayVideoManager(prepareProbeOnInit: false)
    @StateObject private var validationManager = AirPlayValidationManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Live Capture → AirPlay")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("المسار الحالي: Capture → HLS → AVPlayer → AirPlay. هذه الصفحة تعرض مؤشرات فعلية تساعدنا نعرف هل مستقبل AirPlay الخارجي وصل إلى البث أم لا.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                validationStatusCard

                VideoPlayer(player: playerManager.player)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                SectionCard(title: "Live HLS") {
                    row("Capture", captureManager.isCapturing ? "يعمل" : "متوقف")
                    row("Bridge", captureManager.liveBridgeStatusText)
                    row("First ready", captureManager.liveHLSFirstReadyLatencyText)
                    row("Segments", "\(captureManager.liveHLSSegmentCount)")
                    row("Buffer", byteText(captureManager.liveHLSBytes))
                    row("HTTP requests", "\(captureManager.liveHLSTotalRequests)")
                    row("Playlist requests", "\(captureManager.liveHLSPlaylistRequests)")
                    row("Media requests", "\(captureManager.liveHLSMediaRequests)")
                    row("External-client requests", "\(captureManager.liveHLSExternalClientRequests)")
                    row("Served", byteText(captureManager.liveHLSServedBytes))
                    row("Last client", captureManager.liveHLSLastClientEndpoint)
                    row("Last path", captureManager.liveHLSLastRequestPath)
                }

                SectionCard(title: "AVPlayer / AirPlay") {
                    row("Player Item", playerManager.playerItemStatusText)
                    row("Playback", playerManager.isPlaying ? "يعمل" : "متوقف")
                    row(
                        "Keep Up",
                        playerManager.isPlaybackLikelyToKeepUp ? "نعم" : "لا"
                    )
                    row("Stalls", "\(playerManager.playbackStallCount)")
                    row(
                        "External Playback",
                        playerManager.isExternalPlaybackActive ? "نشط" : "غير نشط"
                    )
                    row(
                        "External transition",
                        playerManager.externalPlaybackTransitionText
                    )
                }

                SectionCard(title: "Route / Network") {
                    row("Route detector", validationManager.routeDetectionText)
                    row(
                        "Multiple routes",
                        validationManager.multipleRoutesDetected ? "نعم" : "لا"
                    )
                    row("Audio route", validationManager.currentAudioRouteText)
                    row("Network path", validationManager.networkPathText)
                    row("Interfaces", validationManager.networkInterfacesText)
                }

                if let url = captureManager.liveHLSPlaybackURL {
                    Text(url.absoluteString)
                        .font(.caption2.monospaced())
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("رابط Live HLS سيظهر بعد بدء الالتقاط وتشغيل الخادم المحلي.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 16) {
                    VStack(spacing: 8) {
                        AirPlayRoutePicker()
                            .frame(width: 56, height: 44)

                        Text("اختر AirPlay")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        loadLiveStream()
                    } label: {
                        Label("تحميل البث الحي", systemImage: "dot.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!captureManager.liveHLSReady)
                }

                HStack {
                    Button {
                        captureManager.toggleCapture()
                    } label: {
                        Label(
                            captureManager.isCapturing ? "إيقاف الالتقاط" : "بدء الالتقاط",
                            systemImage: captureManager.isCapturing ? "stop.fill" : "record.circle"
                        )
                    }
                    .disabled(captureManager.isBusy)

                    Spacer()

                    Button {
                        playerManager.togglePlayback()
                    } label: {
                        Label(
                            playerManager.isPlaying ? "إيقاف مؤقت" : "تشغيل",
                            systemImage: playerManager.isPlaying ? "pause.fill" : "play.fill"
                        )
                    }
                    .disabled(playerManager.player.currentItem == nil)
                }
                .buttonStyle(.bordered)

                ShareLink(
                    item: AirPlayValidationReport.make(
                        captureManager: captureManager,
                        playerManager: playerManager,
                        validationManager: validationManager
                    )
                ) {
                    Label("مشاركة تقرير AirPlay", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                if let errorText = playerManager.errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Text("إشارة النجاح القوية عند الاختبار الفعلي: External Playback يصبح نشطًا، وبنفس الوقت نرى طلبات HTTP من عميل خارجي أو دليل تشغيل من جهة المستقبل. بدون ذلك لا نعتبر الربط مع السيارة مثبتًا.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("Live AirPlay Validation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if captureManager.liveHLSReady {
                loadLiveStream()
            }
        }
        .onChange(of: captureManager.liveHLSReady) { _, ready in
            if ready {
                loadLiveStream()
            }
        }
        .onDisappear {
            playerManager.stop()
        }
    }

    private var validationStatusCard: some View {
        let strongSignal =
            playerManager.isExternalPlaybackActive &&
            captureManager.liveHLSExternalClientRequests > 0

        let partialSignal =
            playerManager.isExternalPlaybackActive ||
            captureManager.liveHLSExternalClientRequests > 0

        return HStack(spacing: 14) {
            Image(
                systemName: strongSignal
                    ? "checkmark.seal.fill"
                    : partialSignal
                        ? "exclamationmark.triangle.fill"
                        : "clock.fill"
            )
            .font(.title2)
            .foregroundStyle(
                strongSignal
                    ? .green
                    : partialSignal
                        ? .orange
                        : .secondary
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("External AirPlay Validation")
                    .font(.headline)

                Text(
                    strongSignal
                        ? "مؤشرات قوية على تشغيل خارجي"
                        : partialSignal
                            ? "إشارة جزئية — نحتاج تأكيد إضافي"
                            : "بانتظار اختبار مستقبل AirPlay"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func loadLiveStream() {
        guard let url = captureManager.liveHLSPlaybackURL else { return }

        playerManager.load(
            url: url,
            label: "BMW Mirror Live HLS"
        )
    }

    private func byteText(_ bytes: Int) -> String {
        ByteCountFormatter.string(
            fromByteCount: Int64(bytes),
            countStyle: .file
        )
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            Text(value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.footnote)
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        LiveAirPlayBridgeView(
            captureManager: ScreenCaptureManager()
        )
    }
}
