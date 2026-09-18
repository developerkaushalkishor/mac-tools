import Testing
@testable import InkCore

private final class DisplaySession {
    var strokes = StrokeStore()
}

@Test func everyDisplayGetsIndependentHistoryAndSurvivesReorder() {
    var registry = DisplayRegistry<DisplaySession>()
    registry.reconcile(ids: ["left", "main", "upper"]) { _ in DisplaySession() }
    let left = registry["left"]!
    left.strokes.append(Stroke(points: [InkPoint(x: 12, y: 14)], color: 0, width: 2))
    #expect(registry.activeValues.count == 3)
    #expect(registry["main"]!.strokes.strokes.isEmpty)
    registry.reconcile(ids: ["upper", "left", "main"]) { _ in DisplaySession() }
    #expect(registry["left"] === left)
    #expect(registry["left"]!.strokes.strokes.count == 1)
    registry["main"]!.strokes.clear()
    #expect(left.strokes.strokes.count == 1)
}

@Test func detachRetainsInkAndReconnectReusesItsSession() {
    var registry = DisplayRegistry<DisplaySession>()
    registry.reconcile(ids: ["a", "b"]) { _ in DisplaySession() }
    let external = registry["b"]!
    external.strokes.append(Stroke(points: [InkPoint(x: 1, y: 2)], color: 0, width: 4))
    let removed = registry.reconcile(ids: ["a"]) { _ in DisplaySession() }
    #expect(removed.count == 1)
    #expect(removed.first === external)
    registry.reconcile(ids: ["a", "b", "c"]) { _ in DisplaySession() }
    #expect(registry["b"] === external)
    #expect(external.strokes.strokes.count == 1)
    #expect(registry.activeValues.count == 3)
}

@Test func noDisplaysAndDuplicateIDsAreHandled() {
    var registry = DisplayRegistry<DisplaySession>()
    registry.reconcile(ids: ["a", "a"]) { _ in DisplaySession() }
    #expect(registry.activeValues.count == 1)
    #expect(registry.reconcile(ids: []) { _ in DisplaySession() }.count == 1)
    #expect(registry.activeValues.isEmpty)
}
