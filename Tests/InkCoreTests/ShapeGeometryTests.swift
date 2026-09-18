import Foundation
import Testing
@testable import InkCore

@Test func shiftConstrainsShapesAndLines() {
    let start = InkPoint(x: 10, y: 10)
    let square = ShapeGeometry.constrainedEnd(start: start,
        proposed: InkPoint(x: 70, y: 40), kind: .rectangle, shiftPressed: true)
    #expect(square == InkPoint(x: 70, y: 70))

    let circle = ShapeGeometry.constrainedEnd(start: start,
        proposed: InkPoint(x: -20, y: 55), kind: .ellipse, shiftPressed: true)
    #expect(circle == InkPoint(x: -35, y: 55))

    let line = ShapeGeometry.constrainedEnd(start: InkPoint(x: 0, y: 0),
        proposed: InkPoint(x: 70, y: 40), kind: .line, shiftPressed: true)
    #expect(abs(abs(line.x) - abs(line.y)) < 0.0001)
}

@Test func shapeOutlinesParticipateInEraserHitTesting() {
    let rectangle = Stroke(points: [InkPoint(x: 0, y: 0), InkPoint(x: 100, y: 60)],
        color: 0, width: 4, kind: .rectangle)
    #expect(StrokeHitTesting.hits(rectangle, point: InkPoint(x: 50, y: 2), tolerance: 2))
    #expect(!StrokeHitTesting.hits(rectangle, point: InkPoint(x: 50, y: 30), tolerance: 2))

    let ellipse = Stroke(points: [InkPoint(x: 0, y: 0), InkPoint(x: 100, y: 60)],
        color: 0, width: 4, kind: .ellipse)
    #expect(StrokeHitTesting.hits(ellipse, point: InkPoint(x: 50, y: 1), tolerance: 2))
    #expect(!StrokeHitTesting.hits(ellipse, point: InkPoint(x: 50, y: 30), tolerance: 2))

    let arrow = Stroke(points: [InkPoint(x: 0, y: 0), InkPoint(x: 100, y: 0)],
        color: 0, width: 4, kind: .arrow)
    #expect(StrokeHitTesting.hits(arrow, point: InkPoint(x: 88, y: 6), tolerance: 2))
}

@Test func ellipseUsesAClosedHighResolutionPenCurve() {
    let points = ShapeGeometry.handDrawnEllipsePoints(
        start: InkPoint(x: 0, y: 0), end: InkPoint(x: 200, y: 100))
    #expect(points.count == 97)
    #expect(abs(points.first!.x - points.last!.x) < 0.0001)
    #expect(abs(points.first!.y - points.last!.y) < 0.0001)
    #expect(points.allSatisfy { $0.x >= -1 && $0.x <= 201 && $0.y >= -1 && $0.y <= 101 })
}

@Test func roundedRectangleAndDiamondStayClosedAndInsideTheirBounds() {
    let start = InkPoint(x: 10, y: 20)
    let end = InkPoint(x: 210, y: 140)
    for points in [ShapeGeometry.handDrawnRoundedRectanglePoints(start: start, end: end),
        ShapeGeometry.handDrawnDiamondPoints(start: start, end: end)] {
        #expect(points.count > 24)
        #expect(points.first == points.last)
        #expect(points.allSatisfy { $0.x >= 9 && $0.x <= 211 && $0.y >= 19 && $0.y <= 141 })
    }
}

@Test func recognizesClosedPenEllipseRectangleAndDiamond() {
    let ellipse = sampledPoints(count: 48) { angle in
        InkPoint(x: 100 + cos(angle) * 70, y: 80 + sin(angle) * 45)
    }
    #expect(ShapeRecognizer.recognize(points: ellipse)?.kind == .ellipse)

    let rectangle = sampledPolyline([
        InkPoint(x: 10, y: 10), InkPoint(x: 150, y: 10),
        InkPoint(x: 150, y: 100), InkPoint(x: 10, y: 100), InkPoint(x: 10, y: 10)
    ])
    #expect(ShapeRecognizer.recognize(points: rectangle)?.kind == .rectangle)

    let diamond = sampledPolyline([
        InkPoint(x: 100, y: 10), InkPoint(x: 190, y: 80),
        InkPoint(x: 100, y: 150), InkPoint(x: 10, y: 80), InkPoint(x: 100, y: 10)
    ])
    #expect(ShapeRecognizer.recognize(points: diamond)?.kind == .diamond)
}

@Test func doesNotConvertOpenOrAmbiguousPenStrokes() {
    let openStroke = (0..<30).map { InkPoint(x: Double($0) * 4, y: 40 + sin(Double($0) / 3) * 8) }
    #expect(ShapeRecognizer.recognize(points: openStroke) == nil)
}

private func sampledPoints(count: Int, point: (Double) -> InkPoint) -> [InkPoint] {
    (0...count).map { point(Double($0) / Double(count) * 2 * Double.pi) }
}

private func sampledPolyline(_ vertices: [InkPoint], samplesPerEdge: Int = 12) -> [InkPoint] {
    zip(vertices, vertices.dropFirst()).flatMap { start, end in
        (0..<samplesPerEdge).map { step in
            let t = Double(step) / Double(samplesPerEdge)
            return InkPoint(x: start.x + (end.x - start.x) * t,
                y: start.y + (end.y - start.y) * t)
        }
    } + [vertices.last!]
}
