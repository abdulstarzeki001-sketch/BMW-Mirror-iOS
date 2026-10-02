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

                    StatusCard(
                        title: "Media Pipeline",
                        value: captureManager.statusText,
                        systemImage: captureManager.isCapturing ? "waveform.circle.fill" : "waveform.circle"
                    )

                    capturePreview
                    pipelineMetrics

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

                    NavigationLink {
                        CarPlayPreviewView()
                    } label: {
                        Label("معاينة واجهة CarPlay", systemImage: "car.rear.waves.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)

                    NavigationLink {
                        ReadinessView()
                    } label: {
                        Label("Project Readiness", systemImage: "checklist")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)

                    ShareLink(
                        item: DiagnosticsReport.make(
                            carPlayManager: carPlayManager,
                            captureManager: captureManager
                        )
                    ) {
                        Label("مشاركة تقرير الفحص", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        carPlayManager.refreshConnectionState()
                    } label: {
                        Label("تحديث حالة CarPlay", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)

                    Text(carPlayManager.lastEventText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    Text("معاينة Media Pipeline")
                        .font(.headline)
                    Text("ابدأ الالتقاط لاختبار الفيديو والصوت والاتجاه")
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

    private var pipelineMetrics: some View {
        VStack(spacing: 12) {
            metricRow("FPS", value: "\(captureManager.actualFPSText) / \(captureManager.targetFPS)")
            metricRow("زمن معالجة الإطار", value: captureManager.processingLatencyText)
            metricRow("حجم المصدر", value: captureManager.sourceSizeText)
            metricRow("حجم الإخراج", value: captureManager.frameSizeText)
            metricRow("اتجاه الفيديو", value: captureManager.orientationText)
            metricRow("إطارات معالجة", value: "\(captureManager.frameCount)")
            metricRow("إطارات متروكة", value: "\(captureManager.droppedFrameCount)")
            metricRow("حزم صوت التطبيق", value: "\(captureManager.audioPacketCount)")
        }
        .font(.footnote)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func metricRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }
}

#Preview {
    HomeView()
}
