import SwiftUI

struct ReadinessView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("جاهزية المشروع")
                            .font(.headline)
                        Spacer()
                        Text("\(ProjectReadiness.completedCount)/\(ProjectReadiness.totalCount)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: ProjectReadiness.progress)
                }
                .padding(.vertical, 6)
            }

            Section("الحالة") {
                ForEach(ProjectReadiness.items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.isReady ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundStyle(item.isReady ? .green : .orange)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)

                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("الخطوة التالية") {
                Text("الخطوة البرمجية التالية هي بناء مسار AirPlay Video حقيقي. بعد ذلك يأتي Apple Developer + CarPlay Video entitlement، ثم الاختبار الفعلي على BMW X6 2025.")
                    .font(.subheadline)
            }
        }
        .navigationTitle("جاهزية المشروع")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ReadinessView()
    }
}
