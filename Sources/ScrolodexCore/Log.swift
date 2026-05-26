import Foundation

public enum Log {
	public nonisolated(unsafe) static var debugEnabled = false

	public static func debug(_ message: String, _ args: CVarArg...) {
		guard debugEnabled else { return }
		NSLog("Scrolodex: " + message, args)
	}

	public static func info(_ message: String, _ args: CVarArg...) {
		NSLog("Scrolodex: " + message, args)
	}
}
