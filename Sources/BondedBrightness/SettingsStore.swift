import Foundation

struct AppSettings {
    var isPaused: Bool
    var primaryOffset: Double
    var secondaryOffset: Double
    var autoLaunchAtLogin: Bool
}

final class SettingsStore {
    private enum Key {
        static let isPaused = "isPaused"
        static let primaryOffset = "primaryOffset"
        static let secondaryOffset = "secondaryOffset"
        static let autoLaunchAtLogin = "autoLaunchAtLogin"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Key.autoLaunchAtLogin) == nil {
            defaults.set(true, forKey: Key.autoLaunchAtLogin)
        }
    }

    var settings: AppSettings {
        AppSettings(
            isPaused: defaults.bool(forKey: Key.isPaused),
            primaryOffset: defaults.double(forKey: Key.primaryOffset),
            secondaryOffset: defaults.double(forKey: Key.secondaryOffset),
            autoLaunchAtLogin: defaults.bool(forKey: Key.autoLaunchAtLogin)
        )
    }

    func setPaused(_ isPaused: Bool) {
        defaults.set(isPaused, forKey: Key.isPaused)
    }

    func setPrimaryOffset(_ offset: Double) {
        defaults.set(clampedOffset(offset), forKey: Key.primaryOffset)
    }

    func setSecondaryOffset(_ offset: Double) {
        defaults.set(clampedOffset(offset), forKey: Key.secondaryOffset)
    }

    func setAutoLaunchAtLogin(_ enabled: Bool) {
        defaults.set(enabled, forKey: Key.autoLaunchAtLogin)
    }

    private func clampedOffset(_ value: Double) -> Double {
        min(max(value, -1), 1)
    }
}
