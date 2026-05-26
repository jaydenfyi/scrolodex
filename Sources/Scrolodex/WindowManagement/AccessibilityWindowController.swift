import AppKit
import ApplicationServices
import ScrolodexCore

private typealias SLPSSetFrontProcessWithOptionsFunc = @convention(c) (
	UnsafeMutablePointer<ProcessSerialNumber>, CGWindowID, UInt32
) -> CGError
private typealias SLPSPostEventRecordToFunc = @convention(c) (
	UnsafeMutablePointer<ProcessSerialNumber>, UnsafeMutablePointer<UInt8>
) -> CGError

@_silgen_name("GetProcessForPID") @discardableResult
private func GetProcessForPID(_ pid: pid_t, _ psn: UnsafeMutablePointer<ProcessSerialNumber>) -> OSStatus

private enum SkyLight {
	private nonisolated(unsafe) static let handle = dlopen(
		"/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
		RTLD_LAZY | RTLD_NODELETE
	)

	static let setFrontProcessWithOptions: SLPSSetFrontProcessWithOptionsFunc? = load(
		symbol: "_SLPSSetFrontProcessWithOptions")
	static let postEventRecordTo: SLPSPostEventRecordToFunc? = load(symbol: "SLPSPostEventRecordTo")

	private static func load<T>(symbol: String) -> T? {
		guard let handle, let ptr = dlsym(handle, symbol) else { return nil }
		return unsafeBitCast(ptr, to: T.self)
	}
}

@MainActor
final class AccessibilityWindowController: WindowRaising {
	func raise(candidate: WindowCandidate) {
		Log.debug(
			"raise requested owner=%@ pid=%d title=%@", candidate.ownerName, candidate.ownerPID,
			candidate.windowTitle ?? "")
		let appElement = AXUIElementCreateApplication(candidate.ownerPID)
		let window = AXWindowAccessor.findWindow(for: candidate, in: appElement)

		bringToFront(candidate: candidate, window: window)
	}

	private func bringToFront(candidate: WindowCandidate, window: AXUIElement?) {
		var psn = ProcessSerialNumber()
		let psnResult = GetProcessForPID(candidate.ownerPID, &psn)
		if psnResult != noErr {
			Log.debug("GetProcessForPID pid=%d failed: %d", candidate.ownerPID, psnResult)
			return
		}

		if let setFront = SkyLight.setFrontProcessWithOptions {
			let result = setFront(&psn, candidate.cgWindowID, 0x200)
			Log.debug(
				"SLPSSetFrontProcessWithOptions wid=%u result=%d", candidate.cgWindowID, result.rawValue
			)
		}

		makeKeyWindow(&psn, cgWindowID: candidate.cgWindowID)

		if let window {
			let raiseResult = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
			Log.debug("AX raise wid=%u result=%d", candidate.cgWindowID, raiseResult.rawValue)
		} else {
			Log.debug("no matching AX window found; used SkyLight focus only wid=%u", candidate.cgWindowID)
		}
	}

	private func makeKeyWindow(_ psn: inout ProcessSerialNumber, cgWindowID: CGWindowID) {
		guard let postEvent = SkyLight.postEventRecordTo else { return }

		let recordSize = 0xf8
		let windowIDOffset = 0x3c
		let processBytesRange = 0x20..<0x30
		precondition(windowIDOffset + MemoryLayout<UInt32>.size <= recordSize)
		precondition(processBytesRange.upperBound <= recordSize)

		var bytes = [UInt8](repeating: 0, count: recordSize)
		bytes[0x04] = UInt8(recordSize)
		bytes[0x3a] = 0x10
		let windowIDBytes = withUnsafeBytes(of: UInt32(cgWindowID).littleEndian) { Array($0) }
		bytes.replaceSubrange(windowIDOffset..<(windowIDOffset + windowIDBytes.count), with: windowIDBytes)
		bytes.replaceSubrange(processBytesRange, with: Array(repeating: 0xff, count: processBytesRange.count))

		bytes[0x08] = 0x01
		_ = postEvent(&psn, &bytes)
		bytes[0x08] = 0x02
		_ = postEvent(&psn, &bytes)
	}
}
