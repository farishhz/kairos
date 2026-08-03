import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let updaterManager = UpdaterManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        updaterManager.start()
        self.menuBarController = MenuBarController()
        _ = self.menuBarController

        AnalyticsPermissionsManager.shared.requestPermissions()
    }
}
