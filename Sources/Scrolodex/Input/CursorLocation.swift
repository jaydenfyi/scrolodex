import AppKit
import CoreGraphics

func cgCursorLocation() -> CGPoint {
	let mainScreenHeight = NSScreen.screens[0].frame.height
	let appKitLocation = NSEvent.mouseLocation
	return CGPoint(x: appKitLocation.x, y: mainScreenHeight - appKitLocation.y)
}
