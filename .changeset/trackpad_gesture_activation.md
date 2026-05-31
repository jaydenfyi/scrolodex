---
default: patch
---

Fix Trackpad Gesture activation by observing the full gesture event lifecycle and counting stationary fingers that remain down during a swipe.
