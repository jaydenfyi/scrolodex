import Testing
@testable import ScrolodexCore

@Suite("Keyboard navigation binding")
struct KeyboardNavigationBindingTests {
    private let forward = KeyboardHotkeyConfiguration(flags: .maskCommand, keyCode: 49)
    private let backward = KeyboardHotkeyConfiguration(flags: .maskCommand, keyCode: 48)

    @Test("allBindings empty when disabled")
    func emptyWhenDisabled() {
        let binding = KeyboardNavigationBinding(enabled: false, forward: forward, backward: backward)
        #expect(binding.allBindings == [])
    }

    @Test("allBindings returns forward then backward when enabled with both")
    func forwardThenBackward() {
        let binding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: backward)
        #expect(binding.allBindings == [forward, backward])
    }

    @Test("allBindings returns forward only when backward is nil")
    func forwardOnly() {
        let binding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
        #expect(binding.allBindings == [forward])
    }

    @Test("allBindings empty when enabled but no bindings set")
    func enabledButEmpty() {
        let binding = KeyboardNavigationBinding(enabled: true, forward: nil, backward: nil)
        #expect(binding.allBindings == [])
    }
}
