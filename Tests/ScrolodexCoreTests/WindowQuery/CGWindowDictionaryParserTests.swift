import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("CGWindow dictionary parsing")
struct CGWindowDictionaryParserTests {
    @Test("builds a candidate from a Core Graphics window dictionary")
    func buildsCandidate() throws {
        let dictionary: [String: Any] = [
            kCGWindowNumber as String: 42,
            kCGWindowOwnerPID as String: 1234,
            kCGWindowOwnerName as String: "Finder",
            kCGWindowName as String: "Documents",
            kCGWindowLayer as String: 0,
            kCGWindowAlpha as String: 1.0,
            kCGWindowBounds as String: ["X": 10, "Y": 20, "Width": 300, "Height": 200]
        ]

        let candidate = try #require(CGWindowDictionaryParser.candidate(from: dictionary))

        #expect(candidate.cgWindowID == 42)
        #expect(candidate.ownerPID == 1234)
        #expect(candidate.ownerName == "Finder")
        #expect(candidate.windowTitle == "Documents")
        #expect(candidate.bounds == CGRect(x: 10, y: 20, width: 300, height: 200))
    }

    @Test("returns nil when required fields are absent")
    func returnsNilForMissingFields() {
        #expect(CGWindowDictionaryParser.candidate(from: [:]) == nil)
    }
}
