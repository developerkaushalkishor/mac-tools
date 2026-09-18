import Foundation
import Testing
@testable import InkCore

@Test func closedShapeResizeUsesTheOppositeCornerAsAnchor() {
    let rectangle = Stroke(points: [InkPoint(x: 10, y: 20), InkPoint(x: 110, y: 80)],
        color: 0, width: 4, kind: .rectangle)
    let resized = AnnotationGeometry.resized(rectangle, handle: 2,
        to: InkPoint(x: 170, y: 130))
    let bounds = AnnotationGeometry.bounds(of: resized)
    #expect(bounds == InkBounds(minX: 10, minY: 20, maxX: 170, maxY: 130))
}

@Test func lineEndpointsAndWholeAnnotationsCanBeTransformed() {
    let line = Stroke(points: [InkPoint(x: 5, y: 10), InkPoint(x: 90, y: 60)],
        color: 0, width: 4, kind: .line)
    let endpointResize = AnnotationGeometry.resized(line, handle: 1,
        to: InkPoint(x: 140, y: 100))
    #expect(endpointResize.points.last == InkPoint(x: 140, y: 100))
    let moved = AnnotationGeometry.moved(endpointResize, dx: 12, dy: -8)
    #expect(moved.points.first == InkPoint(x: 17, y: 2))
    #expect(moved.points.last == InkPoint(x: 152, y: 92))
}

@Test func textResizeChangesFontSizeWithinSafeLimits() {
    let text = Stroke(points: [InkPoint(x: 20, y: 30)], color: 0, width: 1,
        kind: .text, text: "ScreenInk", fontSize: 28)
    let bounds = AnnotationGeometry.bounds(of: text)!
    let larger = AnnotationGeometry.resized(text, handle: 0,
        to: InkPoint(x: bounds.minX + bounds.width * 2, y: bounds.minY + bounds.height * 2))
    #expect(abs(larger.fontSize - 56) < 0.001)
    let tiny = AnnotationGeometry.resized(text, handle: 0,
        to: InkPoint(x: bounds.minX, y: bounds.minY))
    #expect(tiny.fontSize == 12)
}

@Test func freehandResizePreservesEveryPointAndStrokeAppearance() {
    let freehand = Stroke(points: [InkPoint(x: 10, y: 10), InkPoint(x: 60, y: 60),
        InkPoint(x: 110, y: 10)], color: 0xFFD60A, width: 16, opacity: 0.28)
    let resized = AnnotationGeometry.resized(freehand, handle: 2,
        to: InkPoint(x: 210, y: 110))
    #expect(resized.points == [InkPoint(x: 10, y: 10), InkPoint(x: 110, y: 110),
        InkPoint(x: 210, y: 10)])
    #expect(resized.opacity == 0.28)
    #expect(resized.color == freehand.color)
    #expect(resized.width > freehand.width)
}

@Test func textBoundsRespectLeftCenterAndRightAnchors() {
    let point = InkPoint(x: 200, y: 80)
    let left = Stroke(points: [point], color: 0, width: 1,
        kind: .text, text: "Teach", fontSize: 20, textAlignment: .left)
    var center = left
    center.textAlignment = .center
    var right = left
    right.textAlignment = .right
    let leftBounds = AnnotationGeometry.bounds(of: left)!
    let centerBounds = AnnotationGeometry.bounds(of: center)!
    let rightBounds = AnnotationGeometry.bounds(of: right)!
    #expect(leftBounds.minX == 200)
    #expect((centerBounds.minX + centerBounds.maxX) / 2 == 200)
    #expect(rightBounds.maxX == 200)
}
