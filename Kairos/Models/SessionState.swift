import Foundation

enum SessionState: Equatable {
    case idle
    case configured(mode: SessionMode, phase: SessionPhase)
    case running(mode: SessionMode, phase: SessionPhase)
    case completed(mode: SessionMode)
}

enum SessionMode: String, Codable, Equatable {
    case quickSession
    case taskPlan
}

enum SessionPhase: String, Codable, Equatable {
    case focus
    case shortBreak
    case longBreak
    case completed
}

extension SessionState {
    var mode: SessionMode? {
        switch self {
        case .idle:
            return nil
        case .configured(let mode, _), .running(let mode, _), .completed(let mode):
            return mode
        }
    }

    var phase: SessionPhase? {
        switch self {
        case .idle:
            return nil
        case .configured(_, let phase), .running(_, let phase):
            return phase
        case .completed:
            return .completed
        }
    }

    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }

    var isBreakPhase: Bool {
        switch self.phase {
        case .shortBreak, .longBreak:
            return true
        case .focus, .completed, .none:
            return false
        }
    }
}

enum BreakType: String, Equatable {
    case short
    case long

    var sessionPhase: SessionPhase {
        switch self {
        case .short:
            return .shortBreak
        case .long:
            return .longBreak
        }
    }
}
