import AppKit
import InkCore
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

    @Test func clickAnimationExpiresWithoutChangingDrawingHistory() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }

        display.canvas.showClickAnimation(at: InkPoint(x: 80, y: 90), time: 100)
        #expect(display.canvas.activeClickRippleCount == 1)
        #expect(display.canvas.store.strokes.isEmpty)
        display.canvas.refreshFading(at: 100.49)
        #expect(display.canvas.activeClickRippleCount == 1)
        display.canvas.refreshFading(at: 100.5)
        #expect(display.canvas.activeClickRippleCount == 0)
        #expect(display.canvas.store.strokes.isEmpty)
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
        #expect(newField.frame.minX == 70)
        #expect(newField.frame.minY == 90)
        #expect(newField.placeholderAttributedString?.string == "Type here…")
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

    @Test func selectToolResizesAShapeAndCreatesOneUndoStep() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        let original = Stroke(points: [InkPoint(x: 10, y: 20), InkPoint(x: 110, y: 80)],
            color: 0xBF5AF2, width: 4, kind: .rectangle)
        display.canvas.store.append(original)
        display.canvas.tool = .select

        func event(_ type: NSEvent.EventType, x: CGFloat, y: CGFloat, time: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: y),
                modifierFlags: [], timestamp: time, windowNumber: display.window.windowNumber,
                context: nil, eventNumber: Int(time * 10), clickCount: 1,
                pressure: type == .leftMouseUp ? 0 : 1))
        }

        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 60, y: 50, time: 1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 60, y: 50, time: 1.1))
        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 110, y: 80, time: 2))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 150, y: 120, time: 2.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 150, y: 120, time: 2.2))

        #expect(display.canvas.store.strokes[0].points == [
            InkPoint(x: 10, y: 20), InkPoint(x: 150, y: 120)
        ])
        display.canvas.store.undo()
        #expect(display.canvas.store.strokes[0] == original)
    }

    @Test func boardChangesPreserveAnnotationsAndDoNotConsumeUndo() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        display.canvas.store.append(Stroke(points: [InkPoint(x: 20, y: 30)],
            color: 0xBF5AF2, width: 4))

        display.canvas.boardStyle = .whiteboard
        #expect(display.canvas.store.strokes.count == 1)
        #expect(BoardStyle.whiteboard.backgroundColor != nil)
        display.canvas.boardStyle = .blackboard
        #expect(display.canvas.store.strokes.count == 1)
        #expect(BoardStyle.blackboard.backgroundColor != nil)
        display.canvas.boardStyle = .screen
        #expect(BoardStyle.screen.backgroundColor == nil)

        display.canvas.store.undo()
        #expect(display.canvas.store.strokes.isEmpty)
    }

    @Test func customBoardRegionAffectsOnlyTheChosenCanvas() throws {
        _ = NSApplication.shared
        let screens = try #require(!NSScreen.screens.isEmpty ? NSScreen.screens : nil)
        let first = DisplayCanvas(screen: screens[0])
        let second = DisplayCanvas(screen: screens.count > 1 ? screens[1] : screens[0])
        defer { first.window.close(); second.window.close() }
        first.canvas.beginBoardRegionSelection(.blackboard)

        func event(_ type: NSEvent.EventType, x: CGFloat, y: CGFloat, time: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: y),
                modifierFlags: [], timestamp: time, windowNumber: first.window.windowNumber,
                context: nil, eventNumber: Int(time * 10), clickCount: 1,
                pressure: type == .leftMouseUp ? 0 : 1))
        }
        first.canvas.mouseDown(with: try event(.leftMouseDown, x: 40, y: 60, time: 1))
        first.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 440, y: 300, time: 1.1))
        first.canvas.mouseUp(with: try event(.leftMouseUp, x: 440, y: 300, time: 1.2))

        #expect(first.canvas.boardStyle == .blackboard)
        #expect(first.canvas.boardRegion == CGRect(x: 40, y: 60, width: 400, height: 240))
        #expect(second.canvas.boardStyle == .screen)
        #expect(second.canvas.boardRegion == nil)
    }

    @Test func selectToolMovesAndResizesFreehandAndBoardIndividually() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        display.canvas.store.append(Stroke(points: [InkPoint(x: 10, y: 10),
            InkPoint(x: 60, y: 60), InkPoint(x: 110, y: 10)],
            color: 0xFFD60A, width: 16, opacity: 0.28))
        display.canvas.tool = .select

        func event(_ type: NSEvent.EventType, x: CGFloat, y: CGFloat, time: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: y),
                modifierFlags: [], timestamp: time, windowNumber: display.window.windowNumber,
                context: nil, eventNumber: Int(time * 10), clickCount: 1,
                pressure: type == .leftMouseUp ? 0 : 1))
        }
        func click(_ x: CGFloat, _ y: CGFloat, _ time: TimeInterval) throws {
            display.canvas.mouseDown(with: try event(.leftMouseDown, x: x, y: y, time: time))
            display.canvas.mouseUp(with: try event(.leftMouseUp, x: x, y: y, time: time + 0.01))
        }

        try click(60, 60, 1)
        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 110, y: 60, time: 2))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 210, y: 110, time: 2.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 210, y: 110, time: 2.2))
        #expect(display.canvas.store.strokes[0].points.count == 3)
        #expect(display.canvas.store.strokes[0].points[1] == InkPoint(x: 110, y: 110))

        display.canvas.setBoard(.whiteboard, region: CGRect(x: 300, y: 100, width: 300, height: 200))
        try click(300, 200, 3)
        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 600, y: 300, time: 4))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 700, y: 360, time: 4.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 700, y: 360, time: 4.2))
        #expect(display.canvas.boardRegion == CGRect(x: 300, y: 100, width: 400, height: 260))
        #expect(display.canvas.store.strokes[0].points.count == 3)
    }

    @Test func marqueeSelectionMovesResizesAndRecolorsSeveralAnnotationsTogether() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        let first = Stroke(points: [InkPoint(x: 40, y: 40), InkPoint(x: 100, y: 90)],
            color: 0xFF453A, width: 4, kind: .rectangle)
        let second = Stroke(points: [InkPoint(x: 130, y: 50), InkPoint(x: 180, y: 100)],
            color: 0xFFD60A, width: 4, kind: .ellipse)
        let outside = Stroke(points: [InkPoint(x: 300, y: 300), InkPoint(x: 340, y: 340)],
            color: 0x30D158, width: 4, kind: .diamond)
        [first, second, outside].forEach { display.canvas.store.append($0) }
        display.canvas.tool = .select

        func event(_ type: NSEvent.EventType, x: CGFloat, y: CGFloat, time: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: y),
                modifierFlags: [], timestamp: time, windowNumber: display.window.windowNumber,
                context: nil, eventNumber: Int(time * 10), clickCount: 1,
                pressure: type == .leftMouseUp ? 0 : 1))
        }
        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 20, y: 20, time: 1))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 210, y: 120, time: 1.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 210, y: 120, time: 1.2))
        #expect(display.canvas.applyColorToSelection(0xBF5AF2))
        #expect(display.canvas.store.strokes.map(\.color) == [0xBF5AF2, 0xBF5AF2, 0x30D158])
        display.canvas.store.undo()
        #expect(display.canvas.store.strokes == [first, second, outside])

        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 70, y: 65, time: 2))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 100, y: 85, time: 2.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 100, y: 85, time: 2.2))
        #expect(display.canvas.store.strokes[0].points.first == InkPoint(x: 70, y: 60))
        #expect(display.canvas.store.strokes[1].points.first == InkPoint(x: 160, y: 70))
        #expect(display.canvas.store.strokes[2] == outside)
    }

    @Test func boardFrameSelectionMovesContainedAnnotationsButInteriorSelectsInk() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        let inside = Stroke(points: [InkPoint(x: 150, y: 150), InkPoint(x: 200, y: 190)],
            color: 0xFF453A, width: 4, kind: .rectangle)
        let outside = Stroke(points: [InkPoint(x: 500, y: 400), InkPoint(x: 550, y: 440)],
            color: 0x30D158, width: 4, kind: .ellipse)
        display.canvas.store.append(inside)
        display.canvas.store.append(outside)
        display.canvas.setBoard(.whiteboard, region: CGRect(x: 100, y: 100, width: 300, height: 200))
        display.canvas.tool = .select

        func event(_ type: NSEvent.EventType, x: CGFloat, y: CGFloat, time: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: y),
                modifierFlags: [], timestamp: time, windowNumber: display.window.windowNumber,
                context: nil, eventNumber: Int(time * 10), clickCount: 1,
                pressure: type == .leftMouseUp ? 0 : 1))
        }
        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 100, y: 200, time: 1))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 140, y: 230, time: 1.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 140, y: 230, time: 1.2))
        #expect(display.canvas.boardRegion == CGRect(x: 140, y: 130, width: 300, height: 200))
        #expect(display.canvas.store.strokes[0].points.first == InkPoint(x: 190, y: 180))
        #expect(display.canvas.store.strokes[1] == outside)
        display.canvas.store.undo()
        #expect(display.canvas.store.strokes[0] == inside)

        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 160, y: 160, time: 2))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 180, y: 170, time: 2.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 180, y: 170, time: 2.2))
        #expect(display.canvas.boardRegion == CGRect(x: 140, y: 130, width: 300, height: 200))
    }

    @Test func drawingStartedInsideBoardCannotCrossItsWritingSurface() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        display.canvas.setBoard(.whiteboard, region: CGRect(x: 100, y: 100, width: 300, height: 200))
        display.canvas.tool = .line
        display.canvas.penWidth = 4

        func event(_ type: NSEvent.EventType, x: CGFloat, y: CGFloat, time: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: y),
                modifierFlags: [], timestamp: time, windowNumber: display.window.windowNumber,
                context: nil, eventNumber: Int(time * 10), clickCount: 1,
                pressure: type == .leftMouseUp ? 0 : 1))
        }
        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 150, y: 150, time: 1))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 500, y: 350, time: 1.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 500, y: 350, time: 1.2))
        #expect(display.canvas.store.strokes[0].points.last == InkPoint(x: 388, y: 288))

        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 450, y: 350, time: 2))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 600, y: 420, time: 2.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 600, y: 420, time: 2.2))
        #expect(display.canvas.store.strokes[1].points.last == InkPoint(x: 600, y: 420))
    }

    @Test func drawingModeImmediatelyUsesTheSelectedToolCursor() throws {
        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close(); NSCursor.arrow.set() }

        display.canvas.tool = .eraser
        display.setDrawing(true)
        #expect(NSCursor.current === display.canvas.activeToolCursor)
        #expect(NSCursor.current !== NSCursor.arrow)

        display.canvas.tool = .highlighter
        #expect(NSCursor.current === display.canvas.activeToolCursor)
        #expect(NSCursor.current.image.size.width >= 32)

        display.canvas.tool = .text
        #expect(NSCursor.current === NSCursor.iBeam)

        display.setDrawing(false)
        #expect(NSCursor.current === NSCursor.arrow)
    }

    @Test func curatedTeachingFontsResolveAndApplyToSelectedText() throws {
        _ = NSApplication.shared
        for style in TextFontCatalog.styles {
            let font = style.font(size: 28)
            #expect(font.pointSize == 28)
        }
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        let first = Stroke(points: [InkPoint(x: 40, y: 40)], color: 0xFFFFFF, width: 1,
            kind: .text, text: "Explain", fontSize: 28)
        let second = Stroke(points: [InkPoint(x: 160, y: 60)], color: 0xFFFFFF, width: 1,
            kind: .text, text: "Clearly", fontSize: 28)
        let shape = Stroke(points: [InkPoint(x: 300, y: 300), InkPoint(x: 350, y: 350)],
            color: 0xFFFFFF, width: 4, kind: .rectangle)
        [first, second, shape].forEach { display.canvas.store.append($0) }
        display.canvas.tool = .select

        func event(_ type: NSEvent.EventType, x: CGFloat, y: CGFloat, time: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: y),
                modifierFlags: [], timestamp: time, windowNumber: display.window.windowNumber,
                context: nil, eventNumber: Int(time * 10), clickCount: 1,
                pressure: type == .leftMouseUp ? 0 : 1))
        }
        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 20, y: 20, time: 1))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 280, y: 120, time: 1.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 280, y: 120, time: 1.2))
        #expect(display.canvas.applyFontToSelection("noteworthy"))
        #expect(display.canvas.store.strokes[0].fontStyleID == "noteworthy")
        #expect(display.canvas.store.strokes[1].fontStyleID == "noteworthy")
        #expect(display.canvas.store.strokes[2].fontStyleID == TextFontCatalog.defaultID)
        display.canvas.store.undo()
        #expect(display.canvas.store.strokes[0].fontStyleID == TextFontCatalog.defaultID)
        #expect(display.canvas.store.strokes[1].fontStyleID == TextFontCatalog.defaultID)

        #expect(display.canvas.applyTextAlignmentToSelection(.center))
        #expect(display.canvas.store.strokes[0].textAlignment == .center)
        #expect(display.canvas.store.strokes[1].textAlignment == .center)
        #expect(display.canvas.store.strokes[2].textAlignment == .left)
        display.canvas.store.undo()
        #expect(display.canvas.store.strokes[0].textAlignment == .left)
        #expect(display.canvas.store.strokes[1].textAlignment == .left)
    }

    @Test func screenshotRegionSelectionUsesLocalCoordinatesAndPngEncodingWorks() throws {
        #expect(ScreenshotError.permissionDenied.requiresScreenRecordingPermission)
        #expect(!ScreenshotError.displayUnavailable.requiresScreenRecordingPermission)

        _ = NSApplication.shared
        let screen = try #require(NSScreen.screens.first)
        let display = DisplayCanvas(screen: screen)
        defer { display.window.close() }
        var selectedRegion: CGRect?
        display.canvas.onScreenshotRegionSelected = { selectedRegion = $0 }
        display.canvas.beginScreenshotRegionSelection()

        func event(_ type: NSEvent.EventType, x: CGFloat, y: CGFloat, time: TimeInterval) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: y),
                modifierFlags: [], timestamp: time, windowNumber: display.window.windowNumber,
                context: nil, eventNumber: Int(time * 10), clickCount: 1,
                pressure: type == .leftMouseUp ? 0 : 1))
        }
        display.canvas.mouseDown(with: try event(.leftMouseDown, x: 40, y: 60, time: 1))
        display.canvas.mouseDragged(with: try event(.leftMouseDragged, x: 440, y: 300, time: 1.1))
        display.canvas.mouseUp(with: try event(.leftMouseUp, x: 440, y: 300, time: 1.2))
        #expect(selectedRegion == CGRect(x: 40, y: 60, width: 400, height: 240))
        #expect(ScreenshotService.captureRect(for: selectedRegion!,
            screenSize: CGSize(width: 1000, height: 800)) ==
            CGRect(x: 40, y: 500, width: 400, height: 240))

        let context = try #require(CGContext(data: nil, width: 8, height: 8,
            bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(NSColor.systemPurple.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        let image = try #require(context.makeImage())
        let png = try ScreenshotService.pngData(for: image)
        #expect(Array(png.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10])
    }

}
