import SwiftUI

extension Text {
    init(_ key: L10n.Key) {
        self.init(L10n.string(key))
    }
}

extension Label where Title == Text, Icon == Image {
    init(_ key: L10n.Key, systemImage: String) {
        self.init(L10n.string(key), systemImage: systemImage)
    }
}

extension Button where Label == Text {
    init(_ key: L10n.Key, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.init(role: role, action: action) {
            Text(key)
        }
    }
}

extension TextField where Label == Text {
    init(_ key: L10n.Key, text: Binding<String>) {
        self.init(LocalizedStringKey(L10n.string(key)), text: text)
    }

    init(_ key: L10n.Key, text: Binding<String>, axis: Axis) {
        self.init(LocalizedStringKey(L10n.string(key)), text: text, axis: axis)
    }
}

extension SecureField where Label == Text {
    init(_ key: L10n.Key, text: Binding<String>) {
        self.init(LocalizedStringKey(L10n.string(key)), text: text)
    }
}
