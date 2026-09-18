import Testing
@testable import InkCore

@Test func toolbarHidesAfterIdleAndRevealsOnFirstEdgeSample() {
    var state = ToolbarVisibility(now: 0)
    state.update(now: 1.9, toolbarHovered: false, topEdgeHovered: false, interacting: false, autoHide: true)
    #expect(state.isVisible)
    state.update(now: 2.1, toolbarHovered: false, topEdgeHovered: false, interacting: false, autoHide: true)
    #expect(!state.isVisible)
    state.update(now: 3, toolbarHovered: false, topEdgeHovered: true, interacting: false, autoHide: true)
    #expect(state.isVisible)
    state.update(now: 3.3, toolbarHovered: false, topEdgeHovered: true, interacting: false, autoHide: true)
    #expect(state.isVisible)
}

@Test func pointerAndDraggingKeepToolbarAvailable() {
    var state = ToolbarVisibility(now: 0)
    state.update(now: 10, toolbarHovered: true, topEdgeHovered: false, interacting: false, autoHide: true)
    #expect(state.isVisible)
    state.update(now: 20, toolbarHovered: false, topEdgeHovered: false, interacting: true, autoHide: true)
    #expect(state.isVisible)
    state.update(now: 21, toolbarHovered: false, topEdgeHovered: false, interacting: false, autoHide: true)
    #expect(state.isVisible)
}

@Test func manualHideRequiresLeavingEdgeBeforeReveal() {
    var state = ToolbarVisibility(now: 0)
    state.hide(topEdgeHovered: true)
    state.update(now: 10, toolbarHovered: false, topEdgeHovered: true, interacting: false, autoHide: false)
    #expect(!state.isVisible)
    state.update(now: 11, toolbarHovered: false, topEdgeHovered: false, interacting: false, autoHide: false)
    state.update(now: 12, toolbarHovered: false, topEdgeHovered: true, interacting: false, autoHide: false)
    state.update(now: 12.3, toolbarHovered: false, topEdgeHovered: true, interacting: false, autoHide: false)
    #expect(state.isVisible)
}

@Test func disablingAutoHideAndExplicitShowResetTheIdleDeadline() {
    var state = ToolbarVisibility(now: 0)
    state.update(now: 100, toolbarHovered: false, topEdgeHovered: false, interacting: false, autoHide: false)
    #expect(state.isVisible)
    state.hide(topEdgeHovered: false)
    state.show(now: 200)
    state.update(now: 201, toolbarHovered: false, topEdgeHovered: false, interacting: false, autoHide: true)
    #expect(state.isVisible)
}
