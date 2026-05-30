---
default: minor
---

### Extract `ScrolodexSettings` module

Moved all UserDefaults-based settings assembly out of `AppDelegate` into a new `ScrolodexSettings` target. `UserDefaultsRuntimeConfigurationReader.read()` returns a single `RuntimeConfiguration` value, collapsing ~200 lines of duplicated builder methods into one 189-line reader with shared helpers (`PerTriggerSettings`, unified `buildKeyBinding`). `DockHoverConfiguration` is now a pure domain type with no `Foundation` import. `SettingKey` and `RuntimeAppearanceSettings` moved to the new module. `TriggerSettingCatalog` centralizes shipped trigger entries.
