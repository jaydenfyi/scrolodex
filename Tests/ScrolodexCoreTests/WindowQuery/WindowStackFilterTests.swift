import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Window stack filtering")
struct WindowStackFilterTests {
    @Test("keeps cursor-contained candidates in existing front-to-back order")
    func keepsCandidatesUnderCursorInOrder() {
        let windows = [
            candidate(id: 10, ownerPID: 100, ownerName: "Front", bounds: CGRect(x: 0, y: 0, width: 200, height: 200)),
            candidate(id: 20, ownerPID: 200, ownerName: "Middle", bounds: CGRect(x: 25, y: 25, width: 200, height: 200)),
            candidate(id: 30, ownerPID: 300, ownerName: "Away", bounds: CGRect(x: 500, y: 500, width: 100, height: 100))
        ]

        let result = WindowStackFilter.candidates(
            from: windows,
            under: CGPoint(x: 50, y: 50),
            excludingOwnerNames: []
        )

        #expect(result.map(\.cgWindowID) == [10, 20])
    }

    @Test("removes system layer invisible invalid and excluded windows")
    func removesUnselectableWindows() {
        let windows = [
            candidate(id: 1, ownerPID: 101, ownerName: "Good", bounds: CGRect(x: 0, y: 0, width: 100, height: 100)),
            candidate(id: 2, ownerPID: 102, ownerName: "Dock", bounds: CGRect(x: 0, y: 0, width: 100, height: 100), layer: 25),
            candidate(id: 3, ownerPID: 103, ownerName: "Hidden", bounds: CGRect(x: 0, y: 0, width: 100, height: 100), alpha: 0),
            candidate(id: 4, ownerPID: 104, ownerName: "Invalid", bounds: CGRect(x: 0, y: 0, width: 0, height: 100)),
            candidate(id: 5, ownerPID: 105, ownerName: "Scrolodex", bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
        ]

        let result = WindowStackFilter.candidates(
            from: windows,
            under: CGPoint(x: 50, y: 50),
            excludingOwnerNames: ["Scrolodex"]
        )

        #expect(result.map(\.cgWindowID) == [1])
    }

    @Test("allWindows returns visible windows on the same screen")
    func allWindowsReturnsAllVisible() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let windows = [
            candidate(id: 10, ownerPID: 100, ownerName: "Front", bounds: CGRect(x: 0, y: 0, width: 200, height: 200)),
            candidate(id: 20, ownerPID: 200, ownerName: "Middle", bounds: CGRect(x: 25, y: 25, width: 200, height: 200)),
            candidate(id: 30, ownerPID: 300, ownerName: "Away", bounds: CGRect(x: 500, y: 500, width: 100, height: 100)),
            candidate(id: 40, ownerPID: 400, ownerName: "Hidden", bounds: CGRect(x: 600, y: 600, width: 100, height: 100), alpha: 0),
            candidate(id: 50, ownerPID: 500, ownerName: "Scrolodex", bounds: CGRect(x: 700, y: 700, width: 100, height: 100)),
            candidate(id: 60, ownerPID: 600, ownerName: "OtherScreen", bounds: CGRect(x: 2000, y: 0, width: 200, height: 200))
        ]

        let result = WindowStackFilter.allWindows(
            from: windows,
            monitorScope: .currentMonitor,
            screenBounds: screen,
            excludingOwnerNames: ["Scrolodex"]
        )

        #expect(result.map(\.cgWindowID) == [10, 20, 30] as [CGWindowID])
    }

