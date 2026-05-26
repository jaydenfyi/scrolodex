import CoreGraphics
import Foundation
import Testing
@testable import ScrolodexCore

@Suite("Dock hover configuration")
struct DockHoverConfigurationTests {
    @Test("default configuration values")
    func defaultValues() {
        let config = DockHoverConfiguration()
        #expect(!config.enabled)
        #expect(config.modifierFlags == CGEventFlags.maskAlternate.rawValue)
        #expect(config.monitorScope == .currentMonitor)
    }

    @Test("modifier matches when flag is present")
    func modifierMatches() {
        let config = DockHoverConfiguration(modifierFlags: CGEventFlags.maskAlternate.rawValue)
        #expect(config.modifierMatches(.maskAlternate))
        #expect(!config.modifierMatches(.maskCommand))
    }

    @Test("from user defaults with overrides")
    func fromUserDefaultsOverrides() {
        let defaults = UserDefaults.standard
        let prefix = "test.dockHover"
        defaults.set(true, forKey: "\(prefix).enabled")
        defaults.set(Double(CGEventFlags.maskControl.rawValue), forKey: "\(prefix).flags")
        defaults.set(MonitorScope.allMonitors.rawValue, forKey: "\(prefix).monitorScope")

        let config = DockHoverConfiguration.fromUserDefaults(prefix: prefix)
        #expect(config.enabled)
        #expect(config.modifierFlags == CGEventFlags.maskControl.rawValue)
        #expect(config.monitorScope == .allMonitors)

        for key in ["enabled", "flags", "monitorScope"] {
            defaults.removeObject(forKey: "\(prefix).\(key)")
        }
    }

    @Test("from user defaults falls back to defaults when empty")
    func fromUserDefaultsFallbacks() {
        let prefix = "test.dockHover.empty"
        let config = DockHoverConfiguration.fromUserDefaults(prefix: prefix)
        #expect(!config.enabled)
        #expect(config.modifierFlags == CGEventFlags.maskAlternate.rawValue)
        #expect(config.monitorScope == .currentMonitor)
    }

    @Test("from user defaults can override fallback monitor scope")
    func fromUserDefaultsUsesFallbackMonitorScope() {
        let config = DockHoverConfiguration.fromUserDefaults(prefix: "test.dockHover.fallback", defaultMonitorScope: .allMonitors)

        #expect(config.monitorScope == .allMonitors)
    }

    @Test("migration from old prefix copies keys")
    func migrationFromOldPrefix() {
        let defaults = UserDefaults.standard
        let old = "test.dockHover.migrate.old"
        let new = "test.dockHover.migrate.new"

        defaults.set(true, forKey: "\(old).enabled")
        defaults.set(Double(CGEventFlags.maskControl.rawValue), forKey: "\(old).modifierFlags")
        defaults.set(false, forKey: "\(old).showOnPress")

        let config = DockHoverConfiguration.fromUserDefaults(
            prefix: new, defaultMonitorScope: .allMonitors, migrationPrefix: old)
        #expect(config.enabled)
        #expect(config.modifierFlags == CGEventFlags.maskControl.rawValue)
        #expect(!config.showOnPress)

        for key in ["enabled", "modifierFlags", "showOnPress"] {
            defaults.removeObject(forKey: "\(old).\(key)")
        }
        for key in ["enabled", "flags", "showOnPress"] {
            defaults.removeObject(forKey: "\(new).\(key)")
        }
    }
}
