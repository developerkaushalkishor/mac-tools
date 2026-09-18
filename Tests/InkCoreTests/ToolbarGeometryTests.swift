import Foundation
import Testing
@testable import InkCore

@Test func revealUsesOnlyToolbarWidthAtExactTopEdge() {
    let frame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let visible = CGRect(x: 0, y: 0, width: 1920, height: 1055)
    for point in [CGPoint(x: 960, y: 1080), CGPoint(x: 960, y: 1076), CGPoint(x: 680, y: 1079)] {
        #expect(ToolbarGeometry.isRevealPoint(point, frame: frame, visibleFrame: visible, toolbarWidth: 560, toolbarHeight: 54))
    }
    #expect(!ToolbarGeometry.isRevealPoint(CGPoint(x: 960, y: 1075), frame: frame, visibleFrame: visible, toolbarWidth: 560, toolbarHeight: 54))
    #expect(!ToolbarGeometry.isRevealPoint(CGPoint(x: 679, y: 1080), frame: frame, visibleFrame: visible, toolbarWidth: 560, toolbarHeight: 54))
    #expect(!ToolbarGeometry.isRevealPoint(CGPoint(x: 20, y: 1080), frame: frame, visibleFrame: visible, toolbarWidth: 560, toolbarHeight: 54))
}

@Test func revealUsesPhysicalCenterWithSideDockAndNegativeOrigin() {
    let frame = CGRect(x: -1600, y: -300, width: 1600, height: 900)
    let visible = CGRect(x: -1520, y: -300, width: 1520, height: 900)
    #expect(ToolbarGeometry.isRevealPoint(CGPoint(x: -800, y: 600), frame: frame, visibleFrame: visible, toolbarWidth: 560, toolbarHeight: 54))
    #expect(!ToolbarGeometry.isRevealPoint(CGPoint(x: -800, y: 601), frame: frame, visibleFrame: visible, toolbarWidth: 560, toolbarHeight: 54))
}

@Test func repeatedRevealAndHideCyclesDoNotRequireDwell() {
    var state = ToolbarVisibility(now: 0)
    for cycle in 1...20 {
        let now = Double(cycle * 10)
        state.update(now: now, toolbarHovered: false, topEdgeHovered: false, interacting: false, autoHide: true)
        #expect(!state.isVisible)
        state.update(now: now + 0.05, toolbarHovered: false, topEdgeHovered: true, interacting: false, autoHide: true)
        #expect(state.isVisible)
        state.update(now: now + 1, toolbarHovered: true, topEdgeHovered: false, interacting: false, autoHide: true)
        #expect(state.isVisible)
    }
}