    @Test("allWindows can return visible windows across all monitors")
    func allWindowsCanReturnAcrossAllMonitors() {
        let windows = [
            candidate(id: 10, ownerPID: 100, ownerName: "Main", bounds: CGRect(x: 0, y: 0, width: 200, height: 200)),
            candidate(id: 20, ownerPID: 200, ownerName: "Second", bounds: CGRect(x: 2000, y: 0, width: 200, height: 200)),
            candidate(id: 30, ownerPID: 300, ownerName: "Hidden", bounds: CGRect(x: 2500, y: 0, width: 200, height: 200), alpha: 0),
            candidate(id: 40, ownerPID: 400, ownerName: "Scrolodex", bounds: CGRect(x: 3000, y: 0, width: 200, height: 200))
        ]

        let result = WindowStackFilter.allWindows(
            from: windows,
            monitorScope: .allMonitors,
            screenBounds: CGRect(x: 0, y: 0, width: 1000, height: 1000),
            excludingOwnerNames: ["Scrolodex"]
        )

        #expect(result.map(\.cgWindowID) == [10, 20] as [CGWindowID])
    }

    @Test("allWindows includes non-zero layer windows up to threshold")
    func allWindowsIncludesNonZeroLayer() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let windows = [
            candidate(id: 10, ownerPID: 100, ownerName: "Normal", bounds: CGRect(x: 0, y: 0, width: 200, height: 200), layer: 0),
            candidate(id: 20, ownerPID: 200, ownerName: "Floating", bounds: CGRect(x: 0, y: 0, width: 200, height: 200), layer: 3),
            candidate(id: 30, ownerPID: 300, ownerName: "Panel", bounds: CGRect(x: 0, y: 0, width: 200, height: 200), layer: 20),
            candidate(id: 40, ownerPID: 400, ownerName: "MenuBar", bounds: CGRect(x: 0, y: 0, width: 200, height: 200), layer: 24),
            candidate(id: 50, ownerPID: 500, ownerName: "Dock", bounds: CGRect(x: 0, y: 0, width: 200, height: 200), layer: 25)
        ]

        let result = WindowStackFilter.allWindows(
            from: windows,
            monitorScope: .currentMonitor,
            screenBounds: screen,
            excludingOwnerNames: []
        )

        #expect(result.map(\.cgWindowID) == [10, 20, 30] as [CGWindowID])
    }

    @Test("appWindows can be limited to current monitor")
    func appWindowsCanBeLimitedToCurrentMonitor() {
        let windows = [
            candidate(id: 10, ownerPID: 100, ownerName: "Target", bounds: CGRect(x: 0, y: 0, width: 200, height: 200)),
            candidate(id: 20, ownerPID: 100, ownerName: "Target", bounds: CGRect(x: 2000, y: 0, width: 200, height: 200)),
            candidate(id: 30, ownerPID: 200, ownerName: "Other", bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
        ]

        let result = WindowStackFilter.appWindows(
            from: windows,
            ownerPIDs: [100],
            monitorScope: .currentMonitor,
            screenBounds: CGRect(x: 0, y: 0, width: 1000, height: 1000),
            excludingOwnerNames: []
        )

        #expect(result.map(\.cgWindowID) == [10] as [CGWindowID])
    }

    @Test("appWindows can include all monitors")
    func appWindowsCanIncludeAllMonitors() {
        let windows = [
            candidate(id: 10, ownerPID: 100, ownerName: "Target", bounds: CGRect(x: 0, y: 0, width: 200, height: 200)),
            candidate(id: 20, ownerPID: 100, ownerName: "Target", bounds: CGRect(x: 2000, y: 0, width: 200, height: 200)),
            candidate(id: 30, ownerPID: 200, ownerName: "Other", bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
        ]

        let result = WindowStackFilter.appWindows(
            from: windows,
            ownerPIDs: [100],
            monitorScope: .allMonitors,
            screenBounds: CGRect(x: 0, y: 0, width: 1000, height: 1000),
            excludingOwnerNames: []
        )

        #expect(result.map(\.cgWindowID) == [10, 20] as [CGWindowID])
    }

    private func candidate(
        id: CGWindowID,
        ownerPID: pid_t,
        ownerName: String,
        bounds: CGRect,
        layer: Int = 0,
        alpha: Double = 1
    ) -> WindowCandidate {
        WindowCandidate(
            cgWindowID: id,
            ownerPID: ownerPID,
            ownerName: ownerName,
            windowTitle: nil,
            bounds: bounds,
            layer: layer,
            alpha: alpha
        )
    }
}
