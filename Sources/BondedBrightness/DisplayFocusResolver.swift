import AppKit
import CoreGraphics
import Foundation

@MainActor
final class DisplayFocusResolver {
    func focusedDisplay(in displays: [ManagedDisplay]) -> ManagedDisplay? {
        guard let displayID = focusedDisplayID() else {
            return nil
        }

        return displays.first { $0.id == displayID }
    }

    private func focusedDisplayID() -> CGDirectDisplayID? {
        if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
           let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            for window in windows where windowOwnerPID(window) == pid {
                if let bounds = windowBounds(window),
                   let display = displayContaining(point: CGPoint(x: bounds.midX, y: bounds.midY)) {
                    return display
                }
            }
        }

        let mouseLocation = NSEvent.mouseLocation
        return displayContaining(point: mouseLocation)
    }

    private func displayContaining(point: CGPoint) -> CGDirectDisplayID? {
        for screen in NSScreen.screens {
            let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            guard let displayID = number?.uint32Value else {
                continue
            }

            if CGDisplayBounds(displayID).contains(point) {
                return displayID
            }
        }

        return nil
    }

    private func windowOwnerPID(_ window: [String: Any]) -> pid_t? {
        (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value
    }

    private func windowBounds(_ window: [String: Any]) -> CGRect? {
        (window[kCGWindowBounds as String] as? NSDictionary).flatMap { dict in
            CGRect(dictionaryRepresentation: dict)
        }
    }
}
