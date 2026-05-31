---
default: patch
---

Fix Desktop Switch targeting the focused display instead of the display under the cursor. Space metadata now resolves per display, no-op boundaries keep showing the current Desktop label, and synthesized Dock swipe events carry the cursor location.
