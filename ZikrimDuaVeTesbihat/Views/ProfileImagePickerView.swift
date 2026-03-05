import SwiftUI
import PhotosUI

struct ProfileImagePickerView: View {
    @Binding var selectedImageData: Data?
    let onCameraTap: () -> Void

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Galeriden Seç", systemImage: "photo.on.rectangle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)

            Button {
                onCameraTap()
            } label: {
                Label("Kamera", systemImage: "camera")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
        .onChange(of: selectedItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedImageData = data
                    }
                }
            }
        }
    }
}
