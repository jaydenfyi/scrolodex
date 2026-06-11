---
default: patch
---

Recover disabled Gesture Trigger HID taps by re-enabling the existing tap, health-checking after disable callbacks, and retrying tap creation if setup fails. Stop the gesture observer during pause and permission revocation so its lifecycle stays aligned with the main event tap.
