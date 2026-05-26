import Foundation

public enum PeekMode: String, CaseIterable, Sendable {
	case snapshot
	case stackScrub

	public static let `default`: PeekMode = .snapshot

	public var displayName: String {
		switch self {
		case .snapshot: "Snapshot"
		case .stackScrub: "Stack Scrub"
		}
	}
}
