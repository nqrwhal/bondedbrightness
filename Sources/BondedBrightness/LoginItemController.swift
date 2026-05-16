import Foundation
import ServiceManagement

final class LoginItemController {
    private let settingsStore: SettingsStore
    private(set) var lastError: String?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }

        return settingsStore.settings.autoLaunchAtLogin
    }

    func applySavedPreference() {
        setEnabled(settingsStore.settings.autoLaunchAtLogin)
    }

    func setEnabled(_ enabled: Bool) {
        settingsStore.setAutoLaunchAtLogin(enabled)
        lastError = nil

        guard #available(macOS 13.0, *) else {
            lastError = "Login items require macOS 13 or newer."
            return
        }

        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}
