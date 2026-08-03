import Foundation

enum KairosError: LocalizedError {
    case fileIOError(filename: String, underlying: Error)
    case decodeError(filename: String, underlying: Error)
    case trackingError(message: String)
    case permissionError(message: String)
    case soundNotFound(id: String)
    case invalidSessionState

    var errorDescription: String? {
        switch self {
        case .fileIOError(let filename, _):
            return "Failed to read or write file: \(filename)"
        case .decodeError(let filename, _):
            return "Failed to decode data from file: \(filename)"
        case .trackingError(let message):
            return "Tracking error: \(message)"
        case .permissionError(let message):
            return "Permission denied: \(message)"
        case .soundNotFound(let id):
            return "Sound not found: \(id)"
        case .invalidSessionState:
            return "Invalid session state"
        }
    }

    var failureReason: String? {
        switch self {
        case .fileIOError(_, let underlying),
             .decodeError(_, let underlying):
            return underlying.localizedDescription
        case .trackingError, .permissionError, .soundNotFound, .invalidSessionState:
            return nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileIOError:
            return "Check disk space and file permissions."
        case .decodeError:
            return "The data file may be corrupted. Delete it to reset."
        case .permissionError:
            return "Open System Settings > Privacy & Security to grant permission."
        case .soundNotFound:
            return "Select a different sound in Settings."
        default:
            return nil
        }
    }
}
