import BondedBrightnessCore
import Foundation

struct SyncStatus {
    var message: String = "Starting"
    var primaryName: String?
    var linkedNames: [String] = []
    var primaryBrightness: Double?
    var linkedTargetBrightness: Double?
    var primaryModeTitle: String?
    var lastError: String?
}

@MainActor
final class BrightnessSyncController: NSObject {
    private let displayClient: DisplayBrightnessClient
    private let settingsStore: SettingsStore
    private let focusResolver = DisplayFocusResolver()
    private var timer: Timer?
    private var notifier: DisplayServicesBrightnessNotifier?

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

        guard let master = resolveMasterDisplay(from: displays, settings: settings) else {
            updateStatus(message: "No main display", settings: settings)
            return
        }

        let linkedDisplays = selectLinkedDisplays(from: displays, primary: master)
        guard !linkedDisplays.isEmpty else {
            updateStatus(
                message: "Connect another display",
                master: master,
                settings: settings
            )
            return
        }

        let masterBrightness = try displayClient.brightness(for: master)
        let target = BrightnessMath.secondaryBrightness(
            primaryBrightness: masterBrightness,
            primaryOffset: settings.primaryOffset,
            secondaryOffset: settings.secondaryOffset
        )

        if !settings.isPaused {
            for linkedDisplay in linkedDisplays {
                let linkedBrightness = try displayClient.brightness(for: linkedDisplay)
                let linkedNeedsSync = BrightnessMath.isMeaningfullyDifferent(linkedBrightness, target)

                if linkedNeedsSync {
                    try displayClient.setBrightness(target, for: linkedDisplay)
                }
            }
        }

        status = SyncStatus(
            message: settings.isPaused ? "Paused" : "Synced",
            primaryName: master.name,
            linkedNames: linkedDisplays.map(\.name),
            primaryBrightness: masterBrightness,
            linkedTargetBrightness: target,
            primaryModeTitle: settings.masterSelectionMode.title,
            lastError: nil
        )
        notifyStatusChanged()
    }

    private func resolveMasterDisplay(
        from displays: [ManagedDisplay],
        settings: AppSettings
    ) -> ManagedDisplay? {
        switch settings.masterSelectionMode {
        case .mainDisplay:
            return displays.first(where: \.isMain) ?? displays.first
        case .secondaryDisplay:
            return displays.first { !$0.isMain } ?? displays.first
        case .focusedApp:
            return focusResolver.focusedDisplay(in: displays)
                ?? displays.first(where: \.isMain)
                ?? displays.first
        }
    }

    private func selectLinkedDisplays(
        from displays: [ManagedDisplay],
        primary: ManagedDisplay
    ) -> [ManagedDisplay] {
        displays.filter { $0.id != primary.id }
    }

    private func updateStatus(
        message: String,
        master: ManagedDisplay? = nil,
        settings: AppSettings
    ) {
        status = SyncStatus(
            message: settings.isPaused ? "Paused" : message,
            primaryName: master?.name,
            linkedNames: [],
            primaryBrightness: nil,
            linkedTargetBrightness: nil,
            primaryModeTitle: settings.masterSelectionMode.title,
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
