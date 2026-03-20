import SwiftUI
import UIKit

struct ManeviAssistantOverlayView: View {
    let authService: AuthService
    let bottomPadding: CGFloat

    private let launcherSize: CGFloat = 56
    private let assistantAvatarAssetName = "rabiaicon"

    @AppStorage("rabia_intro_seen_v1") private var hasSeenRabiaIntro = false
    @State private var isPresented = false
    @State private var isIntroPresented = false
    @State private var shouldOpenChatAfterIntro = false
    @State private var questionText = ""
    @State private var isLoading = false
    @State private var messages: [ManeviMessage] = []
    @State private var activeAlert: RabiaLauncherAlert?
    @State private var showPremiumSheet: Bool = false
    @FocusState private var isQuestionFieldFocused: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme

    private var isPremium: Bool { authService.isPremium }
    private var palette: ThemePalette {
        themeManager.palette(using: systemColorScheme)
    }
    private var trimmedQuestionText: String {
        questionText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    private var canSendMessage: Bool {
        !isLoading && !trimmedQuestionText.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
                .allowsHitTesting(false)

            RabiaLauncherButton(
                size: launcherSize,
                avatarAssetName: assistantAvatarAssetName,
                palette: palette,
                action: handleLauncherTap
            )
            .padding(.trailing, 16)
            .padding(.bottom, bottomPadding)
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: bottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await authService.refreshPremiumStatus()
        }
        .task(id: authService.currentUser?.id) {
            messages = RabiaConversationStore.shared.loadMessages(for: authService.currentUser?.id)
        }
        .fullScreenCover(isPresented: $isIntroPresented) {
            RabiaIntroView(
                assistantAvatarAssetName: assistantAvatarAssetName,
                palette: palette,
                onConfirm: handleIntroConfirmation
            )
        }
        .sheet(isPresented: $isPresented) {
            chatSheet
        }
        .onChange(of: isIntroPresented) { _, isShowing in
            guard !isShowing else { return }
            guard shouldOpenChatAfterIntro, hasSeenRabiaIntro else {
                shouldOpenChatAfterIntro = false
                return
            }

            shouldOpenChatAfterIntro = false
            isPresented = true
        }
    }

