import AppKit
import Foundation

@MainActor
final class DisplayIdentifier {
    private let displayClient: DisplayBrightnessClient
    private var overlayWindows: [NSWindow] = []

    init(displayClient: DisplayBrightnessClient) {
        self.displayClient = displayClient
    }

    func identify() {
        do {
            let displays = try displayClient.onlineDisplays()
            showOverlay(for: displays)
        } catch {
            NSSound.beep()
        }
    }

    private func showOverlay(for displays: [ManagedDisplay]) {
        clearOverlays()
        NSApp.activate(ignoringOtherApps: true)

        let screensByID: [CGDirectDisplayID: NSScreen] = Dictionary(
            uniqueKeysWithValues: NSScreen.screens.compactMap { screen in
                guard
                    let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
                else {
                    return nil
                }

                return (number.uint32Value, screen)
            }
        )

        let orderedScreens = NSScreen.screens.sorted { lhs, rhs in
            if lhs.frame.minY == rhs.frame.minY {
                return lhs.frame.minX < rhs.frame.minX
            }

            return lhs.frame.minY > rhs.frame.minY
        }

        let orderedDisplays = orderedScreens.compactMap { screen -> ManagedDisplay? in
            guard
                let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
                let display = displays.first(where: { $0.id == number.uint32Value })
            else {
                return nil
            }
            return display
        }

        for (index, display) in orderedDisplays.enumerated() {
            guard let screen = screensByID[display.id] else {
                continue
            }

            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = NSWindow.Level.screenSaver
            window.isOpaque = false
            window.backgroundColor = NSColor.black.withAlphaComponent(0.72)
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.collectionBehavior = [
                NSWindow.CollectionBehavior.canJoinAllSpaces,
                NSWindow.CollectionBehavior.fullScreenAuxiliary,
                NSWindow.CollectionBehavior.stationary
            ]

            let label = NSTextField(labelWithString: "\(index + 1)")
            label.font = .systemFont(ofSize: 140, weight: .bold)
            label.textColor = .white
            label.alignment = .center
            label.backgroundColor = .clear
            label.frame = NSRect(
                x: 0,
                y: screen.frame.midY - 110,
                width: screen.frame.width,
                height: 160
            )

            let subtitle = NSTextField(labelWithString: display.name)
            subtitle.font = .systemFont(ofSize: 28, weight: .semibold)
            subtitle.textColor = .white
            subtitle.alignment = .center
            subtitle.backgroundColor = .clear
            subtitle.frame = NSRect(
                x: 0,
                y: screen.frame.midY - 165,
                width: screen.frame.width,
                height: 40
            )

            let container = NSView(frame: screen.frame)
            container.wantsLayer = true
            container.layer?.backgroundColor = NSColor.clear.cgColor
            container.addSubview(label)
            container.addSubview(subtitle)

            window.contentView = container
            window.orderFrontRegardless()
            overlayWindows.append(window)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.clearOverlays()
        }
    }

    private func clearOverlays() {
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
    }
}
