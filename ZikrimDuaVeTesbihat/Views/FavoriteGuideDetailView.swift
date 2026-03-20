import SwiftUI

struct FavoriteGuideDetailView: View {
    let favorite: FavoriteGuide

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: favorite.date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.teal.opacity(0.25), Color.blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.teal)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(.rabiaNinGunlukRehberi)
                            .font(.title3.bold())
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(favorite.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(6)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.07), Color.blue.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.teal.opacity(0.18), lineWidth: 1)
                    )
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.string(.rehberDetay2))
        .navigationBarTitleDisplayMode(.inline)
    }
}
