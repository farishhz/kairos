import AVFoundation
import Combine
import Foundation
import OSLog

@MainActor
final class FocusSessionManager: ObservableObject {
    static let shared = FocusSessionManager()

    @Published var activeTask: String = ""
    @Published var duration: TimeInterval = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var state: SessionState = .idle

    private let activityTracker: ActivityTracker
    private let analyticsStore: AnalyticsStore
    private(set) var timerService = TimerService()

    private var cancellables = Set<AnyCancellable>()
    private var completionHandled = false
    private let soundAlertPlayer = SoundAlertPlayer()
    private var activeSessionRecord: FocusSessionRecord?

    init(
        activityTracker: ActivityTracker = .shared,
        analyticsStore: AnalyticsStore = .shared)
    {
        self.activityTracker = activityTracker
        self.analyticsStore = analyticsStore

        self.timerService.$remainingTime
            .combineLatest(self.timerService.$isRunning, self.timerService.$isPaused)
            .sink { [weak self] remainingTime, isRunning, timerIsPaused in
                guard let self else { return }

                if !self.state.isIdle,
                   !self.completionHandled,
                   !isRunning,
                   !timerIsPaused,
                   remainingTime <= 0
                {
                    self.handleTimerFinished()
                }
            }
            .store(in: &self.cancellables)
    }

    func start(task: String, duration: TimeInterval) {
        self.soundAlertPlayer.stop()
        self.activeTask = task
        self.duration = duration
        self.isActive = true
        self.isPaused = false
        self.state = .running(mode: .quickSession, phase: .focus)
        self.completionHandled = false

        if AppConstants.AnalyticsSettings.isAnalyticsEnabled {
            let sessionRecord = FocusSessionRecord(
                plannedMinutes: Int(duration / 60),
                actualFocusSeconds: 0,
                sessionMode: .quickSession,
                taskTitle: task,
                taskPlanId: nil
            )
            self.activeSessionRecord = sessionRecord
            self.activityTracker.startTracking(sessionID: sessionRecord.id)
        }

        self.timerService.start(duration: duration)
        Logger.session.info("Started focus session: \(task, privacy: .public) for \(Int(duration / 60))m")
    }

    func stop() {
        finalizeAnalyticsSession(completed: false, interruptedReason: "User stopped")
        self.soundAlertPlayer.stop()
        self.timerService.stop()
        self.completionHandled = true
        self.resetSession()
        Logger.session.info("Stopped focus session")
    }

    func pause() {
        guard self.isActive, !self.isPaused else { return }
        self.timerService.pause()
        self.isPaused = true
        self.activityTracker.pauseTracking()
        Logger.session.info("Paused focus session")
    }

    func resume() {
        guard self.isActive, self.isPaused else { return }
        self.timerService.resume()
        self.isPaused = false
        if let sessionRecord = self.activeSessionRecord {
            self.activityTracker.resumeTracking(sessionID: sessionRecord.id)
        }
        Logger.session.info("Resumed focus session")
    }

    private func breakDuration(for type: BreakType) -> TimeInterval {
        let minutes = type == .short
            ? AppConstants.BreakDuration.shortMinutes
            : AppConstants.BreakDuration.longMinutes
        return TimeInterval(minutes * 60)
    }

    private func handleTimerFinished() {
        self.completionHandled = true
        self.playCompletionSoundIfNeeded()

        switch self.state.phase {
        case .focus:
            if self.state.mode == .quickSession {
                finalizeAnalyticsSession(completed: true)
            }
            self.prepareBreak(type: .short)
            WindowManager.shared.hideFloating()
            MenuBarController.shared?.showPopover()
            Logger.session.info("Focus timer finished — showing break")
        case .shortBreak, .longBreak:
            self.completeSession(mode: self.state.mode ?? .quickSession)
            WindowManager.shared.hideFloating()
            MenuBarController.shared?.showPopover()
            Logger.session.info("Break timer finished — showing menu bar")
        case .completed, .none:
            break
        }
    }

    private func resetSession() {
        self.isActive = false
        self.isPaused = false
        self.activeTask = ""
        self.duration = 0
        self.state = .idle
        self.completionHandled = true
        self.activeSessionRecord = nil
    }

