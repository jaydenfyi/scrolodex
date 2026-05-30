---
default: patch
---

Fix cursor move overlay appearing before first scroll when `showOnPress` is disabled. Clear `lastCandidateCursor` on session end to prevent stale state leaking across trigger activations.
