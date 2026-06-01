---
default: patch
---

Fix Trackpad Gesture session lifecycle: stateful touch tracking keeps sessions alive through finger-count transitions (partial lift), extra-finger touch cancels the session immediately, and deferred 80ms release handles ambiguous empty snapshots during transitions.
