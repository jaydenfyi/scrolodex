---
default: patch
---

### Catalog-driven trigger prefixes

Callers (SettingsView, StatusBarController, TriggerSettingsStore) now reference `TriggerSettingCatalog` entries instead of hardcoding prefix strings. Feature-flagged triggers (sameApp, currentMonitor) added to the catalog with `enabled: false`. `registerDefaults` loops over all entries including feature-flagged. Adding a trigger now requires editing fewer files.
