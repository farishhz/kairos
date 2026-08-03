import Foundation
import OSLog

final class AnalyticsStore {
    static let shared = AnalyticsStore()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let ioQueue = DispatchQueue(label: "com.farishhz.kairos.analyticsstore.io")
    private let queueKey = DispatchSpecificKey<Void>()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        ioQueue.setSpecific(key: queueKey, value: ())
        bootstrapDirectory()
    }

    // MARK: - Directory

    private func bootstrapDirectory() {
        let url = AppConstants.AnalyticsSettings.analyticsDirectoryURL
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func fileURL(for filename: String) -> URL {
        AppConstants.AnalyticsSettings.analyticsDirectoryURL.appendingPathComponent(filename)
    }

    // MARK: - Focus Sessions

    func loadFocusSessions() -> [FocusSessionRecord] {
        load(from: AppConstants.AnalyticsSettings.focusSessionsFile) ?? []
    }

    func saveFocusSessions(_ records: [FocusSessionRecord]) {
        save(records, to: AppConstants.AnalyticsSettings.focusSessionsFile)
    }

    func appendFocusSession(_ record: FocusSessionRecord) {
        var records = loadFocusSessions()
        records.append(record)
        saveFocusSessions(records)
    }

    func updateFocusSession(_ record: FocusSessionRecord) {
        var records = loadFocusSessions()
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        saveFocusSessions(records)
    }

    // MARK: - App Activity

    func loadAppActivityEvents() -> [AppActivityEvent] {
        load(from: AppConstants.AnalyticsSettings.appActivityFile) ?? []
    }

    func saveAppActivityEvents(_ events: [AppActivityEvent]) {
        save(events, to: AppConstants.AnalyticsSettings.appActivityFile)
    }

    func appendAppActivityEvents(_ events: [AppActivityEvent]) {
        var existing = loadAppActivityEvents()
        existing.append(contentsOf: events)
        saveAppActivityEvents(existing)
    }

    // MARK: - Website Visits

    func loadWebsiteVisits() -> [WebsiteVisitRecord] {
        let visits: [WebsiteVisitRecord] = load(from: AppConstants.AnalyticsSettings.websiteVisitsFile) ?? []
        Logger.store.debug("loadWebsiteVisits — found \(visits.count) records")
        return visits
    }

    func saveWebsiteVisits(_ records: [WebsiteVisitRecord]) {
        save(records, to: AppConstants.AnalyticsSettings.websiteVisitsFile)
    }

    func appendWebsiteVisits(_ records: [WebsiteVisitRecord]) {
        Logger.store.debug("appendWebsiteVisits — saving \(records.count) new records")
        var existing = loadWebsiteVisits()
        existing.append(contentsOf: records)
        saveWebsiteVisits(existing)
        Logger.store.debug("appendWebsiteVisits — total saved: \(existing.count) records")
    }

    // MARK: - Prune

    func pruneOldData() {
        let days = AppConstants.AnalyticsSettings.retentionDays
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        var sessions = loadFocusSessions()
        sessions.removeAll { $0.startedAt < cutoff }
        saveFocusSessions(sessions)

        var appEvents = loadAppActivityEvents()
        appEvents.removeAll { $0.startedAt < cutoff }
        saveAppActivityEvents(appEvents)

        var webVisits = loadWebsiteVisits()
        webVisits.removeAll { $0.startedAt < cutoff }
        saveWebsiteVisits(webVisits)
    }

    // MARK: - Generic Load/Save

    private func load<T: Decodable>(from filename: String) -> T? {
        syncIO {
            let url = fileURL(for: filename)
            guard let data = try? Data(contentsOf: url) else { return nil }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                Logger.store.error(
                    "Decode error for \(filename, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
    }

    private func save<T: Encodable>(_ value: T, to filename: String) {
        syncIO {
            let url = self.fileURL(for: filename)
            do {
                let data = try self.encoder.encode(value)
                try data.write(to: url, options: .atomic)
            } catch {
                Logger.store.error(
                    "Save error for \(filename, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func syncIO<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return work()
        }

        return ioQueue.sync(execute: work)
    }
}
