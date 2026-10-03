import SwiftUI
import AVKit

struct LiveAirPlayBridgeView: View {
    @ObservedObject var captureManager: ScreenCaptureManager
    @StateObject private var playerManager = AirPlayVideoManager(prepareProbeOnInit: false)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Live Capture → AirPlay")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("BMW Mirror يحول الإطارات الحية إلى fragmented MP4/HLS داخل التطبيق، ويقدّمها عبر خادم HTTP محلي ليتم تشغيلها بواسطة AVPlayer ثم اختيار AirPlay.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                bridgeStatusCard

                VideoPlayer(player: playerManager.player)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(spacing: 12) {
                    row("Capture", captureManager.isCapturing ? "يعمل" : "متوقف")
                    row("HLS Bridge", captureManager.liveBridgeStatusText)
                    row("Segments", "\(captureManager.liveHLSSegmentCount)")
                    row("Buffer", byteText(captureManager.liveHLSBytes))
                    row("Player Item", playerManager.playerItemStatusText)
                    row(
                        "External Playback",
                        playerManager.isExternalPlaybackActive ? "نشط" : "غير نشط"
                    )
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

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

                if let errorText = playerManager.errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Text("هذه مرحلة Bridge تجريبية. نجاح التشغيل داخل AVPlayer لا يثبت أن مستقبل AirPlay في السيارة يستطيع الوصول إلى خادم HLS المحلي؛ لذلك لا نعتبر CarPlay mirroring مكتملًا إلا بعد اختبار External Playback على جهاز فعلي.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("Live AirPlay Bridge")
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

    private var bridgeStatusCard: some View {
        HStack(spacing: 14) {
            Image(
                systemName: captureManager.liveHLSReady
                    ? "checkmark.circle.fill"
                    : "clock.fill"
            )
            .font(.title2)
            .foregroundStyle(captureManager.liveHLSReady ? .green : .orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Live HLS")
                    .font(.headline)

                Text(
                    captureManager.liveHLSReady
                        ? "جاهز لـ AVPlayer"
                        : "بانتظار أول HLS segment"
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
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.footnote)
    }
}

#Preview {
    NavigationStack {
        LiveAirPlayBridgeView(
            captureManager: ScreenCaptureManager()
        )
    }
}
