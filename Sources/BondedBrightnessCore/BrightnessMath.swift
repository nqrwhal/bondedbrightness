public enum BrightnessMath {
    public static let meaningfulChangeThreshold = 0.001

    public static func secondaryBrightness(primaryBrightness: Double, offset: Double) -> Double {
        clamp(primaryBrightness + offset)
    }

    public static func secondaryBrightness(
        primaryBrightness: Double,
        primaryOffset: Double,
        secondaryOffset: Double
    ) -> Double {
        clamp(primaryBrightness - primaryOffset + secondaryOffset)
    }

    public static func isMeaningfullyDifferent(
        _ lhs: Double,
        _ rhs: Double,
        threshold: Double = meaningfulChangeThreshold
    ) -> Bool {
        abs(lhs - rhs) >= threshold
    }

    public static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
