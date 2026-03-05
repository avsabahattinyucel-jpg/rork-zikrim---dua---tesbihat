import SwiftUI
import UIKit


struct ManeviAssistantOverlayView: View {
    @State private var geminiService = GroqService()
    @State private var isPresented: Bool = false
    @State private var questionText: String = ""
    @State private var isLoading: Bool = false
    @State private var messages: [ManeviMessage] = [
        ManeviMessage(role: .assistant, text: "Selâmün aleyküm 💚 Ben Rabia. Aklında ne varsa sor, dinliyorum.")
    ]
    @State private var isPremium: Bool = false
    @State private var showLimitAlert: Bool = false
    @FocusState private var isQuestionFieldFocused: Bool

    @AppStorage("manevi_assistant_free_date_v1") private var freeDate: Double = 0
    @AppStorage("manevi_assistant_free_count_v1") private var freeCount: Int = 0

    private let bubbleSize: CGFloat = 62
    private let assistantLogoURL: URL? = URL(string: "https://r2-pub.rork.com/generated-images/1320b87e-b7e0-42f5-903c-374245e5442d.png")
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            Button {
                isPresented = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.teal, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: bubbleSize, height: bubbleSize)
                    AsyncImage(url: assistantLogoURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "bubble.left.and.sparkles.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: bubbleSize - 10, height: bubbleSize - 10)
                    .clipShape(.circle)
                    .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .padding(.bottom, 90)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            do {
                let info = try await RevenueCatService.shared.customerInfo()
                isPremium = RevenueCatService.shared.hasActiveEntitlement(info)
            } catch {}
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                VStack(spacing: 0) {
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(messages) { message in
                                    HStack {
                                        if message.role == .assistant {
                                            messageBubble(message.text, isAssistant: true)
                                            Spacer(minLength: 44)
                                        } else {
                                            Spacer(minLength: 44)
                                            messageBubble(message.text, isAssistant: false)
                                        }
                                    }
                                    .id(message.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        }
                        .onChange(of: messages.count) { _, _ in
                            if let lastID = messages.last?.id {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    scrollProxy.scrollTo(lastID, anchor: .bottom)
                                }
                            }
                        }
                    }

                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            TextField("Rabia'ya sor…", text: $questionText, axis: .vertical)
                                .textInputAutocapitalization(.sentences)
                                .lineLimit(1...4)
                                .focused($isQuestionFieldFocused)
                                .submitLabel(.send)
                                .onSubmit {
                                    sendQuestion()
                                }
                                .padding(12)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(.rect(cornerRadius: 12))

                            Button {
                                sendQuestion()
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(.teal)
                                        .frame(width: 44, height: 44)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.teal)
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoading || questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        if !isPremium {
                            Text("Ücretsiz kullanım: günlük 3 soru hakkı")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(.bar)
                }
                .navigationTitle("Rabia")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isPresented = false
                            messages = [ManeviMessage(role: .assistant, text: "Selâmün aleyküm 💚 Ben Rabia. Aklında ne varsa sor, dinliyorum.")]
                            questionText = ""
                        } label: {
                            Label("Görüşmeyi Sonlandır", systemImage: "xmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
        }
        .alert("Soru hakkınız doldu", isPresented: $showLimitAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Bugün için 3 soru hakkınızı kullandınız. Premium ile Rabia ile sınırsız devam edebilirsiniz.")
        }
    }

    private func messageBubble(_ text: String, isAssistant: Bool) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(isAssistant ? Color.primary : Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isAssistant ? Color(.secondarySystemGroupedBackground) : Color.teal)
            .clipShape(.rect(cornerRadius: 14))
    }

    private func sendQuestion() {
        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isQuestionFieldFocused = false
        dismissKeyboard()

        Task {
            if !isPremium {
                if let info = try? await RevenueCatService.shared.customerInfo(), RevenueCatService.shared.hasActiveEntitlement(info) {
                    isPremium = true
                }
            }

            if !isPremium && !canAskFreeQuestionToday() {
                showLimitAlert = true
                return
            }

            messages.append(ManeviMessage(role: .user, text: trimmed))
            questionText = ""
            isLoading = true

            let response = try? await geminiService.answerSpiritualQuestion(trimmed)
            messages.append(
                ManeviMessage(
                    role: .assistant,
                    text: response ?? "Şu an yanıt üretemedim. Birazdan tekrar deneyelim."
                )
            )
            if !isPremium {
                markFreeQuestionAsked()
            }
            isLoading = false
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func canAskFreeQuestionToday() -> Bool {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let savedDate = Date(timeIntervalSince1970: freeDate)
        if !Calendar.current.isDate(savedDate, inSameDayAs: todayStart) {
            return true
        }
        return freeCount < 3
    }

    private func markFreeQuestionAsked() {
        let now = Date()
        let todayStart = Calendar.current.startOfDay(for: now)
        let savedDate = Date(timeIntervalSince1970: freeDate)

        if !Calendar.current.isDate(savedDate, inSameDayAs: todayStart) {
            freeDate = now.timeIntervalSince1970
            freeCount = 1
        } else {
            freeCount += 1
        }
    }

}

nonisolated struct ManeviMessage: Identifiable, Equatable, Sendable {
    nonisolated enum Role: String, Sendable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}
