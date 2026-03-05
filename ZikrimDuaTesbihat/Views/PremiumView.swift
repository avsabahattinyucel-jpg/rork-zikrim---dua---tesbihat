import SwiftUI
import RevenueCat

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    let authService: AuthService

    @State private var offerings: Offerings?
    @State private var isLoading: Bool = true
    @State private var isPurchasing: Bool = false
    @State private var selectedPackage: Package?
    @State private var errorMessage: String?

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("sparkles", "Sınırsız Rabia Asistan", "İslami sorularınıza sınırsız cevap"),
        ("nosign", "Reklamsız Deneyim", "Tüm reklamlar kaldırılır"),
        ("book.fill", "Tüm İçerikler", "Premium zikir ve dualar"),
        ("bell.badge.fill", "Özel Bildirimler", "Kişiselleştirilmiş hatırlatmalar"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    packagesSection
                    restoreButton
                    termsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color.green.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Hata", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                await loadOfferings()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(.linearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .padding(.top, 20)

            Text("Zikrim Premium")
                .font(.title.bold())

            Text("Manevi yolculuğunuzu sınırsız yaşayın")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(.green)
                        .frame(width: 36, height: 36)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                        Text(feature.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                if index < features.count - 1 {
                    Divider().padding(.leading, 66)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    @ViewBuilder
    private var packagesSection: some View {
        if isLoading {
            ProgressView()
                .padding(.vertical, 24)
        } else if let current = offerings?.current, !current.availablePackages.isEmpty {
            VStack(spacing: 12) {
                ForEach(current.availablePackages, id: \.identifier) { package in
                    PackageCard(
                        package: package,
                        isSelected: selectedPackage?.identifier == package.identifier,
                        isPurchasing: isPurchasing
                    ) {
                        selectedPackage = package
                    }
                }

                purchaseButton
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Paketler yüklenemedi")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Tekrar Dene") {
                    Task { await loadOfferings() }
                }
                .font(.subheadline.weight(.medium))
            }
            .padding(.vertical, 24)
        }
    }

    private var purchaseButton: some View {
        Button {
            guard let pkg = selectedPackage else { return }
            Task { await purchase(pkg) }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Abone Ol")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [.green, .green.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 14))
        }
        .disabled(isPurchasing || selectedPackage == nil)
        .opacity(selectedPackage == nil ? 0.5 : 1)
    }

    private var restoreButton: some View {
        Button {
            Task { await restore() }
        } label: {
            Text("Satın Alımları Geri Yükle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .disabled(isPurchasing)
    }

    private var termsSection: some View {
        Text("Abonelik otomatik olarak yenilenir. İstediğiniz zaman Ayarlar > Apple Kimliği > Abonelikler bölümünden iptal edebilirsiniz.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    private func loadOfferings() async {
        isLoading = true
        do {
            let result = try await RevenueCatService.shared.offerings()
            offerings = result
            if let current = result.current {
                if let yearly = current.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier == RevenueCatService.yearlyProductID
                }) {
                    selectedPackage = yearly
                } else {
                    selectedPackage = current.availablePackages.first
                }
            }
        } catch {
            print("Offerings load error: \(error)")
        }
        isLoading = false
    }

    private func purchase(_ package: Package) async {
        isPurchasing = true
        do {
            let info = try await RevenueCatService.shared.purchasePackage(package)
            if RevenueCatService.shared.hasActiveEntitlement(info) {
                dismiss()
            }
        } catch {
            if let rcError = error as? RevenueCat.ErrorCode, rcError == .purchaseCancelledError {
            } else {
                errorMessage = "Satın alma başarısız: \(error.localizedDescription)"
            }
        }
        isPurchasing = false
    }

    private func restore() async {
        isPurchasing = true
        do {
            let info = try await RevenueCatService.shared.restorePurchases()
            if RevenueCatService.shared.hasActiveEntitlement(info) {
                dismiss()
            } else {
                errorMessage = "Aktif abonelik bulunamadı."
            }
        } catch {
            errorMessage = "Geri yükleme başarısız: \(error.localizedDescription)"
        }
        isPurchasing = false
    }
}

private struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let isPurchasing: Bool
    let onSelect: () -> Void

    private var isYearly: Bool {
        package.storeProduct.productIdentifier == RevenueCatService.yearlyProductID
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(isYearly ? "Yıllık" : "Aylık")
                            .font(.headline)

                        if isYearly {
                            Text("EN UYGUN")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(.capsule)
                        }
                    }

                    Text(package.storeProduct.localizedPriceString + (isYearly ? " / yıl" : " / ay"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .green : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}
