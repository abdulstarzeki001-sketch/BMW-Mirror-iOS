import SwiftUI

struct HomeView: View {
    @StateObject private var carPlayManager = CarPlayManager()
    @StateObject private var captureManager = ScreenCaptureManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                StatusCard(
                    title: "CarPlay",
                    value: carPlayManager.isConnected ? "متصل" : "غير متصل",
                    systemImage: "car.side"
                )

                StatusCard(
                    title: "التقاط الشاشة",
                    value: captureManager.isCapturing ? "نشط" : "متوقف",
                    systemImage: "rectangle.on.rectangle"
                )

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
        }
    }
}

#Preview {
    HomeView()
}
