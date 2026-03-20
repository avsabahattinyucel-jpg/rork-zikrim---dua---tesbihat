import Foundation

struct RabiaPromptBuilder {
    static func buildSystemPrompt(memory: RabiaMemory, appLanguageCode: String = RabiaAppLanguage.currentCode()) -> String {
        _ = memory
        return RabiaPromptFactory.makeBasePrompt(appLanguage: AppLanguage(code: appLanguageCode))
    }
}
