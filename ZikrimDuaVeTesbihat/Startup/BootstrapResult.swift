import Foundation

struct BootstrapResult: Equatable, Sendable {
    let route: AppRoute
    let warnings: [String]
}

struct BootstrapFailureContext: Equatable, Sendable {
    let titleKey: String
    let messageKey: String
    let debugMessage: String?

    static func startup(debugMessage: String? = nil) -> BootstrapFailureContext {
        BootstrapFailureContext(
            titleKey: "baglanti_hatasi",
            messageKey: "geri_yukleme_hata_tekrar_dene",
            debugMessage: debugMessage
        )
    }
}