    private var chatSheet: some View {
        ZStack {
            RabiaChatBackground(palette: palette)

            VStack(spacing: 0) {
                RabiaChatHeader(
                    assistantAvatarAssetName: assistantAvatarAssetName,
                    palette: palette,
                    onClear: clearConversation,
                    onClose: { isPresented = false }
                )

                Divider()
                    .overlay(palette.rabiaSurfaceBorder)

                conversationView

                RabiaChatComposer(
                    text: $questionText,
                    isFocused: $isQuestionFieldFocused,
                    isLoading: isLoading,
                    canSend: canSendMessage,
                    palette: palette,
                    onSend: sendQuestion
                )
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .presentationContentInteraction(.scrolls)
        .sheet(isPresented: $showPremiumSheet) {
            PremiumView(authService: authService)
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .premiumRequired:
                return Alert(
                    title: Text(.premiumRequiredTitle),
                    message: Text(.premiumRabiaMessage),
                    primaryButton: .default(Text(.premiumAGec2)) {
                        showPremiumSheet = true
                    },
                    secondaryButton: .cancel(Text(.dahaSonra))
                )
            }
        }
    }

    private var conversationView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 18) {
                    if messages.isEmpty {
                        RabiaEmptyStateCard(
                            assistantAvatarAssetName: assistantAvatarAssetName,
                            palette: palette
                        )
                        .padding(.top, 12)
                    } else {
                        ForEach(messages) { message in
                            RabiaChatMessageRow(
                                message: message,
                                assistantAvatarAssetName: assistantAvatarAssetName,
                                palette: palette
                            )
                            .id(message.id)
                        }
                    }

                    if isLoading {
                        RabiaTypingIndicatorRow(
                            assistantAvatarAssetName: assistantAvatarAssetName,
                            palette: palette
                        )
                        .id("typing-indicator")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(with: proxy)
            }
            .onChange(of: isLoading) { _, _ in
                scrollToBottom(with: proxy)
            }
        }
    }

    private func handleLauncherTap() {
        guard hasSeenRabiaIntro else {
            shouldOpenChatAfterIntro = true
            isIntroPresented = true
            return
        }

        isPresented = true
    }

    private func handleIntroConfirmation() {
        hasSeenRabiaIntro = true
        isIntroPresented = false
    }

    private func clearConversation() {
        messages = []
        questionText = ""
        isLoading = false
        isQuestionFieldFocused = false
        RabiaConversationStore.shared.clearMessages(for: authService.currentUser?.id)
    }

    private func scrollToBottom(with proxy: ScrollViewProxy) {
        let targetID: AnyHashable? = isLoading ? "typing-indicator" : messages.last?.id
        guard let targetID else { return }
        withAnimation(.easeOut(duration: 0.24)) {
            proxy.scrollTo(targetID, anchor: .bottom)
        }
    }

    @MainActor
    private func sendQuestion() {
        let trimmed = trimmedQuestionText
        guard !trimmed.isEmpty, !isLoading else { return }

        isQuestionFieldFocused = false
        dismissKeyboard()

        if !authService.isPremium {
            Task {
                await presentFreeUserPremiumGate(for: trimmed)
            }
            return
        }

        Task {
            await authService.refreshPremiumStatus(force: true)
            if authService.isPremium {
                await submitQuestion(trimmed)
            } else {
                await presentFreeUserPremiumGate(for: trimmed)
            }
        }
    }

    @MainActor
    private func presentFreeUserPremiumGate(for question: String) async {
        guard activeAlert == nil else { return }
        guard trimmedQuestionText == question || questionText.trimmingCharacters(in: .whitespacesAndNewlines) == question else { return }
        activeAlert = .premiumRequired
    }

    @MainActor
    private func submitQuestion(_ trimmed: String, appendUserMessage: Bool = true) async {
        let history = recentBackendHistory()
        if appendUserMessage {
            appendMessage(ManeviMessage(role: .user, text: trimmed))
        }
        questionText = ""
        isLoading = true

        let appLanguageCode = RabiaAppLanguage.currentCode()

        var response: String?
        do {
            let userMessage = trimmed
            let runtimeContext = RabiaRuntimeContextStore.shared.snapshot(
                appLanguage: appLanguageCode,
                currentScreen: .rabiaChat
            )
            let reply = try await RabiaService().send(
                message: userMessage,
                runtimeContext: runtimeContext,
                history: history
            )
            response = reply
        } catch {
#if DEBUG
            print("[RabiaUI] fallback_reason=backend_error error=\(error)")
#endif
        }

        let cleanedResponse = (response ?? L10n.string(.rabiaChatResponseError))
            .replacingOccurrences(of: "(?is)<think>.*?</think>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?im)^\\s*</?think>\\s*$", with: "", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

#if DEBUG
        if response == nil {
            print("[RabiaUI] fallback_reason=empty_response")
        } else if cleanedResponse.isEmpty {
            print("[RabiaUI] fallback_reason=cleaned_empty")
        }
#endif

        appendMessage(
            ManeviMessage(
                role: .assistant,
                text: cleanedResponse.isEmpty ? L10n.string(.rabiaChatResponseError) : cleanedResponse
            )
        )

        isLoading = false
    }

    private func appendMessage(_ message: ManeviMessage) {
        messages.append(message)
        RabiaConversationStore.shared.saveMessages(messages, for: authService.currentUser?.id)
    }

    private func recentBackendHistory(maxItems: Int = 4) -> [RabiaBackendHistoryItem] {
        messages
            .suffix(maxItems)
            .map {
                RabiaBackendHistoryItem(
                    role: $0.role == .assistant ? "assistant" : "user",
                    text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.text.isEmpty }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct RabiaLauncherButton: View {
    let size: CGFloat
    let avatarAssetName: String
    let palette: ThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [palette.rabiaAccent, palette.secondaryTint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)

                Circle()
                    .stroke(palette.rabiaLauncherBorder, lineWidth: 1)
                    .frame(width: size, height: size)

                RabiaAvatarView(
                    assetName: avatarAssetName,
                    size: size - 12,
                    fillColor: palette.rabiaHeaderAccent,
                    strokeColor: palette.rabiaLauncherBorder.opacity(0.75),
                    fallbackSymbolSize: (size - 12) * 0.34
                )
                .allowsHitTesting(false)
            }
            .shadow(color: palette.rabiaGlow.opacity(0.22), radius: 12, x: 0, y: 7)
            .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.rabiaYaSor2))
    }
}

private struct RabiaChatBackground: View {
    let palette: ThemePalette

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.rabiaBackgroundTop, palette.rabiaBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(palette.rabiaGlow.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 120, y: -240)

            Circle()
                .fill(palette.secondaryTint.opacity(0.10))
                .frame(width: 200, height: 200)
                .blur(radius: 80)
                .offset(x: -140, y: -180)
        }
    }
}

