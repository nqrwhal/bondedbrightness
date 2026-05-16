import BondedBrightnessCore
import Foundation

struct SyncStatus {
    var message: String = "Starting"
    var primaryName: String?
    var secondaryName: String?
    var primaryBrightness: Double?
    var secondaryBrightness: Double?
    var targetBrightness: Double?
    var lastError: String?
}

@MainActor
final class BrightnessSyncController: NSObject {
    private let displayClient: DisplayBrightnessClient
    private let settingsStore: SettingsStore
    private var timer: Timer?
    private var notifier: DisplayServicesBrightnessNotifier?
    private var lastPrimaryBrightness: Double?

    private(set) var status = SyncStatus()
    var onStatusChange: (() -> Void)?

    init(displayClient: DisplayBrightnessClient, settingsStore: SettingsStore) {
        self.displayClient = displayClient
        self.settingsStore = settingsStore
        super.init()
    }

    func start() {
        if notifier == nil, let eventNotifier = try? DisplayServicesBrightnessNotifier() {
            eventNotifier.onBrightnessChange = { [weak self] _ in
                Task { @MainActor in
                    self?.syncNow()
                }
            }

            do {
                try eventNotifier.start()
                notifier = eventNotifier
            } catch {
                status.lastError = error.localizedDescription
                status.message = "Notification unavailable"
                notifyStatusChanged()
            }
        }

        syncNow()
        let timer = Timer(
            timeInterval: 0.25,
            target: self,
            selector: #selector(timerFired),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        notifier?.stop()
        notifier = nil
    }

    func setPaused(_ paused: Bool) {
        settingsStore.setPaused(paused)
        syncNow()
    }

    func changePrimaryOffset(by delta: Double) {
        let settings = settingsStore.settings
        settingsStore.setPrimaryOffset(settings.primaryOffset + delta)
        syncNow()
    }

    func changeSecondaryOffset(by delta: Double) {
        let settings = settingsStore.settings
        settingsStore.setSecondaryOffset(settings.secondaryOffset + delta)
        syncNow()
    }

    func resetOffsets() {
        settingsStore.setPrimaryOffset(0)
        settingsStore.setSecondaryOffset(0)
        syncNow()
    }

    func syncNow() {
        do {
            try performSync()
        } catch {
            status.lastError = error.localizedDescription
            status.message = "Needs attention"
            notifyStatusChanged()
        }
    }

    private func performSync() throws {
        let settings = settingsStore.settings
        let displays = try displayClient.onlineDisplays()

        guard let primary = displays.first(where: \.isMain) else {
            updateStatus(message: "No main display", settings: settings)
            return
        }

        guard let secondary = selectSecondaryDisplay(from: displays, primary: primary) else {
            updateStatus(
                message: "Connect a second display",
                primary: primary,
                settings: settings
            )
            return
        }

        let primaryBrightness = try displayClient.brightness(for: primary)
        let secondaryBrightness = try displayClient.brightness(for: secondary)
        let target = BrightnessMath.secondaryBrightness(
            primaryBrightness: primaryBrightness,
            primaryOffset: settings.primaryOffset,
            secondaryOffset: settings.secondaryOffset
        )

        if !settings.isPaused {
            let secondaryNeedsSync = BrightnessMath.isMeaningfullyDifferent(secondaryBrightness, target)

            if secondaryNeedsSync {
                try displayClient.setBrightness(target, for: secondary)
            }
        }

        status = SyncStatus(
            message: settings.isPaused ? "Paused" : "Synced",
            primaryName: primary.name,
            secondaryName: secondary.name,
            primaryBrightness: primaryBrightness,
            secondaryBrightness: settings.isPaused ? secondaryBrightness : target,
            targetBrightness: target,
            lastError: nil
        )
        notifyStatusChanged()
    }

    private func selectSecondaryDisplay(
        from displays: [ManagedDisplay],
        primary: ManagedDisplay
    ) -> ManagedDisplay? {
        let secondaryDisplays = displays.filter { $0.id != primary.id }

        return secondaryDisplays.first {
            $0.name.localizedCaseInsensitiveContains("Studio Display")
        } ?? secondaryDisplays.first
    }

    private func updateStatus(
        message: String,
        primary: ManagedDisplay? = nil,
        settings: AppSettings
    ) {
        status = SyncStatus(
            message: settings.isPaused ? "Paused" : message,
            primaryName: primary?.name,
            secondaryName: nil,
            primaryBrightness: nil,
            secondaryBrightness: nil,
            targetBrightness: nil,
            lastError: nil
        )
        notifyStatusChanged()
    }

    private func notifyStatusChanged() {
        onStatusChange?()
    }

    @objc private func timerFired() {
        syncNow()
    }
}
