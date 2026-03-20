import SwiftUI

struct ErrorRecoveryView: View {
    let context: BootstrapFailureContext
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.10),
                    Color(red: 0.08, green: 0.09, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 82, height: 82)
                    .background(.white.opacity(0.08))
                    .clipShape(Circle())

                VStack(spacing: 10) {
                    Text(LocalizedStringKey(context.titleKey))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(LocalizedStringKey(context.messageKey))
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.66))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

#if DEBUG
                if let debugMessage = context.debugMessage {
                    Text(debugMessage)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.white.opacity(0.46))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
#endif

                Button(action: onRetry) {
                    Text("tekrar_dene")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .themedPrimaryButton(cornerRadius: 18, fill: .white.opacity(0.16), foreground: .white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
            }
            .frame(maxWidth: 420)
        }
    }
}