private struct RabiaIntroView: View {
    let assistantAvatarAssetName: String
    let palette: ThemePalette
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            RabiaChatBackground(palette: palette)

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                VStack(spacing: 24) {
                    RabiaAvatarView(
                        assetName: assistantAvatarAssetName,
                        size: 110,
                        fillColor: palette.rabiaHeaderAccent,
                        strokeColor: palette.rabiaLauncherBorder.opacity(0.75),
                        fallbackSymbolSize: 38
                    )
                    .shadow(color: palette.rabiaGlow.opacity(0.24), radius: 24, x: 0, y: 14)
                    .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)

                    VStack(spacing: 14) {
                        Text(.rabiaIntroTitle)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(palette.primaryText)

                        Text(.rabiaIntroMessage)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(palette.primaryText.opacity(0.92))
                            .lineSpacing(6)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(palette.rabiaHeaderAccent)
                            .padding(.top, 2)

                        Text(.rabiaIntroDisclaimer)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(palette.secondaryText)
                            .lineSpacing(5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(palette.rabiaSurface.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(palette.rabiaSurfaceBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .padding(.horizontal, 28)

                Spacer()

                Button(action: onConfirm) {
                    Text(.rabiaIntroConfirm)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [palette.rabiaAccent, palette.secondaryTint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .interactiveDismissDisabled()
    }
}

private struct RabiaChatHeader: View {
    let assistantAvatarAssetName: String
    let palette: ThemePalette
    let onClear: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RabiaAvatarView(
                assetName: assistantAvatarAssetName,
                size: 40,
                fillColor: palette.rabiaHeaderAccent,
                strokeColor: palette.rabiaLauncherBorder.opacity(0.55),
                fallbackSymbolSize: 15
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(.rabia)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                Text(.cevrimici)
                    .font(.caption)
                    .foregroundStyle(palette.rabiaHeaderAccent)
            }

            Spacer(minLength: 12)

            Button {
                onClear()
            } label: {
                Label(.sohbetiTemizle2, systemImage: "trash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(palette.rabiaSurface)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.primaryText.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(palette.rabiaSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.kapat2))
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(palette.rabiaSurface.opacity(0.85))
    }
}

private struct RabiaEmptyStateCard: View {
    let assistantAvatarAssetName: String
    let palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                RabiaAvatarView(
                    assetName: assistantAvatarAssetName,
                    size: 44,
                    fillColor: palette.rabiaHeaderAccent,
                    strokeColor: palette.rabiaLauncherBorder.opacity(0.58),
                    fallbackSymbolSize: 17
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(.rabiaChatEmptyTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(palette.primaryText)
                    Text(.rabiaChatEmptySubtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(palette.rabiaSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(palette.rabiaSurfaceBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct RabiaChatMessageRow: View {
    let message: ManeviMessage
    let assistantAvatarAssetName: String
    let palette: ThemePalette

    private var maxBubbleWidth: CGFloat {
        min(UIScreen.main.bounds.width * 0.76, 560)
    }

    private var timestampText: String {
        Self.timestampFormatter.string(from: message.createdAt)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.role == .assistant {
                assistantAvatar
            } else {
                Spacer(minLength: 34)
            }

            VStack(alignment: message.role == .assistant ? .leading : .trailing, spacing: 6) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(message.role == .assistant ? palette.rabiaAssistantText : palette.rabiaUserText)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .frame(maxWidth: maxBubbleWidth, alignment: .leading)
                    .background(message.role == .assistant ? palette.rabiaAssistantBubble : palette.rabiaUserBubble)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                message.role == .assistant ? palette.rabiaSurfaceBorder : palette.rabiaInputBorder,
                                lineWidth: 1
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Text(timestampText)
                    .font(.caption2)
                    .foregroundStyle(palette.secondaryText.opacity(0.82))
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity, alignment: message.role == .assistant ? .leading : .trailing)

            if message.role == .assistant {
                Spacer(minLength: 34)
            }
        }
    }

    private var assistantAvatar: some View {
        RabiaAvatarView(
            assetName: assistantAvatarAssetName,
            size: 30,
            fillColor: palette.rabiaHeaderAccent,
            strokeColor: palette.rabiaLauncherBorder.opacity(0.55),
            fallbackSymbolSize: 12
        )
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("dMMM HH:mm")
        return formatter
    }()
}

private struct RabiaTypingIndicatorRow: View {
    let assistantAvatarAssetName: String
    let palette: ThemePalette

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            RabiaAvatarView(
                assetName: assistantAvatarAssetName,
                size: 30,
                fillColor: palette.rabiaHeaderAccent,
                strokeColor: palette.rabiaLauncherBorder.opacity(0.55),
                fallbackSymbolSize: 12
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    TypingDot(delay: 0.0, color: palette.rabiaTypingDot)
                    TypingDot(delay: 0.18, color: palette.rabiaTypingDot)
                    TypingDot(delay: 0.36, color: palette.rabiaTypingDot)
                }

                Text(.rabiaDusunuyor)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(palette.rabiaAssistantBubble)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.rabiaSurfaceBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Spacer(minLength: 34)
        }
    }
}

private struct RabiaChatComposer: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let isLoading: Bool
    let canSend: Bool
    let palette: ThemePalette
    let onSend: () -> Void

    private var placeholderColor: Color {
        palette.rabiaPlaceholderText
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(.rabiaYaBirSeySor)
                            .font(.body)
                            .foregroundStyle(placeholderColor)
                            .lineLimit(1)
                            .allowsHitTesting(false)
                    }

                    TextField("", text: $text)
                        .font(.body)
                        .textInputAutocapitalization(.sentences)
                        .focused(isFocused)
                        .submitLabel(.send)
                        .foregroundStyle(palette.primaryText)
                        .tint(palette.rabiaAccent)
                        .onSubmit {
                            onSend()
                        }
                }
                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)

                Button {
                    onSend()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [palette.rabiaSendButton, palette.secondaryTint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)

                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .opacity(canSend ? 1 : 0.45)
                .accessibilityLabel(Text(.soruyuGonder))
            }
            .padding(.leading, 14)
            .padding(.trailing, 10)
            .padding(.vertical, 10)
            .background(palette.rabiaComposerBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.rabiaInputBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [palette.rabiaBackgroundTop.opacity(0.24), palette.rabiaBackgroundBottom.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct RabiaAvatarView: View {
    let assetName: String
    let size: CGFloat
    let fillColor: Color
    let strokeColor: Color
    let fallbackSymbolSize: CGFloat

    var body: some View {
        Group {
            if UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: fallbackSymbolSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(fillColor.opacity(0.88))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(strokeColor, lineWidth: 1)
        )
    }
}

private struct TypingDot: View {
    let delay: Double
    let color: Color
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .scaleEffect(isAnimating ? 1 : 0.55)
            .opacity(isAnimating ? 1 : 0.35)
            .animation(
                .easeInOut(duration: 0.65)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

nonisolated struct ManeviMessage: Identifiable, Equatable, Sendable {
    nonisolated enum Role: String, Codable, Sendable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), role: Role, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

extension ManeviMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case role
        case text
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(Role.self, forKey: .role)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

private enum RabiaLauncherAlert: Identifiable {
    case premiumRequired

    var id: Int {
        switch self {
        case .premiumRequired: 0
        }
    }
}

#Preview("Rabia Theme Switcher") {
    RabiaThemePreviewShowcase()
}

private struct RabiaThemePreviewShowcase: View {
    @StateObject private var themeManager = ThemeManager.preview(theme: .defaultTheme, appearanceMode: .dark)
    @State private var messages: [ManeviMessage] = [
        ManeviMessage(role: .user, text: "Kalbimi sakinleştiren bir ayet önerir misin?"),
        ManeviMessage(role: .assistant, text: "Bu konu için şu referanslar güzel bir başlangıç olabilir:\n\n13:28\n94:5\n2:286")
    ]
    @State private var draft = ""
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        let palette = themeManager.palette(using: .dark)

        VStack(spacing: 18) {
            Picker("Theme", selection: Binding(
                get: { themeManager.currentThemeID },
                set: { themeManager.setTheme($0) }
            )) {
                ForEach(ThemeID.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Spacer()
                RabiaLauncherButton(
                    size: 60,
                    avatarAssetName: "rabiaicon",
                    palette: palette,
                    action: {}
                )
            }

            ZStack {
                RabiaChatBackground(palette: palette)

                VStack(spacing: 0) {
                    RabiaChatHeader(
                        assistantAvatarAssetName: "rabiaicon",
                        palette: palette,
                        onClear: { messages = [] },
                        onClose: {}
                    )

                    Divider()
                        .overlay(palette.rabiaSurfaceBorder)

                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach(messages) { message in
                                RabiaChatMessageRow(
                                    message: message,
                                    assistantAvatarAssetName: "rabiaicon",
                                    palette: palette
                                )
                            }

                            RabiaTypingIndicatorRow(
                                assistantAvatarAssetName: "rabiaicon",
                                palette: palette
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                    }

                    RabiaChatComposer(
                        text: $draft,
                        isFocused: $isComposerFocused,
                        isLoading: false,
                        canSend: !draft.isEmpty,
                        palette: palette,
                        onSend: {}
                    )
                }
            }
            .frame(height: 520)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(palette.rabiaSurfaceBorder, lineWidth: 1)
            )
        }
        .padding()
        .background(palette.pageBackground.ignoresSafeArea())
        .environmentObject(themeManager)
        .preferredColorScheme(.dark)
    }
}
