import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Hotkey configuration")
struct HotkeyConfigurationTests {
    @Test("default scroll at point is Option")
    func defaultScrollAtPoint() {
        let config = HotkeyConfiguration.defaultScrollAtPoint
        #expect(config.flags == [.maskAlternate])
        #expect(config.displayName == "Option")
    }

    @Test("default scroll all windows is Command + Option")
    func defaultScrollAllWindows() {
        let config = HotkeyConfiguration.defaultScrollAllWindows
        #expect(config.flags == [.maskCommand, .maskAlternate])
        #expect(config.displayName == "Command + Option")
    }

    @Test("default desktop switch is Option + Shift")
    func defaultDesktopSwitch() {
        let config = HotkeyConfiguration.defaultDesktopSwitch
        #expect(config.flags == [.maskAlternate, .maskShift])
        #expect(config.displayName == "Option + Shift")
    }

    @Test("matches only when exact modifier flags are present")
    func matchesExactFlags() {
        let hotkey = HotkeyConfiguration(flags: [.maskCommand, .maskAlternate])

        #expect(hotkey.matches([.maskCommand, .maskAlternate]))
        #expect(!hotkey.matches([.maskCommand]))
        #expect(!hotkey.matches([.maskAlternate]))
        #expect(!hotkey.matches([.maskControl, .maskAlternate, .maskShift, .maskCommand]))
    }

    @Test("matches ignores non-modifier flags")
    func matchesIgnoresNonModifiers() {
        let hotkey = HotkeyConfiguration(flags: [.maskCommand, .maskAlternate])
        #expect(hotkey.matches([.maskCommand, .maskAlternate, .maskSecondaryFn]))
    }

    @Test("display name shows None for empty flags")
    func displayNameEmpty() {
        let config = HotkeyConfiguration(flags: [])
        #expect(config.displayName == "None")
    }

    @Test("init from raw value")
    func initFromRawValue() {
        let raw: UInt64 = CGEventFlags([.maskCommand, .maskAlternate]).rawValue
        let config = HotkeyConfiguration(rawValue: raw)
        #expect(config.flags == [.maskCommand, .maskAlternate])
    }

    @Test("three modifier combo matches only exact three modifiers")
    func threeModifierCombo() {
        let hotkey = HotkeyConfiguration(flags: [.maskCommand, .maskAlternate, .maskControl])
        #expect(hotkey.matches([.maskCommand, .maskAlternate, .maskControl]))
        #expect(!hotkey.matches([.maskCommand, .maskAlternate, .maskControl, .maskShift]))
        #expect(!hotkey.matches([.maskCommand, .maskAlternate]))
    }

    @Suite("active hold matching")
    struct ActiveHoldMatchingTests {
        @Test("exact modifier match remains active")
        func exactMatchIsSubset() {
            let hotkey = HotkeyConfiguration(flags: [.maskCommand, .maskAlternate])
            #expect(hotkey.isSubsetOf([.maskCommand, .maskAlternate]))
        }

        @Test("extra modifier flags deactivate the hotkey")
        func extraModifiersDeactivateHotkey() {
            let hotkey = HotkeyConfiguration(flags: [.maskCommand, .maskAlternate])
            #expect(!hotkey.isSubsetOf([.maskCommand, .maskAlternate, .maskControl]))
            #expect(!hotkey.isSubsetOf([.maskCommand, .maskAlternate, .maskShift]))
            #expect(!hotkey.isSubsetOf([.maskCommand, .maskAlternate, .maskControl, .maskShift]))
        }

        @Test("partial flags are not a subset")
        func partialIsNotSubset() {
            let hotkey = HotkeyConfiguration(flags: [.maskCommand, .maskAlternate])
            #expect(!hotkey.isSubsetOf([.maskCommand]))
            #expect(!hotkey.isSubsetOf([.maskAlternate]))
        }

        @Test("unrelated flags are not a subset")
        func unrelatedIsNotSubset() {
            let hotkey = HotkeyConfiguration(flags: [.maskCommand, .maskAlternate])
            #expect(!hotkey.isSubsetOf([.maskControl, .maskShift]))
        }

        @Test("ignores non-modifier flags")
        func ignoresNonModifiers() {
            let hotkey = HotkeyConfiguration(flags: [.maskCommand, .maskAlternate])
            #expect(hotkey.isSubsetOf([.maskCommand, .maskAlternate, .maskSecondaryFn]))
        }

        @Test("empty flags only match empty modifiers")
        func emptyIsSubsetOfAll() {
            let hotkey = HotkeyConfiguration(flags: [])
            #expect(!hotkey.isSubsetOf([.maskCommand]))
            #expect(hotkey.isSubsetOf([]))
        }
    }
}
