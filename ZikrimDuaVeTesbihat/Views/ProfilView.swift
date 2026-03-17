import SwiftUI

struct ProfilView: View {
    let storage: StorageService
    let authService: AuthService

    var body: some View {
        AccountSettingsView(storage: storage, authService: authService)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section(L10n.string(.zikrimNedir)) {
                Text(.zikrimGunlukDuaVeZikirPratiginiDuzenliSekildeTakipEtmeniziSaglayanBir)
            }

            Section(L10n.string(.uygulamaninAmaci)) {
                Text(.amacimizTesbihRehberIceriklerNamazVakitleriVeKisiselTakipAraclariylaIb)
            }

            Section(L10n.string(.premiumAvantajlari)) {
                Label(.reklamsizKullanim, systemImage: "checkmark.seal.fill")
                Label(.bulutSenkronizasyonu2, systemImage: "icloud.fill")
                Label(.detayliIstatistik, systemImage: "chart.bar.xaxis")
                Label(.widgetDestegi, systemImage: "rectangle.3.group.fill")
                Label(.bildirimSesPaketi2, systemImage: "speaker.wave.2.fill")
                Label(.filigransizPaylasimKartlari, systemImage: "photo.badge.checkmark")
            }

            Section(L10n.string(.gizlilik)) {
                Text(.verilerinizOncelikliOlarakCihazinizdaYerelOlarakSaklanir)
            }

            Section(L10n.string(.surum)) {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }

            Section(L10n.string(.iletisim)) {
                Link("melsalegal.com/support", destination: LegalLinks.supportURL)

                if let supportEmailURL = LegalLinks.supportEmailURL {
                    Link(LegalLinks.supportEmail, destination: supportEmailURL)
                } else {
                    Text(LegalLinks.supportEmail)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.string(.hakkinda))
    }
}
