import Testing
@testable import InkCore

private func stroke(_ x: Double) -> Stroke {
    Stroke(points: [InkPoint(x: x, y: 10)], color: 0xFF453A, width: 4)
}

@Test func clearCanBeUndoneAndRedone() {
    var store = StrokeStore()
    store.append(stroke(1))
    store.append(stroke(2))
    store.clear()
    #expect(store.strokes.isEmpty)
    store.undo()
    #expect(store.strokes == [stroke(1), stroke(2)])
    store.redo()
    #expect(store.strokes.isEmpty)
}

@Test func drawingAfterUndoDiscardsRedo() {
    var store = StrokeStore()
    store.append(stroke(1))
    store.undo()
    store.append(stroke(2))
    store.redo()
    #expect(store.strokes == [stroke(2)])
}

@Test func emptyOperationsPreserveRedo() {
    var store = StrokeStore()
    store.append(stroke(1))
    store.undo()
    store.clear()
    store.append(Stroke(points: [], color: 0, width: 1))
    store.redo()
    #expect(store.strokes == [stroke(1)])
}

@Test func erasingSeveralStrokesIsOneUndoableOperation() {
    var store = StrokeStore()
    store.append(stroke(1))
    store.append(stroke(2))
    store.append(stroke(3))
    store.remove(at: [0, 2])
    #expect(store.strokes == [stroke(2)])
    store.undo()
    #expect(store.strokes == [stroke(1), stroke(2), stroke(3)])
    store.redo()
    #expect(store.strokes == [stroke(2)])
}

@Test func strokeHitTestingUsesSegmentsAndWidth() {
    let line = Stroke(points: [InkPoint(x: 0, y: 0), InkPoint(x: 100, y: 0)],
        color: 0, width: 10, opacity: 0.28)
    #expect(StrokeHitTesting.hits(line, point: InkPoint(x: 50, y: 8), tolerance: 3))
    #expect(!StrokeHitTesting.hits(line, point: InkPoint(x: 50, y: 9), tolerance: 3))
    #expect(line.opacity == 0.28)
}

@Test func fadingInkUsesElapsedTimeAndPermanentInkStaysVisible() {
    let fading = Stroke(points: [InkPoint(x: 0, y: 0)], color: 0, width: 4,
        opacity: 0.8, createdAt: 100, fadeAfter: 5)
    #expect(fading.visibleOpacity(at: 104) == 0.8)
    #expect(fading.visibleOpacity(at: 105.5) == 0.4)
    #expect(fading.visibleOpacity(at: 106) == 0)
    #expect(fading.isActivelyFading(at: 105.5))
    #expect(!fading.isActivelyFading(at: 106))

    let permanent = Stroke(points: [InkPoint(x: 0, y: 0)], color: 0, width: 4, opacity: 0.28)
    #expect(permanent.visibleOpacity(at: 10_000) == 0.28)
}
