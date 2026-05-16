import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private let displayClient = DisplayServicesBrightnessClient()
    private lazy var loginItemController = LoginItemController(settingsStore: settingsStore)
    private lazy var syncController = BrightnessSyncController(
        displayClient: displayClient,
        settingsStore: settingsStore
    )
    private var menuController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        loginItemController.applySavedPreference()
        menuController = StatusMenuController(
            syncController: syncController,
            settingsStore: settingsStore,
            loginItemController: loginItemController
        )
        syncController.start()
    }
}
