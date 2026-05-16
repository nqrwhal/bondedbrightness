import AppKit
import Foundation

@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let syncController: BrightnessSyncController
    private let settingsStore: SettingsStore
    private let loginItemController: LoginItemController
    private var liveRefreshTimer: Timer?

    init(
        syncController: BrightnessSyncController,
        settingsStore: SettingsStore,
        loginItemController: LoginItemController
    ) {
        self.syncController = syncController
        self.settingsStore = settingsStore
        self.loginItemController = loginItemController
        super.init()

        statusItem.button?.image = NSImage(
            systemSymbolName: "sun.max",
            accessibilityDescription: "Bonded Brightness"
        )
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.title = ""
        statusItem.menu = menu
        menu.delegate = self

        syncController.onStatusChange = { [weak self] in
            self?.rebuildMenu()
        }

        rebuildMenu()
    }

    private func rebuildMenu() {
        let status = syncController.status
        let settings = settingsStore.settings

        menu.removeAllItems()
        menu.addItem(disabledItem("Bonded Brightness"))
        menu.addItem(disabledItem(status.message))

        if let primary = status.primaryName {
            menu.addItem(disabledItem("Primary: \(primary)"))
        }

        if let secondary = status.secondaryName {
            menu.addItem(disabledItem("Secondary: \(secondary)"))
        }

        if let primaryBrightness = status.primaryBrightness {
            menu.addItem(disabledItem("Primary brightness: \(percent(primaryBrightness))"))
        }

        if let targetBrightness = status.targetBrightness {
            menu.addItem(disabledItem("Secondary target: \(percent(targetBrightness))"))
        }

        if let error = status.lastError {
            menu.addItem(disabledItem("Error: \(error)"))
        }

        if let loginError = loginItemController.lastError {
            menu.addItem(disabledItem("Login item: \(loginError)"))
        }

        menu.addItem(.separator())

        let pauseItem = NSMenuItem(
            title: settings.isPaused ? "Resume Sync" : "Pause Sync",
            action: #selector(togglePaused),
            keyEquivalent: ""
        )
        pauseItem.target = self
        menu.addItem(pauseItem)

        let syncItem = NSMenuItem(title: "Sync Now", action: #selector(syncNow), keyEquivalent: "")
        syncItem.target = self
        menu.addItem(syncItem)

        menu.addItem(.separator())
        addOffsetItems(settings: settings)
        menu.addItem(.separator())

        let autoLaunchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        autoLaunchItem.target = self
        autoLaunchItem.state = settings.autoLaunchAtLogin ? .on : .off
        menu.addItem(autoLaunchItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.button?.toolTip = "Bonded Brightness: \(status.message)"
    }

    func menuWillOpen(_ menu: NSMenu) {
        liveRefreshTimer?.invalidate()
        let timer = Timer(
            timeInterval: 0.25,
            target: self,
            selector: #selector(refreshLiveMenu),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        liveRefreshTimer = timer
        refreshLiveMenu()
    }

    func menuDidClose(_ menu: NSMenu) {
        liveRefreshTimer?.invalidate()
        liveRefreshTimer = nil
    }

    private func addOffsetItems(settings: AppSettings) {
        menu.addItem(disabledItem("Primary offset: \(signedPercent(settings.primaryOffset))"))

        let decreasePrimary = NSMenuItem(
            title: "Primary Offset -5%",
            action: #selector(decreasePrimaryOffset),
            keyEquivalent: ""
        )
        decreasePrimary.target = self
        menu.addItem(decreasePrimary)

        let increasePrimary = NSMenuItem(
            title: "Primary Offset +5%",
            action: #selector(increasePrimaryOffset),
            keyEquivalent: ""
        )
        increasePrimary.target = self
        menu.addItem(increasePrimary)

        menu.addItem(disabledItem("Secondary offset: \(signedPercent(settings.secondaryOffset))"))

        let decreaseSecondary = NSMenuItem(
            title: "Secondary Offset -5%",
            action: #selector(decreaseSecondaryOffset),
            keyEquivalent: ""
        )
        decreaseSecondary.target = self
        menu.addItem(decreaseSecondary)

        let increaseSecondary = NSMenuItem(
            title: "Secondary Offset +5%",
            action: #selector(increaseSecondaryOffset),
            keyEquivalent: ""
        )
        increaseSecondary.target = self
        menu.addItem(increaseSecondary)

        let reset = NSMenuItem(title: "Reset Offsets", action: #selector(resetOffsets), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func togglePaused() {
        syncController.setPaused(!settingsStore.settings.isPaused)
    }

    @objc private func syncNow() {
        syncController.syncNow()
    }

    @objc private func refreshLiveMenu() {
        rebuildMenu()
    }

    @objc private func decreasePrimaryOffset() {
        syncController.changePrimaryOffset(by: -0.05)
    }

    @objc private func increasePrimaryOffset() {
        syncController.changePrimaryOffset(by: 0.05)
    }

    @objc private func decreaseSecondaryOffset() {
        syncController.changeSecondaryOffset(by: -0.05)
    }

    @objc private func increaseSecondaryOffset() {
        syncController.changeSecondaryOffset(by: 0.05)
    }

    @objc private func resetOffsets() {
        syncController.resetOffsets()
    }

    @objc private func toggleLaunchAtLogin() {
        loginItemController.setEnabled(!settingsStore.settings.autoLaunchAtLogin)
        rebuildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func signedPercent(_ value: Double) -> String {
        let percentValue = Int((value * 100).rounded())
        return percentValue >= 0 ? "+\(percentValue)%" : "\(percentValue)%"
    }
}
