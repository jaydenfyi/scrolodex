import CoreGraphics

public enum GestureMouseMovePolicy {
	public static func shouldConsume(type: CGEventType, gestureSessionActive: Bool) -> Bool {
		type == .mouseMoved && gestureSessionActive
	}
}
