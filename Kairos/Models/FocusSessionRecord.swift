import Foundation

struct FocusSessionRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date?
    var plannedMinutes: Int
    var actualFocusSeconds: Double
    var sessionMode: SessionMode
    var taskTitle: String?
    var taskPlanId: UUID?
    var completed: Bool
    var interruptedReason: String?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        plannedMinutes: Int,
        actualFocusSeconds: Double = 0,
        sessionMode: SessionMode,
        taskTitle: String? = nil,
        taskPlanId: UUID? = nil,
        completed: Bool = false,
        interruptedReason: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedMinutes = plannedMinutes
        self.actualFocusSeconds = actualFocusSeconds
        self.sessionMode = sessionMode
        self.taskTitle = taskTitle
        self.taskPlanId = taskPlanId
        self.completed = completed
        self.interruptedReason = interruptedReason
    }

    var date: Date {
        Calendar.current.startOfDay(for: startedAt)
    }

    var durationMinutes: Double {
        actualFocusSeconds / 60.0
    }
}
