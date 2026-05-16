import CoreGraphics
import Darwin
import Foundation

@MainActor
final class DisplayServicesBrightnessNotifier {
    private typealias Callback = @convention(c) (CGDirectDisplayID, UnsafeMutableRawPointer?) -> Void
    private typealias Register = @convention(c) (Callback, UnsafeMutableRawPointer?) -> Int32
    private typealias Unregister = @convention(c) (Callback, UnsafeMutableRawPointer?) -> Int32

    private let register: Register
    private let unregister: Unregister
    private var isRegistered = false

    var onBrightnessChange: ((CGDirectDisplayID) -> Void)?

    init() throws {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        guard let handle = dlopen(path, RTLD_LAZY) else {
            throw DisplayBrightnessError.displayServicesUnavailable(String(cString: dlerror()))
        }

        guard let registerSymbol = dlsym(handle, "DisplayServicesRegisterForBrightnessChangeNotifications") else {
            throw DisplayBrightnessError.displayServicesUnavailable("missing DisplayServicesRegisterForBrightnessChangeNotifications")
        }

        guard let unregisterSymbol = dlsym(handle, "DisplayServicesUnregisterForBrightnessChangeNotifications") else {
            throw DisplayBrightnessError.displayServicesUnavailable("missing DisplayServicesUnregisterForBrightnessChangeNotifications")
        }

        self.register = unsafeBitCast(registerSymbol, to: Register.self)
        self.unregister = unsafeBitCast(unregisterSymbol, to: Unregister.self)
    }

    func start() throws {
        guard !isRegistered else {
            return
        }

        let result = register(Self.callback, Unmanaged.passUnretained(self).toOpaque())
        guard result == 0 else {
            throw DisplayBrightnessError.displayServicesUnavailable("register returned \(result)")
        }

        isRegistered = true
    }

    func stop() {
        guard isRegistered else {
            return
        }

        _ = unregister(Self.callback, Unmanaged.passUnretained(self).toOpaque())
        isRegistered = false
    }

    private static let callback: Callback = { displayID, context in
        guard let context else {
            return
        }

        let notifier = Unmanaged<DisplayServicesBrightnessNotifier>
            .fromOpaque(context)
            .takeUnretainedValue()

        notifier.onBrightnessChange?(displayID)
    }
}
