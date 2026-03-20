import SwiftUI

private func localizedWidgetInfo(_ key: StaticString, defaultValue: String.LocalizationValue) -> String {
    String(localized: key, defaultValue: defaultValue)
}

private enum WidgetGalleryTitle {
    static var signature: String { localizedWidgetInfo("widget_signature_title", defaultValue: "İmza Widget") }
    static var prayerFocus: String { localizedWidgetInfo("widget_prayer_focus_title", defaultValue: "Sıradaki Vakit") }
    static var dhikrProgress: String { localizedWidgetInfo("widget_dhikr_progress_title", defaultValue: "Günlük Zikir") }
    static var prayerTimeline: String { localizedWidgetInfo("widget_prayer_timeline_title", defaultValue: "Tüm Vakitler") }
    static var prayerDhikr: String { localizedWidgetInfo("widget_prayer_dhikr_title", defaultValue: "Namaz ve Zikir") }
    static var spiritualDashboard: String { localizedWidgetInfo("widget_spiritual_dashboard_title", defaultValue: "Manevi Özet") }
    static var noorSpotlight: String { localizedWidgetInfo("widget_noor_spotlight_title", defaultValue: "Hikmet Kartı") }
    static var auraFlow: String { localizedWidgetInfo("widget_aura_flow_title", defaultValue: "Namaz Ritmi") }
    static var majlisGlow: String { localizedWidgetInfo("widget_majlis_glow_title", defaultValue: "Manevi Vitrin") }
}

