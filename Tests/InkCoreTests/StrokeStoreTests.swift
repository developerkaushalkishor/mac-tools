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
