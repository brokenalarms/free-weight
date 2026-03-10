import UIKit
import ImageIO

final class ThumbnailCache: Sendable {
    static let shared = ThumbnailCache()

    // Using NSCache directly; it's thread-safe internally
    private let cache = NSCache<NSURL, UIImage>()

    init() {
        cache.countLimit = 200
    }

    func thumbnail(for url: URL, targetSize: CGSize, scopedURL: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        return await Task.detached(priority: .utility) { [cache, scopedURL] in
            guard scopedURL.startAccessingSecurityScopedResource() else { return nil }
            defer { scopedURL.stopAccessingSecurityScopedResource() }

            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                return nil
            }
            let maxDimension = max(targetSize.width, targetSize.height) * UIScreen.main.scale
            let options: [CFString: Any] = [
                kCGImageSourceThumbnailMaxPixelSize: maxDimension,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                return nil
            }
            let thumb = UIImage(cgImage: cgImage)
            cache.setObject(thumb, forKey: url as NSURL)
            return thumb
        }.value
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
