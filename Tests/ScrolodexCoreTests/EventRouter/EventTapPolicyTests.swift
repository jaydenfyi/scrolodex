import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Event tap policy")
struct EventTapPolicyTests {
    @Test("does not consume key up events")
    func doesNotHandleKeyUp() {
        #expect(EventTapPolicy.observedEventTypes.contains(.keyUp) == false)
        #expect(EventTapPolicy.action(for: .keyUp, triggerHeld: true, permissionsAvailable: true) == .passThrough)
    }

    @Test("mouseMoved is observed and routes to handleCursorMove when trigger held")
    func mouseMovedRoutesToHandleCursorMove() {
        #expect(EventTapPolicy.observedEventTypes.contains(.mouseMoved) == true)
        #expect(
            EventTapPolicy.action(for: .mouseMoved, triggerHeld: true, permissionsAvailable: true)
            == .handleCursorMove)
        #expect(
            EventTapPolicy.action(for: .mouseMoved, triggerHeld: false, permissionsAvailable: true)
            == .passThrough)
    }

    @Test("mouseMoved passes through when permissions unavailable")
    func mouseMovedPassesThroughWithoutPermissions() {
        #expect(
            EventTapPolicy.action(for: .mouseMoved, triggerHeld: true, permissionsAvailable: false)
            == .passThrough)
    }

    @Test("consumes trigger scroll, passes through trigger click")
    func triggerPointerActions() {
        #expect(EventTapPolicy.action(for: .scrollWheel, triggerHeld: true, permissionsAvailable: true) == .handleScroll)
        #expect(EventTapPolicy.action(for: .leftMouseDown, triggerHeld: true, permissionsAvailable: true) == .handleClickConfirm)
        #expect(EventTapPolicy.action(for: .scrollWheel, triggerHeld: false, permissionsAvailable: true) == .passThrough)
    }

    @Test("passes through trigger events when required permissions are unavailable")
    func passesThroughWhenPermissionsUnavailable() {
        #expect(EventTapPolicy.action(for: .flagsChanged, triggerHeld: true, permissionsAvailable: false) == .passThrough)
        #expect(EventTapPolicy.action(for: .scrollWheel, triggerHeld: true, permissionsAvailable: false) == .passThrough)
        #expect(EventTapPolicy.action(for: .leftMouseDown, triggerHeld: true, permissionsAvailable: false) == .passThrough)
    }

    @Test("does not re-enable a disabled tap when permissions are unavailable")
    func doesNotReenableDisabledTapWithoutPermissions() {
        #expect(EventTapPolicy.action(for: .tapDisabledByUserInput, triggerHeld: false, permissionsAvailable: false) == .passThrough)
        #expect(EventTapPolicy.action(for: .tapDisabledByTimeout, triggerHeld: false, permissionsAvailable: false) == .passThrough)
    }

    @Test("keyDown matching forward binding returns handleKeyNavigate direction 1")
    func keyDownMatchesForwardBinding() {
        let forward = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskAlternate], keyCode: 49)
        let result = EventTapPolicy.action(
            for: .keyDown,
            eventFlags: [.maskCommand, .maskAlternate],
            eventKeyCode: 49,
            triggerHeld: false,
            keyboardBindings: [forward],
            permissionsAvailable: true
        )
        #expect(result == .handleKeyNavigate(direction: 1))
    }

    @Test("non-matching keyDown passes through")
    func keyDownPassesThroughNonMatching() {
        let forward = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskAlternate], keyCode: 49)
        let result = EventTapPolicy.action(
            for: .keyDown,
            eventFlags: [.maskCommand],
            eventKeyCode: 49,
            triggerHeld: false,
            keyboardBindings: [forward],
            permissionsAvailable: true
        )
        #expect(result == .passThrough)
    }

    @Test("keyDown passes through when no bindings configured")
    func keyDownPassesThroughEmptyBindings() {
        let result = EventTapPolicy.action(
            for: .keyDown,
            eventFlags: [.maskCommand, .maskAlternate],
            eventKeyCode: 49,
            triggerHeld: false,
            keyboardBindings: [],
            permissionsAvailable: true
        )
        #expect(result == .passThrough)
    }

    @Test("keyDown passes through when permissions unavailable")
    func keyDownPassesThroughWithoutPermissions() {
        let forward = KeyboardHotkeyConfiguration(flags: [.maskCommand], keyCode: 49)
        let result = EventTapPolicy.action(
            for: .keyDown,
            eventFlags: [.maskCommand],
            eventKeyCode: 49,
            triggerHeld: false,
            keyboardBindings: [forward],
            permissionsAvailable: false
        )
        #expect(result == .passThrough)
    }

    @Test("keyDown with extra modifiers does not match binding requiring exact modifiers")
    func keyDownExtraModifiersNoMatch() {
        let binding = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskAlternate], keyCode: 49)
        let result = EventTapPolicy.action(
            for: .keyDown,
            eventFlags: [.maskCommand, .maskAlternate, .maskControl],
            eventKeyCode: 49,
            triggerHeld: true,
            keyboardBindings: [binding],
            permissionsAvailable: true
        )
        #expect(result == .passThrough)
    }

    @Test("keyDown passes through when binding from different trigger is not in scoped list")
    func keyDownScopedBindings() {
        let triggerABinding = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskAlternate], keyCode: 49)
        let triggerBBinding = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskAlternate, .maskControl], keyCode: 49)
        let scopedBindings = [triggerABinding]
        let result = EventTapPolicy.action(
            for: .keyDown,
            eventFlags: [.maskCommand, .maskAlternate, .maskControl],
            eventKeyCode: 49,
            triggerHeld: true,
            keyboardBindings: scopedBindings,
            permissionsAvailable: true
        )
        #expect(result == .passThrough)
    }
}
