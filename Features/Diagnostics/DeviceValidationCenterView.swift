import SwiftUI

struct DeviceValidationCenterView: View {
    @ObservedObject var captureManager: ScreenCaptureManager
    @ObservedObject var carPlayManager: CarPlayManager
    @StateObject private var validationManager = DeviceValidationManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard

                VStack(spacing: 12) {
                    statusRow("Environment", validationManager.environmentText)
                    statusRow("System", validationManager.systemVersionText)
                    statusRow(
                        "Capture path",
                        validationManager.preferredCapturePathText
                    )
                    statusRow("Last self-test", validationManager.lastRunText)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if validationManager.checks.isEmpty {
                    Text("شغّل الفحص الذاتي حتى نعرف ما الذي أصبح جاهزًا على الجهاز الحالي وما الذي ينتظر اختبارًا فعليًا.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 10) {
                        ForEach(validationManager.checks) { check in
                            checkRow(check)
                        }
                    }
                }

                Button {
                    Task {
                        await validationManager.run(
                            captureManager: captureManager,
                            carPlayManager: carPlayManager
                        )
                    }
                } label: {
                    Label(
                        validationManager.isRunning
                            ? "جارٍ الفحص…"
                            : "تشغيل Device Self-Test",
                        systemImage: "stethoscope"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(validationManager.isRunning)

                ShareLink(
                    item: validationManager.makeReport(
                        captureManager: captureManager,
                        carPlayManager: carPlayManager
                    )
                ) {
                    Label(
                        "مشاركة تقرير Device Validation",
                        systemImage: "square.and.arrow.up"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                VStack(alignment: .leading, spacing: 8) {
                    Text("تسلسل الاختبار")
                        .font(.headline)

                    Text("1. iPhone فعلي → 2. full-display capture → 3. Live HLS ready → 4. AirPlay External Playback → 5. CarPlay Video entitlement → 6. BMW X6 2025.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text("هذه الشاشة لا تعتبر Simulator أو CarPlay scene وحدهما دليلًا على نجاح عرض الفيديو في السيارة. الغرض منها منعنا من القفز إلى مرحلة entitlement قبل إثبات كل خطوة السابقة.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("Device Validation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(
                systemName: validationManager.isSimulator
                    ? "iphone.gen3.slash"
                    : "iphone.gen3"
            )
            .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Pre-Entitlement Test Center")
                    .font(.headline)

                Text(validationManager.summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func checkRow(
        _ check: DeviceValidationCheck
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(
                systemName: check.passed
                    ? "checkmark.circle.fill"
                    : "clock.fill"
            )
            .foregroundStyle(
                check.passed
                    ? .green
                    : .orange
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(check.title)
                    .font(.subheadline.bold())

                Text(check.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statusRow(
        _ title: String,
        _ value: String
    ) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.footnote)
    }
}

#Preview {
    NavigationStack {
        DeviceValidationCenterView(
            captureManager: ScreenCaptureManager(),
            carPlayManager: CarPlayManager()
        )
    }
}
