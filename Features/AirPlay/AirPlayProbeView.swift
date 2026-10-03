import SwiftUI
import AVKit

struct AirPlayProbeView: View {
    @StateObject private var manager = AirPlayVideoManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("AirPlay Video Probe")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("هذا الاختبار يثبت أن BMW Mirror يستطيع تشغيل فيديو عبر AVPlayer مع External Playback واختيار جهاز AirPlay. لا يربط شاشة iPhone الحية بـ AirPlay بعد.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VideoPlayer(player: manager.player)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(spacing: 12) {
                    statusRow(
                        title: "Player Item",
                        value: manager.playerItemStatusText
                    )

                    statusRow(
                        title: "Playback",
                        value: manager.isPlaying ? "يعمل" : "متوقف"
                    )

                    statusRow(
                        title: "External Playback",
                        value: manager.isExternalPlaybackActive ? "نشط" : "غير نشط"
                    )
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack(spacing: 16) {
                    VStack(spacing: 8) {
                        AirPlayRoutePicker()
                            .frame(width: 56, height: 44)

                        Text("اختر AirPlay")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        manager.togglePlayback()
                    } label: {
                        Label(
                            manager.isPlaying ? "إيقاف مؤقت" : "تشغيل",
                            systemImage: manager.isPlaying ? "pause.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack {
                    Button("إعادة تحميل الاختبار") {
                        manager.prepareProbe()
                    }

                    Spacer()

                    Button("إيقاف") {
                        manager.stop()
                    }
                }
                .buttonStyle(.bordered)

                Text(manager.statusText)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let errorText = manager.errorText {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Text("الخطوة التالية بعد نجاح هذا الاختبار: تحويل خرج ScreenCaptureKit/ReplayKit إلى فيديو قابل للتشغيل عبر مسار AirPlay بدل فيديو HLS التجريبي.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("AirPlay Probe")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            manager.stop()
        }
    }

    private func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .font(.footnote)
    }
}

#Preview {
    NavigationStack {
        AirPlayProbeView()
    }
}
