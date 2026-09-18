import AppKit

struct TextFontStyle: Equatable {
    let id: String
    let displayName: String
    let category: String
    let postScriptNames: [String]
    let usesSystemRoundedDesign: Bool

    func font(size: CGFloat) -> NSFont {
        if usesSystemRoundedDesign {
            let base = NSFont.systemFont(ofSize: size, weight: .medium)
            if let descriptor = base.fontDescriptor.withDesign(.rounded) {
                return NSFont(descriptor: descriptor, size: size) ?? base
            }
            return base
        }
        for name in postScriptNames {
            if let font = NSFont(name: name, size: size) { return font }
        }
        return NSFont.systemFont(ofSize: size, weight: .medium)
    }
}

@MainActor
enum TextFontCatalog {
    static let defaultID = "system-rounded"
    static let styles: [TextFontStyle] = [
        TextFontStyle(id: defaultID, displayName: "System Rounded", category: "Clear",
            postScriptNames: [], usesSystemRoundedDesign: true),
        TextFontStyle(id: "avenir-next", displayName: "Avenir Next", category: "Clear",
            postScriptNames: ["AvenirNext-Medium", "Avenir Next Medium"],
            usesSystemRoundedDesign: false),
        TextFontStyle(id: "helvetica-neue", displayName: "Helvetica Neue", category: "Clear",
            postScriptNames: ["HelveticaNeue-Medium", "Helvetica Neue Medium"],
            usesSystemRoundedDesign: false),
        TextFontStyle(id: "chalkboard", displayName: "Chalkboard", category: "Handwriting",
            postScriptNames: ["ChalkboardSE-Regular", "Chalkboard"],
            usesSystemRoundedDesign: false),
        TextFontStyle(id: "noteworthy", displayName: "Noteworthy", category: "Handwriting",
            postScriptNames: ["Noteworthy-Light", "Noteworthy"],
            usesSystemRoundedDesign: false),
        TextFontStyle(id: "marker-felt", displayName: "Marker Felt", category: "Handwriting",
            postScriptNames: ["MarkerFelt-Thin", "Marker Felt"],
            usesSystemRoundedDesign: false)
    ]

    static func style(id: String) -> TextFontStyle {
        styles.first(where: { $0.id == id }) ?? styles[0]
    }

    static func font(id: String, size: Double) -> NSFont {
        style(id: id).font(size: CGFloat(size))
    }
}
