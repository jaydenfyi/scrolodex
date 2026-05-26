import AppKit
import Dispatch

@MainActor
final class OverlayAnimation {
	private var timer: DispatchSourceTimer?
	private var transitionOffset: CGFloat = 0
	private var targetSize: CGFloat?
	private var animatedSize: CGFloat?

	var onUpdate: (() -> Void)?

	var currentTransitionOffset: CGFloat { transitionOffset }

	var currentAnimatedSize: CGFloat? { animatedSize }

	func setTargetSize(_ target: CGFloat?) {
		targetSize = target
		if animatedSize == nil { animatedSize = target }
		if animatedSize != targetSize {
			ensureTimer()
		}
	}

	func startTransition(offset: CGFloat) {
		transitionOffset = offset
		ensureTimer()
	}

	func resetTransition() {
		transitionOffset = 0
		animatedSize = targetSize
		stopTimer()
	}

	func invalidate() {
		stopTimer()
		targetSize = nil
		animatedSize = nil
		transitionOffset = 0
	}

	private func ensureTimer() {
		guard timer == nil else { return }
		let t = DispatchSource.makeTimerSource(queue: .main)
		t.schedule(deadline: .now(), repeating: .milliseconds(16))
		t.setEventHandler { [weak self] in
			Task { @MainActor [weak self] in
				self?.tick()
			}
		}
		t.resume()
		timer = t
	}

	private func tick() {
		transitionOffset *= 0.72
		if abs(transitionOffset) < 0.01 {
			transitionOffset = 0
		}

		if let target = targetSize, let current = animatedSize {
			let diff = target - current
			if abs(diff) < 0.5 {
				animatedSize = target
			} else {
				animatedSize = current + diff * 0.28
			}
		}

		if transitionOffset == 0 && animatedSize == targetSize {
			stopTimer()
		}
		onUpdate?()
	}

	private func stopTimer() {
		timer?.cancel()
		timer = nil
	}
}
