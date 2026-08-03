import Foundation

struct AppActivityEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var sessionID: UUID
    var appBundleID: String
    var appName: String
    var windowTitle: String?
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Double

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        appBundleID: String,
        appName: String,
        windowTitle: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        durationSeconds: Double = 0
    ) {
        self.id = id
        self.sessionID = sessionID
        self.appBundleID = appBundleID
        self.appName = appName
        self.windowTitle = windowTitle
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
    }
}
