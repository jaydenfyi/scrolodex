---
default: patch
---

### Standardize desktop switch settings keys

Deleted `SettingKey.DesktopSwitch` enum and `buildDesktopKeyboardNavigation` duplicate. Desktop switch now uses the same catalog-prefix convention as window and dock triggers via `TriggerSettingCatalog.desktopEntries`. No UserDefaults keys changed.
