import SwiftUI

struct CarPlayPreviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("معاينة واجهة CarPlay")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("هذه معاينة داخل iPhone فقط لاختبار شكل الواجهة قبل تفعيل CarPlay entitlement.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.black)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("BMW Mirror")
                                .font(.title3.bold())
                            Spacer()
                            Image(systemName: "car.side.fill")
                        }

                        Divider()
                            .overlay(.white.opacity(0.18))

                        previewRow(
                            title: "Media Pipeline",
                            detail: "30 FPS target • 1280px max edge",
                            icon: "waveform.circle.fill"
                        )

                        previewRow(
                            title: "Screen Capture",
                            detail: "Prepared on iPhone",
                            icon: "rectangle.on.rectangle"
                        )

                        previewRow(
                            title: "Target Vehicle",
                            detail: "BMW X6 2025",
                            icon: "car.side"
                        )
                    }
                    .foregroundStyle(.white)
                    .padding(24)
                }
                .aspectRatio(16 / 9, contentMode: .fit)

                VStack(alignment: .leading, spacing: 10) {
                    Label("CarPlay Scene: جاهز", systemImage: "checkmark.circle.fill")
                    Label("Media Pipeline: جاهز", systemImage: "checkmark.circle.fill")
                    Label("Apple Entitlement: بانتظار الموافقة", systemImage: "clock.fill")
                    Label("BMW X6 Test: لم يبدأ بعد", systemImage: "car.circle")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding()
        }
        .navigationTitle("CarPlay Preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func previewRow(title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        CarPlayPreviewView()
    }
}
