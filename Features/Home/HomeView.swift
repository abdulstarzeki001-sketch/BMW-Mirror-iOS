import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var carPlayManager = CarPlayManager()
    @StateObject private var captureManager = ScreenCaptureManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                StatusCard(
                    title: "CarPlay",
                    value: carPlayManager.statusText,
                    systemImage: carPlayManager.isConnected ? "car.side.fill" : "car.side"
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("حالة الاتصال")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(carPlayManager.lastEventText)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                StatusCard(
                    title: "التقاط الشاشة",
                    value: captureManager.isCapturing ? "نشط" : "متوقف",
                    systemImage: "rectangle.on.rectangle"
                )

                Button {
                    carPlayManager.refreshConnectionState()
                } label: {
                    Label("تحديث حالة CarPlay", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)

                Button {
                    captureManager.toggleCapture()
                } label: {
                    Text(captureManager.isCapturing ? "إيقاف الالتقاط" : "بدء الالتقاط")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("BMW Mirror")
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    carPlayManager.refreshConnectionState()
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
