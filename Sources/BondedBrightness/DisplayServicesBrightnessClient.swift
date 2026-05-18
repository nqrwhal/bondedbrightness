import AppKit
import CoreGraphics
import Darwin
import Foundation

@MainActor
final class DisplayServicesBrightnessClient: DisplayBrightnessClient {
    private let api: Result<DisplayServicesAPI, DisplayBrightnessError>

    init() {
        self.api = Result {
            try DisplayServicesAPI.load()
        }.mapError { error in
            if let displayError = error as? DisplayBrightnessError {
                return displayError
            }

            return .displayServicesUnavailable(error.localizedDescription)
        }
    }

    func onlineDisplays() throws -> [ManagedDisplay] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0
        let error = CGGetOnlineDisplayList(UInt32(displayIDs.count), &displayIDs, &displayCount)

        guard error == .success else {
            throw DisplayBrightnessError.displayListUnavailable(error)
        }

        return displayIDs.prefix(Int(displayCount)).map { displayID in
            ManagedDisplay(
                id: displayID,
                name: screenName(for: displayID),
                isMain: displayID == CGMainDisplayID(),
                identity: DisplayIdentity(
                    vendorID: CGDisplayVendorNumber(displayID),
                    productID: CGDisplayModelNumber(displayID),
                    serialNumber: CGDisplaySerialNumber(displayID)
                )
            )
        }
    }

    func brightness(for display: ManagedDisplay) throws -> Double {
        var brightness = Float(0)
        let result = try api.get().getBrightness(display.id, &brightness)

        guard result == 0 else {
            throw DisplayBrightnessError.brightnessReadFailed(display.name, result)
        }

        return Double(brightness)
    }

    func setBrightness(_ brightness: Double, for display: ManagedDisplay) throws {
        let result = try api.get().setBrightness(display.id, Float(brightness))

        guard result == 0 else {
            throw DisplayBrightnessError.brightnessWriteFailed(display.name, result)
        }
    }

    private func screenName(for displayID: CGDirectDisplayID) -> String {
        for screen in NSScreen.screens {
            let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            if number?.uint32Value == displayID {
                return screen.localizedName
            }
        }

        return displayID == CGMainDisplayID() ? "Main Display" : "Display \(displayID)"
    }
}

private struct DisplayServicesAPI {
    typealias GetBrightness = @convention(c) (
        CGDirectDisplayID,
        UnsafeMutablePointer<Float>
    ) -> Int32
    typealias SetBrightness = @convention(c) (CGDirectDisplayID, Float) -> Int32

    let getBrightness: GetBrightness
    let setBrightness: SetBrightness

    static func load() throws -> DisplayServicesAPI {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        guard let handle = dlopen(path, RTLD_LAZY) else {
            throw DisplayBrightnessError.displayServicesUnavailable(String(cString: dlerror()))
        }

        guard let getSymbol = dlsym(handle, "DisplayServicesGetBrightness") else {
            throw DisplayBrightnessError.displayServicesUnavailable("missing DisplayServicesGetBrightness")
        }

        guard let setSymbol = dlsym(handle, "DisplayServicesSetBrightness") else {
            throw DisplayBrightnessError.displayServicesUnavailable("missing DisplayServicesSetBrightness")
        }

        return DisplayServicesAPI(
            getBrightness: unsafeBitCast(getSymbol, to: GetBrightness.self),
            setBrightness: unsafeBitCast(setSymbol, to: SetBrightness.self)
        )
    }
}
