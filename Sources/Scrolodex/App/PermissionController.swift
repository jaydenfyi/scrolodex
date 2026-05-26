import AppKit
import ApplicationServices
import CoreGraphics

@MainActor
final class PermissionController {
	private var hasRequestedScreenRecording = false

	var isAccessibilityTrusted: Bool {
		AXIsProcessTrusted()
	}

	var hasScreenRecordingAccess: Bool {
		CGPreflightScreenCaptureAccess()
	}

	var allPermissionsGranted: Bool {
		isAccessibilityTrusted && hasScreenRecordingAccess
	}

	func requestAccessibilityPermission() {
		let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
		_ = AXIsProcessTrustedWithOptions(options)
	}

	@discardableResult
	func requestScreenRecordingPermission() -> Bool {
		guard !hasRequestedScreenRecording else { return false }
		hasRequestedScreenRecording = true
		return CGRequestScreenCaptureAccess()
	}

	func requestAllPermissions() {
		if !isAccessibilityTrusted {
			requestAccessibilityPermission()
		}
	}

	func openAccessibilitySettings() {
		if #available(macOS 14.0, *) {
			let url = URL(
				string:
					"x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
			)!
			NSWorkspace.shared.open(url)
		} else {
			let url = URL(
				string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
			NSWorkspace.shared.open(url)
		}
	}

	func openScreenRecordingSettings() {
		if #available(macOS 14.0, *) {
			let url = URL(
				string:
					"x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
			)!
			NSWorkspace.shared.open(url)
		} else {
			let url = URL(
				string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
			NSWorkspace.shared.open(url)
		}
	}
}
