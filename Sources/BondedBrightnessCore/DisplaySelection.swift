public struct DisplaySnapshot: Equatable, Identifiable, Sendable {
    public let id: UInt32
    public let isMain: Bool

    public init(id: UInt32, isMain: Bool) {
        self.id = id
        self.isMain = isMain
    }
}

public enum DisplaySelection {
    public static func primaryDisplay(from displays: [DisplaySnapshot]) -> DisplaySnapshot? {
        displays.first(where: \.isMain) ?? displays.first
    }

    public static func secondaryDisplay(from displays: [DisplaySnapshot]) -> DisplaySnapshot? {
        displays.first { !$0.isMain }
    }
}
