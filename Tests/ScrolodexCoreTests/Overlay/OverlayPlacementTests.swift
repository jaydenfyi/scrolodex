import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Overlay placement")
struct OverlayPlacementTests {
    @Test("centers overlay in selected window when it fits")
    func centersInSelectedWindow() {
        let frame = OverlayPlacement.frame(
            preferredSize: CGSize(width: 300, height: 200),
            anchorBounds: CGRect(x: 100, y: 100, width: 800, height: 600),
            screenBounds: CGRect(x: 0, y: 0, width: 1200, height: 900)
        )

        #expect(frame == CGRect(x: 350, y: 300, width: 300, height: 200))
    }

    @Test("clamps overlay to visible screen")
    func clampsToScreen() {
        let frame = OverlayPlacement.frame(
            preferredSize: CGSize(width: 500, height: 300),
            anchorBounds: CGRect(x: 0, y: 0, width: 200, height: 100),
            screenBounds: CGRect(x: 0, y: 0, width: 600, height: 400),
            margin: 24
        )

        #expect(frame == CGRect(x: 24, y: 24, width: 500, height: 300))
    }

    @Test("converts Core Graphics bounds on a right-hand secondary display")
    func convertsRightHandSecondaryDisplay() {
        let appKitFrame = OverlayPlacement.appKitFrame(
            fromCGWindowBounds: CGRect(x: 3200, y: 200, width: 500, height: 400),
            screens: [
                .init(cgBounds: CGRect(x: 0, y: 0, width: 1920, height: 1080), appKitFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)),
                .init(cgBounds: CGRect(x: 1920, y: 0, width: 1440, height: 900), appKitFrame: CGRect(x: 1920, y: 0, width: 1440, height: 900))
            ]
        )

        #expect(appKitFrame == CGRect(x: 3200, y: 300, width: 500, height: 400))
    }

    @Test("converts Core Graphics bounds on a display above the main display")
    func convertsDisplayAboveMain() {
        let appKitFrame = OverlayPlacement.appKitFrame(
            fromCGWindowBounds: CGRect(x: 100, y: -700, width: 400, height: 300),
            screens: [
                .init(cgBounds: CGRect(x: 0, y: 0, width: 1920, height: 1080), appKitFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)),
                .init(cgBounds: CGRect(x: 0, y: -900, width: 1440, height: 900), appKitFrame: CGRect(x: 0, y: 1080, width: 1440, height: 900))
            ]
        )

        #expect(appKitFrame == CGRect(x: 100, y: 1480, width: 400, height: 300))
    }

    @Test("converts Core Graphics cursor point on secondary display")
    func convertsCursorPointOnSecondaryDisplay() {
        let point = OverlayPlacement.appKitPoint(
            fromCGDisplayPoint: CGPoint(x: 2000, y: 100),
            screens: [
                .init(cgBounds: CGRect(x: 0, y: 0, width: 1920, height: 1080), appKitFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)),
                .init(cgBounds: CGRect(x: 1920, y: 0, width: 1440, height: 900), appKitFrame: CGRect(x: 1920, y: 0, width: 1440, height: 900))
            ]
        )

        #expect(point == CGPoint(x: 2000, y: 800))
    }

    @Test("converts Core Graphics cursor point on display above main")
    func convertsCursorPointOnDisplayAboveMain() {
        let point = OverlayPlacement.appKitPoint(
            fromCGDisplayPoint: CGPoint(x: 100, y: -700),
            screens: [
                .init(cgBounds: CGRect(x: 0, y: 0, width: 1920, height: 1080), appKitFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)),
                .init(cgBounds: CGRect(x: 0, y: -900, width: 1440, height: 900), appKitFrame: CGRect(x: 0, y: 1080, width: 1440, height: 900))
            ]
        )

        #expect(point == CGPoint(x: 100, y: 1780))
    }

    @Test("selects conversion frame containing current mouse location")
    func selectsFrameContainingMouse() {
        let frame = OverlayPlacement.bestFrame(
            from: [
                CGRect(x: 100, y: 100, width: 400, height: 300),
                CGRect(x: 2100, y: 240, width: 400, height: 300)
            ],
            containingOrNearestTo: CGPoint(x: 3200, y: 300)
        )

        #expect(frame == CGRect(x: 2100, y: 240, width: 400, height: 300))
    }

    @Test("selects nearest conversion frame when mouse is outside every frame")
    func selectsNearestFrame() {
        let frame = OverlayPlacement.bestFrame(
            from: [
                CGRect(x: 100, y: 100, width: 400, height: 300),
                CGRect(x: 2100, y: 240, width: 400, height: 300)
            ],
            containingOrNearestTo: CGPoint(x: 2600, y: 300)
        )

        #expect(frame == CGRect(x: 2100, y: 240, width: 400, height: 300))
    }

    @Test("chooses secondary screen bounds for a secondary screen anchor")
    func choosesScreenForAnchor() {
        let screen = OverlayPlacement.screenBounds(
            forAnchorBounds: CGRect(x: 2100, y: 240, width: 400, height: 300),
            mouseLocation: CGPoint(x: 3200, y: 300),
            screens: [
                CGRect(x: 0, y: 0, width: 1920, height: 1080),
                CGRect(x: 1920, y: 0, width: 1440, height: 900)
            ]
        )

        #expect(screen == CGRect(x: 1920, y: 0, width: 1440, height: 900))
    }

    @Test("tile overlay centers on anchor window")
    func tileOverlayCentersOnAnchor() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let anchor = CGRect(x: 100, y: 100, width: 800, height: 600)
        let frame = OverlayPlacement.tileOverlayFrame(
            candidateCount: 5,
            selectedBounds: anchor,
            cursor: CGPoint(x: 500, y: 400),
            screens: [screen]
        )

        let expectedWidth = screen.width - 2 * 24
        #expect(frame.width == expectedWidth)
        #expect(frame.height == 320)
        #expect(frame.minX == screen.minX + 24)
    }

    @Test("tile overlay near cursor when no anchor")
    func tileOverlayNearCursorNoAnchor() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let frame = OverlayPlacement.tileOverlayFrame(
            candidateCount: 3,
            selectedBounds: nil,
            cursor: CGPoint(x: 500, y: 400),
            screens: [screen]
        )

        let expectedWidth = screen.width - 2 * 24
        #expect(frame.width == expectedWidth)
        #expect(frame.height == 320)
    }

    @Test("tile overlay clamps to screen")
    func tileOverlayClampsToScreen() {
        let screen = CGRect(x: 0, y: 0, width: 1200, height: 800)
        let anchor = CGRect(x: -100, y: 0, width: 200, height: 100)
        let frame = OverlayPlacement.tileOverlayFrame(
            candidateCount: 5,
            selectedBounds: anchor,
            cursor: CGPoint(x: 0, y: 50),
            screens: [screen]
        )

        let expectedWidth = screen.width - 2 * 24
        #expect(frame.width == expectedWidth)
        #expect(frame.height == 320)
        #expect(frame.minX >= screen.minX)
    }
}
