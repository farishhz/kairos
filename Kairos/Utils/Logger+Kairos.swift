import Foundation
import OSLog

extension Logger {
    static let kairosSubsystem = Bundle.main.bundleIdentifier ?? "com.farishhz.kairos"

    static let analytics = Logger(subsystem: kairosSubsystem, category: "Analytics")
    static let tracking = Logger(subsystem: kairosSubsystem, category: "Tracking")
    static let session = Logger(subsystem: kairosSubsystem, category: "Session")
    static let ui = Logger(subsystem: kairosSubsystem, category: "UI")
    static let sound = Logger(subsystem: kairosSubsystem, category: "Sound")
    static let browser = Logger(subsystem: kairosSubsystem, category: "Browser")
    static let permissions = Logger(subsystem: kairosSubsystem, category: "Permissions")
    static let store = Logger(subsystem: kairosSubsystem, category: "Store")
}
