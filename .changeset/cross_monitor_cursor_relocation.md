---
default: patch
---

Fix window stack not refreshing when cursor crosses monitors during active session. Remove `.underCursor`-only guard from cursor relocation refresh so all scope types update candidates on cross-monitor movement.
