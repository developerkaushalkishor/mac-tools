import Testing
@testable import InkCore

@Test func laserTrailFadesProgressivelyFromTailToHead() {
    let oldTail = LaserTrailMath.strength(age: 0.8, pointsFromHead: 45)
    let middle = LaserTrailMath.strength(age: 0.4, pointsFromHead: 25)
    let freshHead = LaserTrailMath.strength(age: 0.05, pointsFromHead: 2)
    #expect(oldTail < middle)
    #expect(middle < freshHead)
    #expect(LaserTrailMath.strength(age: 1, pointsFromHead: 0) == 0)
    #expect(LaserTrailMath.strength(age: 0, pointsFromHead: 50) == 0)
}
