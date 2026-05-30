---
default: patch
---

### Catalog-driven `registerDefaults`

`TriggerSettingCatalogEntry` now carries `enabled` and `keyboardNavDefaults`, making the catalog the single source of truth for trigger defaults. `registerDefaults` loops over catalog entries instead of hardcoding 40 lines of prefix/value pairs. Adding a new trigger now only requires editing the catalog.
