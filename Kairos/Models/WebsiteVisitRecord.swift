import Foundation

struct WebsiteVisitRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var sessionID: UUID
    var browserBundleID: String
    var browserName: String
    var domain: String
    var pageTitle: String?
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Double

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        browserBundleID: String,
        browserName: String,
        domain: String,
        pageTitle: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        durationSeconds: Double = 0
    ) {
        self.id = id
        self.sessionID = sessionID
        self.browserBundleID = browserBundleID
        self.browserName = browserName
        self.domain = domain
        self.pageTitle = pageTitle
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
    }
}
