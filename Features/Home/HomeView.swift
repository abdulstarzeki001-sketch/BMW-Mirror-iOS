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
                        title: "BMW Mirror على CarPlay",
                        value: carPlayManager.statusText,
                        systemImage: carPlayManager.isConnected ? "car.side.fill" : "car.side"
                    )

                    StatusCard(
                        title: "Screen Capture",
                        value: captureManager.statusText,
                        systemImage: captureManager.isCapturing ? "waveform.circle.fill" : "waveform.circle"
                    )

                    captureModePicker

                    Text(captureManager.modeDetailText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

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
                            captureButtonTitle,
                            systemImage: captureButtonIcon
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(captureManager.isBusy)

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
                        Label("جاهزية المشروع", systemImage: "checklist")
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
                        Label("تحديث مشهد CarPlay", systemImage: "arrow.clockwise")
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

    private var captureModePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("وضع الالتقاط")
                .font(.headline)

            Picker("وضع الالتقاط", selection: $captureManager.captureMode) {
                ForEach(CaptureMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(captureManager.isCapturing || captureManager.isBusy)

            HStack {
                Text(captureManager.captureMode.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if captureManager.captureMode == .fullDisplay &&
                    !captureManager.supportsFullDisplayCapture {
                    Text("غير متاح")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                    Text("معاينة الالتقاط")
                        .font(.headline)
                    Text("ابدأ الالتقاط لعرض الإطارات هنا")
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
            metricRow("إطارات throttled", value: "\(captureManager.droppedFrameCount)")
            metricRow("إطارات فاشلة", value: "\(captureManager.failedFrameCount)")
            metricRow("حزم صوت", value: "\(captureManager.audioPacketCount)")
        }
        .font(.footnote)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var captureButtonTitle: String {
        if captureManager.isBusy {
            return "جارٍ التنفيذ…"
        }

        return captureManager.isCapturing ? "إيقاف الالتقاط" : "بدء الالتقاط"
    }

    private var captureButtonIcon: String {
        if captureManager.isBusy {
            return "hourglass"
        }

        return captureManager.isCapturing ? "stop.fill" : "record.circle"
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
