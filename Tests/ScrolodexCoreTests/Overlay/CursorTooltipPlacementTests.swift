import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Cursor tooltip placement")
struct CursorTooltipPlacementTests {
    @Test("places tooltip near cursor")
    func placesTooltipNearCursor() {
        let frame = CursorTooltipPlacement.frame(
            size: CGSize(width: 200, height: 68),
            cursor: CGPoint(x: 100, y: 100),
            screens: [CGRect(x: 0, y: 0, width: 500, height: 500)]
        )

        #expect(frame.origin.x == 114)
        #expect(frame.origin.y == 106)
    }

    @Test("clamps tooltip inside screen")
    func clampsTooltipInsideScreen() {
        let frame = CursorTooltipPlacement.frame(
            size: CGSize(width: 200, height: 68),
            cursor: CGPoint(x: 490, y: 490),
            screens: [CGRect(x: 0, y: 0, width: 500, height: 500)]
        )

        #expect(frame.origin.x == 292)
        #expect(frame.origin.y == 424)
    }
}
