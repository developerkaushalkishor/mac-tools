import AppKit
import Testing
@testable import ScreenInk

@Suite(.serialized)
@MainActor
struct DisplayCanvasTests {
    @Test func canvasFitsEveryConnectedScreenAndReleasesInput() throws {
        _ = NSApplication.shared
        let screens = NSScreen.screens
        try #require(!screens.isEmpty, "A logged-in macOS desktop is required for AppKit tests")
        print("AppKit display coverage: \(screens.count) connected screen(s)")
        let displays = screens.map { DisplayCanvas(screen: $0) }
        defer { displays.forEach { $0.window.close() } }
        for (screen, display) in zip(screens, displays) {
            #expect(display.window.frame == screen.frame)
            #expect(display.canvas.bounds.origin == .zero)
            #expect(display.canvas.bounds.size == screen.frame.size)
            #expect(display.window.ignoresMouseEvents)
            display.setDrawing(true)
            #expect(!display.window.ignoresMouseEvents)
            display.setDrawing(false)
            #expect(display.window.ignoresMouseEvents)
        }
        #expect(Set(screens.map(\.inkDisplayID)).count == screens.count)
    }

    @Test func strokesUseLocalCoordinatesOnAnOffsetDisplay() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        // Simulate a display left of and below the primary without changing system settings.
        display.window.setFrame(NSRect(x: -1600, y: -300, width: 1600, height: 900), display: false)
        let point = NSPoint(x: 40, y: 60)
        let down = try #require(NSEvent.mouseEvent(with: .leftMouseDown, location: point,
            modifierFlags: [], timestamp: 0, windowNumber: display.window.windowNumber,
            context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        let up = try #require(NSEvent.mouseEvent(with: .leftMouseUp, location: point,
            modifierFlags: [], timestamp: 1, windowNumber: display.window.windowNumber,
            context: nil, eventNumber: 1, clickCount: 1, pressure: 0))
        display.canvas.mouseDown(with: down)
        display.canvas.mouseUp(with: up)
        let stroke = try #require(display.canvas.store.strokes.first)
        #expect(stroke.points.first?.x == 40)
        #expect(stroke.points.first?.y == 60)
    }
    @Test func rightClickExitsAllCanvasesAndKeepsInk() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let displays = NSScreen.screens.map { DisplayCanvas(screen: $0) }
        defer { displays.forEach { $0.window.close() } }
        let active = try #require(displays.first)
        var exits = 0
        active.canvas.onEscape = {
            exits += 1
            displays.forEach { $0.setDrawing(false) }
        }
        displays.forEach { $0.setDrawing(true) }
        let down = try #require(NSEvent.mouseEvent(with: .leftMouseDown, location: NSPoint(x: 20, y: 30),
            modifierFlags: [], timestamp: 0, windowNumber: active.window.windowNumber,
            context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        active.canvas.mouseDown(with: down)
        let right = try #require(NSEvent.mouseEvent(with: .rightMouseDown, location: NSPoint(x: 20, y: 30),
            modifierFlags: [], timestamp: 1, windowNumber: active.window.windowNumber,
            context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
        active.canvas.rightMouseDown(with: right)
        #expect(exits == 1)
        #expect(displays.allSatisfy { $0.window.ignoresMouseEvents })
        #expect(active.canvas.store.strokes.count == 1)
        #expect(active.window.frame == screen.frame)
        active.canvas.store.undo()
        #expect(active.canvas.store.strokes.isEmpty)
    }

    @Test func highlighterAndWholeStrokeEraserWorkWithUndo() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        let point = NSPoint(x: 80, y: 90)
        func event(_ type: NSEvent.EventType, _ timestamp: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
                timestamp: timestamp, windowNumber: display.window.windowNumber,
                context: nil, eventNumber: Int(timestamp), clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1))
        }

        display.canvas.color = 0xFFD60A
        display.canvas.penWidth = 4
        display.canvas.tool = .highlighter
        display.canvas.mouseDown(with: try event(.leftMouseDown, 0))
        display.canvas.mouseUp(with: try event(.leftMouseUp, 1))
        let highlight = try #require(display.canvas.store.strokes.first)
        #expect(highlight.opacity == 0.28)
        #expect(highlight.width == 16)

        display.canvas.tool = .eraser
        display.canvas.mouseDown(with: try event(.leftMouseDown, 2))
        display.canvas.mouseUp(with: try event(.leftMouseUp, 3))
        #expect(display.canvas.store.strokes.isEmpty)
        display.canvas.store.undo()
        #expect(display.canvas.store.strokes == [highlight])
    }

    @Test func laserPointerCreatesOnlyTemporaryTrail() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        func event(_ type: NSEvent.EventType, x: CGFloat, time: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: 100),
                modifierFlags: [], timestamp: time, windowNumber: display.window.windowNumber,
                context: nil, eventNumber: Int(time), clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1))
        }
        display.canvas.tool = .laser
        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 20, time: 0))
        #expect(display.canvas.showsLaserHead)
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 80, time: 1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 120, time: 2))
        #expect(!display.canvas.showsLaserHead)
        #expect(display.canvas.store.strokes.isEmpty)
        #expect(display.canvas.activeLaserSegmentCount == 3)
        display.canvas.refreshFading(at: ProcessInfo.processInfo.systemUptime + 1)
        #expect(display.canvas.activeLaserSegmentCount == 0)
    }

    @Test func textCanBePlacedEditedAndUndone() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        display.canvas.tool = .text
        display.canvas.color = 0xBF5AF2
        display.canvas.fontSize = 28

        func click(x: CGFloat, y: CGFloat, time: TimeInterval) throws {
            let event = try #require(NSEvent.mouseEvent(with: .leftMouseDown,
                location: NSPoint(x: x, y: y), modifierFlags: [], timestamp: time,
                windowNumber: display.window.windowNumber, context: nil,
                eventNumber: Int(time), clickCount: 1, pressure: 1))
            display.canvas.mouseDown(with: event)
        }

        try click(x: 70, y: 90, time: 1)
        let newField = try #require(display.canvas.subviews.compactMap { $0 as? NSTextField }.first)
        newField.stringValue = "Hello"
        _ = newField.sendAction(newField.action, to: newField.target)
        #expect(display.canvas.store.strokes.count == 1)
        #expect(display.canvas.store.strokes[0].text == "Hello")

        try click(x: 80, y: 100, time: 2)
        let editField = try #require(display.canvas.subviews.compactMap { $0 as? NSTextField }.first)
        #expect(editField.stringValue == "Hello")
        editField.stringValue = "Hello ScreenInk"
        _ = editField.sendAction(editField.action, to: editField.target)
        #expect(display.canvas.store.strokes.count == 1)
        #expect(display.canvas.store.strokes[0].text == "Hello ScreenInk")
        display.canvas.store.undo()
        #expect(display.canvas.store.strokes[0].text == "Hello")
    }

}
