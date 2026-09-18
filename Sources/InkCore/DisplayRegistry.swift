/// Retains each display's session state across reorder and temporary disconnection.
public struct DisplayRegistry<Value> {
    public private(set) var activeIDs: [String] = []
    private var values: [String: Value] = [:]
    public init() {}
    public var activeValues: [Value] { activeIDs.compactMap { values[$0] } }
    public subscript(id: String) -> Value? { values[id] }
    @discardableResult
    public mutating func reconcile(ids: [String], create: (String) -> Value) -> [Value] {
        var seen = Set<String>()
        let unique = ids.filter { seen.insert($0).inserted }
        let detached = activeIDs.filter { !seen.contains($0) }.compactMap { values[$0] }
        for id in unique where values[id] == nil { values[id] = create(id) }
        activeIDs = unique
        return detached
    }
}
