import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var carPlayManager = CarPlayManager()
    @StateObject private var captureManager = ScreenCaptureManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                        value: captureManager.statusText,
                        systemImage: captureManager.isCapturing ? "record.circle.fill" : "rectangle.on.rectangle"
                    )

                    capturePreview

                    HStack {
                        Label("\(captureManager.frameCount) إطار", systemImage: "film.stack")
                        Spacer()
                        Text(captureManager.frameSizeText)
                            .monospacedDigit()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    if let errorText = captureManager.errorText {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        captureManager.toggleCapture()
                    } label: {
                        Label(
                            captureManager.isCapturing ? "إيقاف الالتقاط" : "بدء التقاط الشاشة",
                            systemImage: captureManager.isCapturing ? "stop.fill" : "record.circle"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        carPlayManager.refreshConnectionState()
                    } label: {
                        Label("تحديث حالة CarPlay", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("BMW Mirror")
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    carPlayManager.refreshConnectionState()
                }
            }
        }
    }

    @ViewBuilder
    private var capturePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.black)

            if let frame = captureManager.latestFrame {
                Image(decorative: frame, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 34))
                    Text("معاينة شاشة iPhone")
                        .font(.headline)
                    Text("اضغط بدء الالتقاط لعرض الإطارات هنا")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    HomeView()
}
