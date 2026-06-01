---
default: patch
---

Collapse duplicate `releaseGesture`/`cancelGesture` cleanup paths into a single `endGesture` method so gesture session state stays in sync.
