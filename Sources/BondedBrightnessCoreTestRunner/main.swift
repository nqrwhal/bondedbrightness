import BondedBrightnessCore
import Foundation

@discardableResult
func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if condition() {
        return true
    }

    fputs("FAIL: \(message)\n", stderr)
    exit(1)
}

func expectClose(_ actual: Double, _ expected: Double, _ message: String) {
    expect(abs(actual - expected) < 0.0001, "\(message): expected \(expected), got \(actual)")
}

let upperClamp = BrightnessMath.secondaryBrightness(primaryBrightness: 0.92, offset: 0.2)
expectClose(upperClamp, 1.0, "secondary brightness clamps upper bound")

let lowerClamp = BrightnessMath.secondaryBrightness(primaryBrightness: 0.05, offset: -0.2)
expectClose(lowerClamp, 0.0, "secondary brightness clamps lower bound")

let perDisplayOffset = BrightnessMath.secondaryBrightness(
    primaryBrightness: 0.55,
    primaryOffset: 0.10,
    secondaryOffset: -0.05
)
expectClose(perDisplayOffset, 0.40, "secondary brightness applies per-display offsets")

let displays = [
    DisplaySnapshot(id: 11, isMain: false),
    DisplaySnapshot(id: 42, isMain: true),
    DisplaySnapshot(id: 99, isMain: false)
]
expect(DisplaySelection.secondaryDisplay(from: displays)?.id == 11, "secondary display skips main display")

expect(!BrightnessMath.isMeaningfullyDifferent(0.500, 0.5005), "brightness tolerance ignores tiny changes")
expect(BrightnessMath.isMeaningfullyDifferent(0.500, 0.502), "brightness tolerance detects meaningful changes")

print("BondedBrightnessCoreTestRunner passed")
