---
default: patch
---

Fix cursor move: revert sync dispatch to async to prevent AX-I/O hangs, allow single-window candidate refresh during cursor relocation, skip first-move spurious candidate query until a meaningful position is established, and align peek border radius to standard macOS windows (10pt).
