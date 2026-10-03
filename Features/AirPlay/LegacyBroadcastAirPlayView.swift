import SwiftUI
import AVKit
import Network

struct LegacyBroadcastAirPlayView: View {
    @StateObject private var playerManager = AirPlayVideoManager(
        prepareProbeOnInit: false
    )
    @StateObject private var validationManager = AirPlayValidationManager()
    @StateObject private var broadcastMonitor = LegacyBroadcastMonitor()

    @State private var liveURL: URL?
    @State private var statusText = "ابدأ System Broadcast أولًا"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Legacy Full Display — iOS 17–26")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("هذا المسار يستخدم ReplayKit Broadcast Upload Extension لالتقاط الشاشة الكاملة، ثم يبني HLS على منفذ ثابت ويشغله عبر AVPlayer/AirPlay.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                broadcastControlCard

                VideoPlayer(player: playerManager.player)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(spacing: 12) {
                    row("Broadcast port", "\(AppConstants.legacyBroadcastPort)")
                    row("HLS server", broadcastMonitor.statusText)
                    row("Probe latency", broadcastMonitor.latencyText)
                    row("Probe count", "\(broadcastMonitor.probeCount)")
                    row("Live URL", liveURL?.absoluteString ?? "—")
                    row("Player", playerManager.playerItemStatusText)
                    row(
                        "External Playback",
                        playerManager.isExternalPlaybackActive ? "نشط" : "غير نشط"
                    )
                    row("Keep Up", playerManager.isPlaybackLikelyToKeepUp ? "نعم" : "لا")
                    row("Stalls", "\(playerManager.playbackStallCount)")
                    row("Route", validationManager.currentAudioRouteText)
                    row("Network", validationManager.networkPathText)
                    row("Interfaces", validationManager.networkInterfacesText)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack(spacing: 16) {
                    VStack(spacing: 8) {
                        AirPlayRoutePicker()
                            .frame(width: 56, height: 44)

                        Text("AirPlay")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        prepareLegacyURL()
                    } label: {
                        Label("إعادة فحص الرابط", systemImage: "network")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack {
                    Button {
                        loadLegacyStream()
                    } label: {
                        Label("تحميل البث", systemImage: "play.rectangle")
                    }
                    .disabled(!broadcastMonitor.isReachable)

                    Spacer()

                    Button {
                        playerManager.togglePlayback()
                    } label: {
                        Label(
                            playerManager.isPlaying ? "إيقاف مؤقت" : "تشغيل",
                            systemImage: playerManager.isPlaying
                                ? "pause.fill"
                                : "play.fill"
                        )
                    }
                    .disabled(playerManager.player.currentItem == nil)
                }
                .buttonStyle(.bordered)

                Text(statusText)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("هذا المسار لا يحتاج App Groups لنقل الإطارات: الـ Broadcast Extension نفسه يقوم بإنشاء HLS ويستمع على منفذ ثابت. المراقب يفحص الرابط كل ثانية ويحمّل البث تلقائيًا عندما يصبح الخادم جاهزًا.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("Legacy Broadcast")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            prepareLegacyURL()
        }
        .onChange(of: broadcastMonitor.isReachable) { _, reachable in
            if reachable {
                statusText = "Broadcast Extension يعمل وHLS أصبح متاحًا."
                loadLegacyStream()
            }
        }
        .onDisappear {
            broadcastMonitor.stop()
            playerManager.stop()
        }
    }

    private var broadcastControlCard: some View {
        VStack(spacing: 12) {
            LegacyBroadcastPickerView()
                .frame(width: 64, height: 64)

            Text("اضغط لبدء BMW Mirror Broadcast")
                .font(.subheadline.bold())

            HStack(spacing: 8) {
                Image(
                    systemName: broadcastMonitor.isReachable
                        ? "checkmark.circle.fill"
                        : "clock.fill"
                )
                .foregroundStyle(
                    broadcastMonitor.isReachable
                        ? .green
                        : .orange
                )

                Text(
                    broadcastMonitor.isReachable
                        ? "Broadcast HLS متصل"
                        : "بانتظار بدء Broadcast Extension"
                )
                .font(.caption)
            }

            Text("ابدأ البث من نافذة iOS الرسمية. عند تشغيل الـExtension سيكتشف BMW Mirror الخادم على المنفذ 8765 تلقائيًا.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func prepareLegacyURL() {
        guard
            let host = LiveHLSHTTPServer.preferredLocalIPv4Address(),
            let url = URL(
                string: "http://\(host):\(AppConstants.legacyBroadcastPort)/live.m3u8"
            )
        else {
            broadcastMonitor.stop()
            liveURL = nil
            statusText = "تعذر العثور على IPv4 محلي. تأكد من اتصال Wi‑Fi/CarPlay ثم حاول مجددًا."
            return
        }

        liveURL = url
        statusText = "الرابط مجهز؛ BMW Mirror يراقب بدء Broadcast Extension."
        broadcastMonitor.start(url: url)
    }

    private func loadLegacyStream() {
        guard let liveURL else { return }

        if playerManager.currentSourceLabel != "Legacy Broadcast Live HLS" {
            playerManager.load(
                url: liveURL,
                label: "Legacy Broadcast Live HLS"
            )
        }
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

#Preview {
    NavigationStack {
        LegacyBroadcastAirPlayView()
    }
}
