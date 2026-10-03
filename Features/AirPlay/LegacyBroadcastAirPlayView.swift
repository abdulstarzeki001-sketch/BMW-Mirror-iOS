import SwiftUI
import AVKit
import Network

struct LegacyBroadcastAirPlayView: View {
    @StateObject private var playerManager = AirPlayVideoManager(
        prepareProbeOnInit: false
    )
    @StateObject private var validationManager = AirPlayValidationManager()

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

                VStack(spacing: 12) {
                    LegacyBroadcastPickerView()
                        .frame(width: 64, height: 64)

                    Text("اضغط لبدء BMW Mirror Broadcast")
                        .font(.subheadline.bold())

                    Text("سيظهر اختيار البث الرسمي من iOS. بعد بدء البث ارجع إلى هذه الصفحة واضغط تجهيز الرابط.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VideoPlayer(player: playerManager.player)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(spacing: 12) {
                    row("Broadcast port", "\(AppConstants.legacyBroadcastPort)")
                    row("Live URL", liveURL?.absoluteString ?? "—")
                    row("Player", playerManager.playerItemStatusText)
                    row(
                        "External Playback",
                        playerManager.isExternalPlaybackActive ? "نشط" : "غير نشط"
                    )
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
                        Label("تجهيز رابط البث", systemImage: "network")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack {
                    Button {
                        if let liveURL {
                            playerManager.load(
                                url: liveURL,
                                label: "Legacy Broadcast Live HLS"
                            )
                        }
                    } label: {
                        Label("تحميل البث", systemImage: "play.rectangle")
                    }
                    .disabled(liveURL == nil)

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

                Text("هذا المسار لا يحتاج App Groups لنقل الإطارات: الـ Broadcast Extension نفسه يقوم بإنشاء HLS ويستمع على منفذ ثابت. نجاحه النهائي يجب أن يُثبت على iPhone فعلي لأن ReplayKit Broadcast لا يعمل كالتقاط نظام كامل داخل Simulator.")
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
        .onDisappear {
            playerManager.stop()
        }
    }

    private func prepareLegacyURL() {
        guard
            let host = LiveHLSHTTPServer.preferredLocalIPv4Address(),
            let url = URL(
                string: "http://\(host):\(AppConstants.legacyBroadcastPort)/live.m3u8"
            )
        else {
            liveURL = nil
            statusText = "تعذر العثور على IPv4 محلي. تأكد من اتصال Wi‑Fi/CarPlay ثم حاول مجددًا."
            return
        }

        liveURL = url
        statusText = "الرابط جاهز. إذا بدأ Broadcast Extension يمكن لـ AVPlayer محاولة تحميله."
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
