import Foundation

struct PomodoroTaskPlan: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var sessionsTarget: Int
    var longBreakEvery: Int

    init(
        id: UUID = UUID(),
        title: String,
        focusMinutes: Int,
        shortBreakMinutes: Int,
        longBreakMinutes: Int,
        sessionsTarget: Int,
        longBreakEvery: Int
    ) {
        self.id = id
        self.title = title
        self.focusMinutes = focusMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.sessionsTarget = sessionsTarget
        self.longBreakEvery = longBreakEvery
    }

    var focusDuration: TimeInterval {
        TimeInterval(self.focusMinutes * 60)
    }

    var shortBreakDuration: TimeInterval {
        TimeInterval(self.shortBreakMinutes * 60)
    }

    var longBreakDuration: TimeInterval {
        TimeInterval(self.longBreakMinutes * 60)
    }
}
