import AppKit

enum IconUtils {
    static func getAppIconAsPNG(for bundleId: String) -> Data? {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first,
              let icon = app.icon else {
            return nil
        }
        let resizedImage = NSImage(size: NSSize(width: 32, height: 32), flipped: false) { rect in
            icon.draw(in: rect)
            return true
        }
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    static func getAppIcon(for bundleId: String) -> NSImage? {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first else {
            return nil
        }
        return app.icon
    }
}
