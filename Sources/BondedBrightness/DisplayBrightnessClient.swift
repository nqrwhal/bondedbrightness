import CoreGraphics
import Foundation

struct DisplayIdentity: Equatable, Sendable {
    let vendorID: UInt32
    let productID: UInt32
    let serialNumber: UInt32
}

@MainActor
struct ManagedDisplay: Identifiable, Equatable {
    let id: CGDirectDisplayID
    let name: String
    let isMain: Bool
    let identity: DisplayIdentity
}

@MainActor
protocol DisplayBrightnessClient {
    func onlineDisplays() throws -> [ManagedDisplay]
    func brightness(for display: ManagedDisplay) throws -> Double
    func setBrightness(_ brightness: Double, for display: ManagedDisplay) throws
}

enum DisplayBrightnessError: LocalizedError {
    case displayListUnavailable(CGError)
    case displayServicesUnavailable(String)
    case brightnessReadFailed(String, Int32)
    case brightnessWriteFailed(String, Int32)

    var errorDescription: String? {
        switch self {
        case .displayListUnavailable(let error):
            return "Unable to read display list: \(error)"
        case .displayServicesUnavailable(let message):
            return "DisplayServices is unavailable: \(message)"
        case .brightnessReadFailed(let name, let code):
            return "Unable to read brightness for \(name): \(code)"
        case .brightnessWriteFailed(let name, let code):
            return "Unable to set brightness for \(name): \(code)"
        }
    }
}
