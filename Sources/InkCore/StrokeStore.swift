import Foundation

public struct InkPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public enum StrokeKind: String, Equatable, Sendable {
    case freehand
    case line
    case arrow
    case rectangle
    case ellipse
    case diamond
    case text
}

public enum InkTextAlignment: String, Equatable, Sendable {
    case left
    case center
    case right
}

public struct Stroke: Equatable, Sendable {
    public var points: [InkPoint]
    public var color: UInt32
    public var width: Double
    public var opacity: Double
    public var createdAt: Double
    public var fadeAfter: Double?
    public var fadeDuration: Double
    public var kind: StrokeKind
    public var text: String?
    public var fontSize: Double
    public var fontStyleID: String
    public var textAlignment: InkTextAlignment
    public init(points: [InkPoint], color: UInt32, width: Double, opacity: Double = 1,
        createdAt: Double = 0, fadeAfter: Double? = nil, fadeDuration: Double = 1,
        kind: StrokeKind = .freehand, text: String? = nil, fontSize: Double = 28,
        fontStyleID: String = "system-rounded", textAlignment: InkTextAlignment = .left) {
        self.points = points
        self.color = color
        self.width = width
        self.opacity = opacity
        self.createdAt = createdAt
        self.fadeAfter = fadeAfter
        self.fadeDuration = fadeDuration
        self.kind = kind
        self.text = text
        self.fontSize = fontSize
        self.fontStyleID = fontStyleID
        self.textAlignment = textAlignment
    }

    public func visibleOpacity(at time: Double) -> Double {
        guard let fadeAfter else { return opacity }
        let progress = max(0, min(1, (time - createdAt - fadeAfter) / fadeDuration))
        return opacity * (1 - progress)
    }

    public func isActivelyFading(at time: Double) -> Bool {
        guard let fadeAfter else { return false }
        let elapsed = time - createdAt
        return elapsed >= fadeAfter && elapsed < fadeAfter + fadeDuration
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

    public mutating func remove(at indices: Set<Int>) {
        let valid = indices.filter { strokes.indices.contains($0) }
        guard !valid.isEmpty else { return }
        checkpoint()
        for index in valid.sorted(by: >) { strokes.remove(at: index) }
    }

    public mutating func replace(at index: Int, with stroke: Stroke) {
        guard strokes.indices.contains(index), !stroke.points.isEmpty else { return }
        checkpoint()
        strokes[index] = stroke
    }

    public mutating func replace(_ replacements: [Int: Stroke]) {
        let valid = replacements.filter { strokes.indices.contains($0.key) && !$0.value.points.isEmpty }
        guard !valid.isEmpty else { return }
        checkpoint()
        for (index, stroke) in valid { strokes[index] = stroke }
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

    /// Removes fully invisible temporary ink from every history snapshot so long sessions do not
    /// retain drawings that can never become visible again. This maintenance operation is not undoable.
    @discardableResult
    public mutating func removeExpiredFadingStrokes(at time: Double) -> Int {
        let originalCount = strokes.count
        strokes.removeAll { $0.fadeAfter != nil && $0.visibleOpacity(at: time) <= 0 }
        undoHistory = undoHistory.map { snapshot in
            snapshot.filter { $0.fadeAfter == nil || $0.visibleOpacity(at: time) > 0 }
        }
        redoHistory = redoHistory.map { snapshot in
            snapshot.filter { $0.fadeAfter == nil || $0.visibleOpacity(at: time) > 0 }
        }
        return originalCount - strokes.count
    }

    private mutating func checkpoint() {
        undoHistory.append(strokes)
        if undoHistory.count > historyLimit { undoHistory.removeFirst() }
        redoHistory.removeAll()
    }
}
