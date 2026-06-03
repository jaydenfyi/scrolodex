import CoreGraphics
import ScrolodexCore
import Testing

@Suite("gesture mouse move policy")
struct GestureMouseMovePolicyTests {
	@Test("mouse movement is consumed only during a gesture session")
	func mouseMovementIsConsumedOnlyDuringGestureSession() {
		#expect(GestureMouseMovePolicy.shouldConsume(type: .mouseMoved, gestureSessionActive: false) == false)
		#expect(GestureMouseMovePolicy.shouldConsume(type: .mouseMoved, gestureSessionActive: true) == true)
		#expect(GestureMouseMovePolicy.shouldConsume(type: .scrollWheel, gestureSessionActive: true) == false)
	}
}
