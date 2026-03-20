import SwiftUI

struct DiyanetKnowledgeListView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @ObservedObject var store: DiyanetKnowledgeStore
    let initialType: DiyanetContentType?
    let initialSearchText: String

    @State private var searchText: String
    @State private var selectedType: DiyanetContentType?

    init(store: DiyanetKnowledgeStore, initialType: DiyanetContentType? = nil, initialSearchText: String = "") {
        self.store = store
        self.initialType = initialType
        self.initialSearchText = initialSearchText
        _searchText = State(initialValue: initialSearchText)
        _selectedType = State(initialValue: initialType)
    }

    private var theme: AppTheme {
        themeManager.palette(using: systemColorScheme)
    }

    private var filteredRecords: [DiyanetKnowledgeRecord] {
        store.filteredRecords(searchText: searchText, selectedType: selectedType)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                filterHeader

                if filteredRecords.isEmpty {
                    emptyResultsCard
                } else {
                    ForEach(filteredRecords) { record in
                        NavigationLink {
                            DiyanetKnowledgeDetailView(record: record)
                        } label: {
                            DiyanetKnowledgeRecordCard(record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .themedScreenBackground()
        .themedNavigation(title: selectedType?.displayName ?? "Tüm Kayıtlar", displayMode: .large)
        .searchable(text: $searchText, prompt: "Resmi içeriklerde ara")
        .task {
            await store.loadIfNeeded()
        }
    }

    private var filterHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resmi içerikler")
                .font(.caption.bold())
                .foregroundStyle(theme.secondaryText)
                .tracking(0.8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    typeChip(title: "Tümü", systemImage: "square.grid.2x2.fill", isSelected: selectedType == nil) {
                        selectedType = nil
                    }

                    ForEach(DiyanetContentType.allCases, id: \.self) { type in
                        typeChip(title: type.displayName, systemImage: type.systemImage, isSelected: selectedType == type) {
                            selectedType = type
                        }
                    }
                }
            }

            Text("\(filteredRecords.count) kayıt")
                .font(.caption)
                .foregroundStyle(theme.mutedText)
        }
    }

    private func typeChip(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.bold())
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? theme.accent.opacity(0.14) : theme.elevatedCardBackground)
            .foregroundStyle(isSelected ? theme.accent : theme.secondaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? theme.accent.opacity(0.3) : theme.divider.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyResultsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(theme.secondaryText)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Sonuç bulunamadı")
                        .font(.headline)
                        .foregroundStyle(theme.primaryText)
                    Text("Arama metnini veya içerik türü filtresini değiştirerek tekrar deneyebilirsin.")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                }
            }
        }
        .padding(16)
        .appCardStyle(theme, elevated: true)
    }
}

struct DiyanetKnowledgeRecordCard: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    let record: DiyanetKnowledgeRecord

    private var theme: AppTheme {
        themeManager.palette(using: systemColorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: record.type.systemImage)
                        .font(.caption.bold())
                        .foregroundStyle(theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.displayTitle)
                        .font(.headline)
                        .foregroundStyle(theme.primaryText)
                        .multilineTextAlignment(.leading)

                    if let question = record.questionClean, !question.isEmpty, question != record.displayTitle {
                        Text(question)
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }

            Text(record.previewText)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
                .lineLimit(3)

            HStack(spacing: 8) {
                Text(record.type.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accent.opacity(0.1))
                    .clipShape(Capsule())

                if let topCategory = record.categoryPath.first {
                    Text(topCategory)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(theme.mutedText)
            }
        }
        .padding(16)
        .appCardStyle(theme, elevated: false)
    }
}
