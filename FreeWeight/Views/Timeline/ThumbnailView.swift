import SwiftUI

/// Async thumbnail loading from ThumbnailCache with security-scoped access.
struct ThumbnailView: View {
    let url: URL?
    let targetSize: CGSize
    let scopedURL: URL

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray.opacity(0.5))
                            .font(.caption)
                    }
            }
        }
        .task(id: url) {
            guard let url else { return }
            image = await ThumbnailCache.shared.thumbnail(
                for: url,
                targetSize: targetSize,
                scopedURL: scopedURL
            )
        }
    }
}

/// Full-size photo loading with security-scoped access.
struct ScopedPhotoView: View {
    let url: URL?
    let scopedURL: URL

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if url != nil {
                ProgressView()
                    .tint(.white)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
            }
        }
        .task(id: url) {
            guard let url else { return }
            image = await loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) async -> UIImage? {
        await Task.detached(priority: .userInitiated) { [scopedURL] in
            guard scopedURL.startAccessingSecurityScopedResource() else { return nil }
            defer { scopedURL.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }.value
    }
}
