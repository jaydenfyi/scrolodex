import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Window stack overlay model")
struct WindowStackOverlayModelTests {
    @Test("formats candidate rows with detailed primary and secondary text")
    func formatsCandidateRows() {
        let model = WindowStackOverlayModel(candidates: [
            candidate(id: 1, ownerName: "Safari", title: "Docs"),
            candidate(id: 2, ownerName: "Xcode", title: nil)
        ], selected: candidate(id: 2, ownerName: "Xcode", title: nil))

        #expect(model.title == "Choose Window")
        #expect(model.subtitle == "2 windows under cursor")
        #expect(model.rows.map(\.primaryText) == ["Docs", "Xcode"])
        #expect(model.rows.map(\.secondaryText) == ["Safari • Window #1", "Xcode • Window #2"])
        #expect(model.rows.map(\.isSelected) == [false, true])
    }

    @Test("describes empty candidate stack")
    func describesEmptyStack() {
        let model = WindowStackOverlayModel(candidates: [], selected: nil)

        #expect(model.title == "No Windows Here")
        #expect(model.subtitle == "Move over overlapping windows, then scroll")
        #expect(model.rows.isEmpty)
    }

    private func candidate(id: CGWindowID, ownerName: String, title: String?) -> WindowCandidate {
        WindowCandidate(
            cgWindowID: id,
            ownerPID: pid_t(id),
            ownerName: ownerName,
            windowTitle: title,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            layer: 0,
            alpha: 1
        )
    }
}
