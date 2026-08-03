import Foundation
import AppKit

/// Fetches and caches website favicons. Downloads icons from the page or falls back
/// to domain-level favicon URLs, converting them to 32x32 PNG.
actor WebIconService {
    static let shared = WebIconService()

    private let cache = IconCacheActor(maxEntries: 200)

    private init() {}

    /// Returns cached favicon data for a domain, or fetches and caches it.
    /// - Parameters:
    ///   - domain: The domain name (e.g. "github.com")
    ///   - sourceURL: The full page URL for extracting the page-specific icon
    /// - Returns: PNG favicon data, or nil if unavailable
    func favicon(for domain: String, sourceURL: String?) async -> Data? {
        if let cached = await cache.get(domain) {
            return cached
        }

        // Try extracting from the actual page first
        if let sourceURL = sourceURL,
           let faviconURL = await extractFaviconURL(from: sourceURL) {
            if let data = await fetchIcon(from: faviconURL) {
                await cache.set(domain, value: data)
                return data
            }
        }

        // Fallback to domain-level favicons
        let candidates = [
            "https://\(domain)/favicon.ico",
            "https://www.\(domain)/favicon.ico",
            "https://\(domain)/favicon.png",
            "https://www.\(domain)/favicon.png",
        ]

        for urlString in candidates {
            if let data = await fetchIcon(from: urlString) {
                await cache.set(domain, value: data)
                return data
            }
        }

        return nil
    }

    // MARK: - Private

    private func extractFaviconURL(from pageURL: String) async -> String? {
        guard let url = URL(string: pageURL) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }

            let patterns = [
                #"<link[^>]*rel=["\'](?:shortcut )?icon["\'][^>]*href=["\']([^"\']+)["\']"#,
                #"<link[^>]*href=["\']([^"\']+)["\'][^>]*rel=["\'](?:shortcut )?icon["\']"#,
            ]

            for pattern in patterns {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: html.count)

                if let match = regex.firstMatch(in: html, options: [], range: range) {
                    let hrefRange = match.range(at: 1)
                    if let swiftRange = Range(hrefRange, in: html) {
                        let href = String(html[swiftRange])
                        return absoluteURL(href, base: pageURL)
                    }
                }
            }
        } catch {
            // Failed to fetch page, fall through to domain favicon
        }

        return nil
    }

    private func absoluteURL(_ href: String, base: String) -> String {
        if href.hasPrefix("http") {
            return href
        } else if href.hasPrefix("//") {
            let scheme = base.hasPrefix("https://") ? "https:" : "http:"
            return scheme + href
        } else if href.hasPrefix("/"), let baseURL = URL(string: base) {
            return "\(baseURL.scheme!)://\(baseURL.host!)\(href)"
        } else if let baseURL = URL(string: base) {
            let basePath = baseURL.deletingLastPathComponent().absoluteString
            return basePath + href
        }
        return href
    }

    private func fetchIcon(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let originalImage = NSImage(data: data) else { return nil }
            return await convertToPNG(originalImage)
        } catch {
            return nil
        }
    }

    private func convertToPNG(_ image: NSImage) async -> Data? {
        let targetSize = NSSize(width: 32, height: 32)
        let resizedImage = NSImage(size: targetSize, flipped: false) { rect in
            image.draw(in: rect)
            return true
        }

        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:])
    }
}
