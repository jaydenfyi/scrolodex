import AppKit
import CoreGraphics

enum DockSide {
	case top, bottom, left, right
}

enum DockGeometry {
	@_silgen_name("CoreDockGetOrientationAndPinning")
	private static func coreDockOrientationAndPinning(
		_ orientation: UnsafeMutablePointer<Int32>,
		_ pinning: UnsafeMutablePointer<Int32>
	)

	static var side: DockSide {
		var orientation: Int32 = 0
		var pinning: Int32 = 0
		coreDockOrientationAndPinning(&orientation, &pinning)
		switch orientation {
		case 1: return .top
		case 3: return .left
		case 4: return .right
		default: return .bottom
		}
	}

	static var isHorizontal: Bool {
		side == .top || side == .bottom
	}

	static func dockSize() -> CGFloat {
		guard let screen = NSScreen.main else { return 0 }
		switch side {
		case .right: return screen.frame.width - screen.visibleFrame.width
		case .left: return screen.visibleFrame.origin.x
		case .bottom: return screen.visibleFrame.origin.y
		case .top: return screen.frame.height - screen.visibleFrame.maxY
		}
	}

	static func anchorPoint(forDockItemFrame frame: CGRect) -> CGPoint {
		CGPoint(x: frame.midX, y: frame.midY)
	}
}
