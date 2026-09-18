import Foundation

public struct InkPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public struct Stroke: Equatable, Sendable {
    public var points: [InkPoint]
    public var color: UInt32
    public var width: Double
    public init(points: [InkPoint], color: UInt32, width: Double) {
        self.points = points
        self.color = color
        self.width = width
    }
}

/// Stores completed drawing operations. A new operation invalidates redo history.
public struct StrokeStore {
    public private(set) var strokes: [Stroke] = []
    private var undoHistory: [[Stroke]] = []
    private var redoHistory: [[Stroke]] = []
    private let historyLimit = 100

    public init() {}

    public mutating func append(_ stroke: Stroke) {
        guard !stroke.points.isEmpty else { return }
        checkpoint()
        strokes.append(stroke)
    }

    public mutating func clear() {
        guard !strokes.isEmpty else { return }
        checkpoint()
        strokes.removeAll()
    }

    public mutating func undo() {
        guard let previous = undoHistory.popLast() else { return }
        redoHistory.append(strokes)
        strokes = previous
    }

    public mutating func redo() {
        guard let next = redoHistory.popLast() else { return }
        undoHistory.append(strokes)
        strokes = next
    }

    private mutating func checkpoint() {
        undoHistory.append(strokes)
        if undoHistory.count > historyLimit { undoHistory.removeFirst() }
        redoHistory.removeAll()
    }
}