struct WidgetInfoView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme

    let subscriptionStore: SubscriptionStore
    let authService: AuthService

    @State private var showPremiumPaywall = false

    private var freeWidgets: [WidgetGalleryItem] {
        [
            WidgetGalleryItem(
                title: WidgetGalleryTitle.signature,
                subtitle: localizedWidgetInfo("widget_gallery_signature_subtitle", defaultValue: "Tek widget içinde small, medium ve large düzenleri sunar."),
                family: "S-M-L",
                accent: Color(red: 0.06, green: 0.39, blue: 0.47),
                icon: "square.grid.3x3.square.fill"
            ),
            WidgetGalleryItem(
                title: WidgetGalleryTitle.prayerFocus,
                subtitle: localizedWidgetInfo("widget_gallery_prayer_focus_subtitle", defaultValue: "Sıradaki vakit ve canlı geri sayım."),
                family: "S",
                accent: Color(red: 0.13, green: 0.35, blue: 0.63),
                icon: "moon.stars.fill"
            ),
            WidgetGalleryItem(
                title: WidgetGalleryTitle.dhikrProgress,
                subtitle: localizedWidgetInfo("widget_gallery_dhikr_progress_subtitle", defaultValue: "Günlük hedef ve seri takibi."),
                family: "S",
                accent: Color(red: 0.78, green: 0.60, blue: 0.18),
                icon: "circle.hexagongrid.circle.fill"
            ),
            WidgetGalleryItem(
                title: WidgetGalleryTitle.prayerTimeline,
                subtitle: localizedWidgetInfo("widget_gallery_prayer_timeline_subtitle", defaultValue: "Tüm vakitleri yatay akışta gösterir."),
                family: "M",
                accent: Color(red: 0.09, green: 0.48, blue: 0.49),
                icon: "calendar.badge.clock"
            ),
            WidgetGalleryItem(
                title: WidgetGalleryTitle.prayerDhikr,
                subtitle: localizedWidgetInfo("widget_gallery_prayer_dhikr_subtitle", defaultValue: "Namaz ve zikir özetini birlikte gösterir."),
                family: "M",
                accent: Color(red: 0.17, green: 0.44, blue: 0.39),
                icon: "sparkles.square.filled.on.square"
            ),
            WidgetGalleryItem(
                title: WidgetGalleryTitle.spiritualDashboard,
                subtitle: localizedWidgetInfo("widget_gallery_spiritual_dashboard_subtitle", defaultValue: "Büyük boyutta tam manevi özet."),
                family: "L",
                accent: Color(red: 0.29, green: 0.29, blue: 0.55),
                icon: "sparkles.rectangle.stack.fill"
            )
        ]
    }

    private var premiumWidgets: [WidgetGalleryItem] {
        [
            WidgetGalleryItem(
                title: WidgetGalleryTitle.noorSpotlight,
                subtitle: localizedWidgetInfo("widget_gallery_noor_spotlight_subtitle", defaultValue: "Hikmet notunu lüks bir küçük karta taşır."),
                family: "S",
                accent: Color(red: 0.82, green: 0.67, blue: 0.24),
                icon: "sparkles"
            ),
            WidgetGalleryItem(
                title: WidgetGalleryTitle.auraFlow,
                subtitle: localizedWidgetInfo("widget_gallery_aura_flow_subtitle", defaultValue: "Namaz ve zikir ritmini premium yüzeyde birleştirir."),
                family: "M",
                accent: Color(red: 0.70, green: 0.55, blue: 0.23),
                icon: "rectangle.3.group.bubble.left.fill"
            ),
            WidgetGalleryItem(
                title: WidgetGalleryTitle.majlisGlow,
                subtitle: localizedWidgetInfo("widget_gallery_majlis_glow_subtitle", defaultValue: "Büyük premium sahnede şehir, vakit ve hikmet."),
                family: "L",
                accent: Color(red: 0.55, green: 0.42, blue: 0.17),
                icon: "sparkles.tv"
            ),
            WidgetGalleryItem(
                title: localizedWidgetInfo("daily_quran_verse_title", defaultValue: "Günün Ayeti"),
                subtitle: localizedWidgetInfo("widget_gallery_daily_verse_subtitle", defaultValue: "Her gün yenilenen ayeti premium editoryal kartta sunar."),
                family: "M-L",
                accent: Color(red: 0.31, green: 0.60, blue: 0.52),
                icon: "book.pages.fill"
            ),
            WidgetGalleryItem(
                title: localizedWidgetInfo("daily_hadith_card_title", defaultValue: "Günün Hadisi"),
                subtitle: localizedWidgetInfo("widget_gallery_daily_hadith_subtitle", defaultValue: "Her gün seçilen hadisi şık bir premium alıntı kartına dönüştürür."),
                family: "M-L",
                accent: Color(red: 0.73, green: 0.55, blue: 0.22),
                icon: "quote.opening"
            )
        ]
    }

    var body: some View {
        let palette = themeManager.palette(using: systemColorScheme)

        ThemedScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard(palette: palette)
                    collectionSection(
                        title: localizedWidgetInfo("widget_gallery_collection_free_title", defaultValue: "Hazır Koleksiyon"),
                        subtitle: localizedWidgetInfo("widget_gallery_collection_free_subtitle", defaultValue: "Ücretsiz koleksiyon anında kullanıma hazır."),
                        items: freeWidgets,
                        palette: palette,
                        isPremiumCollection: false
                    )
                    collectionSection(
                        title: localizedWidgetInfo("widget_gallery_collection_premium_title", defaultValue: "Premium Koleksiyon"),
                        subtitle: localizedWidgetInfo("widget_gallery_collection_premium_subtitle", defaultValue: "Daha lüks yüzeyler ve daha iddialı premium tasarımlar."),
                        items: premiumWidgets,
                        palette: palette,
                        isPremiumCollection: true
                    )
                    installationSection(palette: palette)
                    if !subscriptionStore.isPremium {
                        premiumCallout(palette: palette)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .sheet(isPresented: $showPremiumPaywall) {
                PremiumView(authService: authService)
            }
        }
        .navigationTitle(L10n.string(.widget2))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func heroCard(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localizedWidgetInfo("widget_gallery_hero_title", defaultValue: "Widget Studio"))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)

                    Text(localizedWidgetInfo("widget_gallery_hero_subtitle", defaultValue: "Ana ekranda premium görünen, hızlı erişim sağlayan widget koleksiyonu."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: subscriptionStore.isPremium ? "crown.fill" : "square.grid.2x2.fill")
                        .font(.caption.weight(.bold))
                    if subscriptionStore.isPremium {
                        Text(L10n.string(.premiumStatusActive))
                            .font(.caption.weight(.semibold))
                    } else {
                        Text(
                            String.localizedStringWithFormat(
                                localizedWidgetInfo("widget_gallery_total_count_format", defaultValue: "%lld Widgets"),
                                freeWidgets.count + premiumWidgets.count
                            )
                        )
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.14))
                .clipShape(.capsule)
            }

            HStack(spacing: 12) {
                heroStat(title: Text(L10n.string(.premiumStatusFree)), value: "\(freeWidgets.count)", icon: "sparkles.square.filled.on.square")
                heroStat(title: Text(L10n.string(.premium)), value: "\(premiumWidgets.count)", icon: "crown.fill")
                heroStat(title: Text(localizedWidgetInfo("widget_gallery_sizes_title", defaultValue: "Sizes")), value: "S-M-L", icon: "rectangle.3.group.fill")
            }
        }
        .padding(20)
        .background(
            ZStack {
                palette.heroGradient

                RadialGradient(
                    colors: [Color.white.opacity(0.22), .clear],
                    center: .topTrailing,
                    startRadius: 6,
                    endRadius: 180
                )

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
                    .blendMode(.screen)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: palette.glow.opacity(0.22), radius: 20, y: 10)
    }

    private func heroStat(title: Text, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            title
                .font(.caption)
                .foregroundStyle(.white.opacity(0.70))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func collectionSection(
        title: String,
        subtitle: String,
        items: [WidgetGalleryItem],
        palette: ThemePalette,
        isPremiumCollection: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(palette.primaryText)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                        .lineLimit(3)
                }

                Spacer()

                if isPremiumCollection {
                    if subscriptionStore.isPremium {
                        Text(localizedWidgetInfo("widget_gallery_premium_open", defaultValue: "Açık"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(palette.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(palette.accent.opacity(0.12))
                            .clipShape(.capsule)
                    } else {
                        Text(L10n.string(.premium))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.79, green: 0.61, blue: 0.20))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.79, green: 0.61, blue: 0.20).opacity(0.12))
                            .clipShape(.capsule)
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach(items) { item in
                    widgetPreviewCard(item: item, palette: palette, isPremiumCollection: isPremiumCollection)
                }
            }
        }
        .padding(18)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(palette.borderColor.opacity(0.7), lineWidth: 1)
        )
    }

    private func widgetPreviewCard(
        item: WidgetGalleryItem,
        palette: ThemePalette,
        isPremiumCollection: Bool
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                item.accent.opacity(isPremiumCollection ? 0.95 : 0.75),
                                palette.accent.opacity(isPremiumCollection ? 0.78 : 0.56)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: item.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: item.accent.opacity(0.28), radius: 16, y: 8)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(item.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(palette.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(item.family)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isPremiumCollection ? item.accent : palette.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((isPremiumCollection ? item.accent : palette.secondaryText).opacity(0.10))
                        .clipShape(.capsule)
                }

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if isPremiumCollection {
                Image(systemName: subscriptionStore.isPremium ? "checkmark.seal.fill" : "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(subscriptionStore.isPremium ? palette.accent : item.accent)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.elevatedCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    (isPremiumCollection ? item.accent : palette.borderColor).opacity(0.18),
                    lineWidth: 1
                )
        )
    }

    private func installationSection(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.widgetKurulumu2)
                .font(.headline.weight(.semibold))
                .foregroundStyle(palette.primaryText)

            VStack(spacing: 10) {
                installRow(
                    index: "1",
                    title: localizedWidgetInfo("widget_install_step_1_title", defaultValue: "Ana ekranda boş bir alana uzun bas."),
                    detail: localizedWidgetInfo("widget_install_step_1_detail", defaultValue: "Artı butonuna dokunup Zikrim widget'larını aç.")
                )
                installRow(
                    index: "2",
                    title: localizedWidgetInfo("widget_install_step_2_title", defaultValue: "Boyutu seç."),
                    detail: localizedWidgetInfo("widget_install_step_2_detail", defaultValue: "Small, Medium veya Large seçeneklerinden birini yerleştir.")
                )
                installRow(
                    index: "3",
                    title: localizedWidgetInfo("widget_install_step_3_title", defaultValue: "İmza Widget ile tüm boyutları gör."),
                    detail: localizedWidgetInfo("widget_install_step_3_detail", defaultValue: "Premium üyelik açıksa günlük ayet ve hadis kartları da menüde belirir.")
                )
            }
        }
        .padding(18)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(palette.borderColor.opacity(0.7), lineWidth: 1)
        )
    }

    private func installRow(index: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(index)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func premiumCallout(palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.80, green: 0.63, blue: 0.18))

                Text(localizedWidgetInfo("widget_premium_callout_title", defaultValue: "Premium widget'ları aç"))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            Text(localizedWidgetInfo("widget_premium_callout_subtitle", defaultValue: "Hikmet Kartı, Namaz Ritmi, Manevi Vitrin, Günün Ayeti ve Günün Hadisi ana ekranda daha güçlü bir premium vitrin sunar."))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(3)

            Button {
                showPremiumPaywall = true
            } label: {
                HStack {
                    Text(localizedWidgetInfo("widget_premium_callout_button", defaultValue: "Premium koleksiyonu aç"))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.white)
                .foregroundStyle(Color.black.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.15, blue: 0.24),
                    Color(red: 0.33, green: 0.27, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 20, y: 10)
    }
}

private struct WidgetGalleryItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let family: String
    let accent: Color
    let icon: String
}
