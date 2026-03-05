import SwiftUI

struct WidgetInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Widget Kurulumu")
                    .font(.title2.bold())
                Text("Ana ekranda boş bir alana uzun basın, \"Düzenle\" menüsünden Zikrim widget'ını ekleyin.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Sonraki namaz vakti", systemImage: "clock.fill")
                    Label("Günlük zikir ilerlemesi", systemImage: "chart.pie.fill")
                }
                .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .navigationTitle("Widget")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}
