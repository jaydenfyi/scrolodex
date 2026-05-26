import CoreGraphics
import Foundation

public enum CGWindowDictionaryParser {
	public static func candidate(from dictionary: [String: Any]) -> WindowCandidate? {
		guard let windowID = unsigned32Value(dictionary[kCGWindowNumber as String]),
			let ownerPID = int32Value(dictionary[kCGWindowOwnerPID as String]),
			let ownerName = dictionary[kCGWindowOwnerName as String] as? String,
			let layer = intValue(dictionary[kCGWindowLayer as String]),
			let alpha = doubleValue(dictionary[kCGWindowAlpha as String]),
			let boundsDictionary = dictionary[kCGWindowBounds as String] as? NSDictionary,
			let bounds = CGRect(dictionaryRepresentation: boundsDictionary)
		else {
			return nil
		}

		return WindowCandidate(
			cgWindowID: CGWindowID(windowID),
			ownerPID: pid_t(ownerPID),
			ownerName: ownerName,
			windowTitle: dictionary[kCGWindowName as String] as? String,
			bounds: bounds,
			layer: layer,
			alpha: alpha
		)
	}

	private static func unsigned32Value(_ value: Any?) -> UInt32? {
		if let value = value as? UInt32 { return value }
		if let value = value as? Int { return UInt32(value) }
		if let value = value as? NSNumber { return value.uint32Value }
		return nil
	}

	private static func int32Value(_ value: Any?) -> Int32? {
		if let value = value as? Int32 { return value }
		if let value = value as? Int { return Int32(value) }
		if let value = value as? NSNumber { return value.int32Value }
		return nil
	}

	private static func intValue(_ value: Any?) -> Int? {
		if let value = value as? Int { return value }
		if let value = value as? NSNumber { return value.intValue }
		return nil
	}

	private static func doubleValue(_ value: Any?) -> Double? {
		if let value = value as? Double { return value }
		if let value = value as? NSNumber { return value.doubleValue }
		return nil
	}
}
