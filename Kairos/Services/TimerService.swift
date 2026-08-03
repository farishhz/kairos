import Combine
import Foundation

@MainActor
final class TimerService: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false

    private var timer: DispatchSourceTimer?
    private var endTime: Date?

    private func cancelTimer() {
        self.timer?.cancel()
        self.timer = nil
    }

    func start(duration: TimeInterval) {
        self.cancelTimer()

        self.remainingTime = duration
        self.endTime = Date().addingTimeInterval(duration)
        self.isRunning = true
        self.isPaused = false

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 1)

        timer.setEventHandler { [weak self] in
            guard let self else { return }

            let now = Date()
            let remaining = self.endTime?.timeIntervalSince(now) ?? 0

            if remaining <= 0 {
                self.stop()
            } else {
                self.remainingTime = remaining
            }
        }

        self.timer = timer
        timer.resume()
    }

    func stop() {
        self.cancelTimer()
        self.endTime = nil
        self.isRunning = false
        self.isPaused = false
        self.remainingTime = 0
    }

    func pause() {
        guard self.isRunning, let endTime = self.endTime else { return }

        let now = Date()
        self.remainingTime = max(0, endTime.timeIntervalSince(now))
        self.cancelTimer()
        self.endTime = nil
        self.isRunning = false
        self.isPaused = true
    }

    func resume() {
        guard self.isPaused, self.remainingTime > 0 else { return }
        self.start(duration: self.remainingTime)
    }

    func elapsedTime(totalDuration: TimeInterval, now: Date = Date()) -> TimeInterval {
        max(0, totalDuration - currentRemainingTime(now: now))
    }

    private func currentRemainingTime(now: Date) -> TimeInterval {
        if self.isRunning, let endTime = self.endTime {
            return max(0, endTime.timeIntervalSince(now))
        }

        return max(0, self.remainingTime)
    }
}
