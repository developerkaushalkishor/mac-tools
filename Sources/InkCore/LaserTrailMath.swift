import Foundation

public enum LaserTrailMath {
    public static func strength(age: Double, pointsFromHead: Double,
        lifetime: Double = 1, maximumPointCount: Double = 50) -> Double {
        let timeFactor = max(0, min(1, 1 - age / lifetime))
        let lengthFactor = max(0, min(1, 1 - pointsFromHead / maximumPointCount))
        let value = min(timeFactor, lengthFactor)
        return 1 - pow(1 - value, 3)
    }
}
