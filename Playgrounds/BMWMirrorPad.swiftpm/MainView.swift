import SwiftUI
import AVKit

struct MainView: View {
    @StateObject private var playerManager = PlaygroundAirPlayPlayer()
    @StateObject private var diagnostics = PlaygroundDiagnostics()

    @AppStorage("customHLSURL")
    private var customHLSURL = ""

    @State private var isProbing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard

                    NavigationLink {
                        LiveCaptureTestView()
                    } label: {
                        Label(
                            "Live Capture → AirPlay",
                            systemImage: "record.circle"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)

                    sourceCard

                    VideoPlayer(player: playerManager.player)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 20,
                                style: .continuous
                            )
                        )

                    playbackCard
                    networkCard
                    actionCard

                    if let errorText = playerManager.errorText {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.red.opacity(0.08))
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                            )
                    }

                    ShareLink(
                        item: diagnostics.makeReport(
                            player: playerManager,
                            customURL: customHLSURL
                        )
                    ) {
                        Label(
                            "مشاركة تقرير الاختبار",
                            systemImage: "square.and.arrow.up"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)

                    Text("هذه نسخة اختبار مخصصة للـiPad. تختبر HLS وAVPlayer وAirPlay والشبكة. لا تحتوي على Broadcast Upload Extension ولا CarPlay entitlement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("BMW Mirror Pad")
            .onAppear {
                if playerManager.player.currentItem == nil {
                    playerManager.loadAppleProbe()
                }
            }
            .onDisappear {
                playerManager.stop()
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "ipad.and.iphone")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("iPad Test Harness")
                        .font(.headline)

                    Text(diagnostics.deviceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack {
                statusPill(
                    title: "AirPlay",
                    active: playerManager.isExternalPlaybackActive
                )

                statusPill(
                    title: "Network",
                    active: diagnostics.networkPathText == "satisfied"
                )

                statusPill(
                    title: "HLS",
                    active: diagnostics.lastProbeSucceeded
                )
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("مصدر الفيديو")
                .font(.headline)

            Button {
                customHLSURL = ""
                playerManager.loadAppleProbe()
            } label: {
                Label(
                    "استخدام Apple HLS Probe",
                    systemImage: "play.rectangle.on.rectangle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            TextField(
                "مثال: http://192.168.1.10:8765/live.m3u8",
                text: $customHLSURL
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.URL)
            .textFieldStyle(.roundedBorder)

            HStack {
                Button("فحص الرابط") {
                    Task {
                        await probeCustomURL()
                    }
                }
                .disabled(customURL == nil || isProbing)

                Spacer()

                Button("تحميل الرابط") {
                    guard let url = customURL else { return }
                    playerManager.load(
                        url: url,
                        label: "Custom HLS"
                    )
                }
                .disabled(customURL == nil)
            }

            if isProbing {
                ProgressView("جارٍ فحص HLS…")
                    .font(.caption)
            } else {
                Text(
                    "\(diagnostics.lastProbeText) • \(diagnostics.lastProbeLatencyText)"
                )
                .font(.caption)
                .foregroundStyle(
                    diagnostics.lastProbeSucceeded
                        ? .green
                        : .secondary
                )
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var playbackCard: some View {
        VStack(spacing: 10) {
            metricRow("Source", playerManager.sourceLabel)
            metricRow("Player Item", playerManager.itemStatusText)
            metricRow(
                "Playback",
                playerManager.isPlaying ? "يعمل" : "متوقف"
            )
            metricRow(
                "Keep Up",
                playerManager.isPlaybackLikelyToKeepUp ? "نعم" : "لا"
            )
            metricRow(
                "External Playback",
                playerManager.isExternalPlaybackActive ? "نشط" : "غير نشط"
            )
            metricRow(
                "Stalls",
                "\(playerManager.playbackStallCount)"
            )
            metricRow(
                "Transition",
                playerManager.externalTransitionText
            )
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var networkCard: some View {
        VStack(spacing: 10) {
            metricRow("Network", diagnostics.networkPathText)
            metricRow("Interfaces", diagnostics.interfacesText)
            metricRow("Route Detector", diagnostics.routeDetectionText)
            metricRow(
                "Multiple Routes",
                diagnostics.multipleRoutesDetected ? "نعم" : "لا"
            )
            metricRow("Audio Route", diagnostics.currentAudioRouteText)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var actionCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                PlaygroundAirPlayRoutePicker()
                    .frame(width: 58, height: 48)

                Text("AirPlay")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                playerManager.togglePlayback()
            } label: {
                Label(
                    playerManager.isPlaying
                        ? "إيقاف مؤقت"
                        : "تشغيل",
                    systemImage: playerManager.isPlaying
                        ? "pause.fill"
                        : "play.fill"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)

            Button {
                playerManager.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var customURL: URL? {
        let value = customHLSURL
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else { return nil }
        return URL(string: value)
    }

    private func probeCustomURL() async {
        guard let url = customURL else { return }

        isProbing = true
        await diagnostics.probe(url: url)
        isProbing = false
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

    private func statusPill(
        title: String,
        active: Bool
    ) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(active ? Color.green : Color.secondary)
                .frame(width: 7, height: 7)

            Text(title)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

#Preview {
    MainView()
}