    private func completeSession(mode: SessionMode) {
        self.isActive = false
        self.isPaused = false
        self.activeTask = ""
        self.duration = 0
        self.state = .completed(mode: mode)
        self.completionHandled = true
        self.activeSessionRecord = nil
    }

    private func finalizeAnalyticsSession(completed: Bool, interruptedReason: String? = nil) {
        guard AppConstants.AnalyticsSettings.isAnalyticsEnabled,
              var sessionRecord = self.activeSessionRecord else { return }

        let endedAt = Date()
        let (appEvents, websiteVisits) = self.activityTracker.stopTracking()
        let trackedFocusSeconds = appEvents.reduce(0) { $0 + $1.durationSeconds }
        let elapsedSessionSeconds = self.timerService.elapsedTime(totalDuration: self.duration, now: endedAt)
        let plannedFocusSeconds = Double(sessionRecord.plannedMinutes * 60)
        let focusSeconds = min(plannedFocusSeconds, max(trackedFocusSeconds, elapsedSessionSeconds))

        sessionRecord.endedAt = endedAt
        sessionRecord.actualFocusSeconds = focusSeconds
        sessionRecord.completed = completed
        sessionRecord.interruptedReason = interruptedReason

        self.analyticsStore.updateFocusSession(sessionRecord)
        self.analyticsStore.appendAppActivityEvents(appEvents)
        self.analyticsStore.appendWebsiteVisits(websiteVisits)

        self.activeSessionRecord = nil
        Logger.session.info("Finalized analytics session: \(focusSeconds / 60, privacy: .public) min focus")
    }

    private func prepareBreak(type: BreakType) {
        self.activeTask = ""
        self.duration = self.breakDuration(for: type)
        self.isActive = false
        self.isPaused = false
        self.state = .configured(mode: .quickSession, phase: type.sessionPhase)
    }

    private func playCompletionSoundIfNeeded() {
        let defaults = UserDefaults.standard
        let selectedSoundID = defaults.string(forKey: AppConstants.SoundSettings.selectedSoundKey)
            ?? AppConstants.SoundSettings.defaultSoundID
        let autoMuteAfter5Seconds =
            defaults.object(forKey: AppConstants.SoundSettings.autoMuteAfter5SecondsKey) as? Bool
                ?? true
        let soundVolume = defaults.object(forKey: AppConstants.SoundSettings.volumeKey) as? Double
            ?? AppConstants.SoundSettings.defaultVolume

        self.soundAlertPlayer.play(
            soundID: selectedSoundID,
            volume: soundVolume,
            autoMuteAfter5Seconds: autoMuteAfter5Seconds)
    }
}

@MainActor
private final class SoundAlertPlayer {
    private var player: AVAudioPlayer?
    private var autoMuteWorkItem: DispatchWorkItem?

    func play(soundID: String, volume: Double, autoMuteAfter5Seconds: Bool) {
        self.stop()

        guard let option = AppConstants.SoundSettings.options.first(where: { $0.id == soundID }) else {
            Logger.sound.error("Unknown sound id: \(soundID, privacy: .public)")
            return
        }

        let soundURL =
            Bundle.main.url(
                forResource: option.fileName,
                withExtension: option.fileExtension,
                subdirectory: "Sounds") ??
            Bundle.main.url(
                forResource: option.fileName,
                withExtension: option.fileExtension)

        guard let soundURL else {
            Logger.sound.error("Sound file not found: \(option.fileName).\(option.fileExtension, privacy: .public)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            self.player = player
            player.volume = Float(min(1.0, max(0.0, volume)))
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            Logger.sound.info("Playing sound: \(option.title, privacy: .public)")
        } catch {
            Logger.sound.error("Failed to play sound: \(error.localizedDescription, privacy: .public)")
            return
        }

        guard autoMuteAfter5Seconds else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.stop()
        }

        self.autoMuteWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
    }

    func stop() {
        self.autoMuteWorkItem?.cancel()
        self.autoMuteWorkItem = nil
        self.player?.stop()
        self.player = nil
    }
}
