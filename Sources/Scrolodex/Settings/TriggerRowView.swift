import ScrolodexCore
import SwiftUI

struct TriggerRowView: View {
	let id: String
	let icon: String
	let iconColor: Color
	let title: String
	let subtitle: String
	let includeMonitorScope: Bool
	let allOtherFlags: CGEventFlags
	var globallyDisabled: Bool = false
	@Bindable var store: TriggerSettingsStore
	@Binding var expandedSettingsCard: String?
	@Binding var expandedAdvancedCards: Set<String>
	@Binding var recordingField: String?
	@Binding var liveModifierFlags: NSEvent.ModifierFlags
	var onStartRecording: (String, Binding<Double>, Binding<Double>) -> Void
	var onEndRecording: () -> Void

	var body: some View {
		let effectiveEnabled = !globallyDisabled && store.enabled
		let summary = SettingsTriggerSummary(
			enabled: effectiveEnabled,
			flags: UInt64(store.flags),
			overlayMode: OverlayPresentationMode(rawValue: store.overlay) ?? .default,
			monitorScope: includeMonitorScope
				? MonitorScope(rawValue: store.monitorScope) ?? .currentMonitor : nil,
			keyboardNavigationEnabled: store.kbNavEnabled
		)

		VStack(spacing: 0) {
			Button {
				withAnimation(.easeOut(duration: 0.16)) {
					expandedSettingsCard = expandedSettingsCard == id ? nil : id
				}
			} label: {
				SettingsRow(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle) {
					settingsMiniChips(summary.compactChips)
						.layoutPriority(1)
					Toggle("", isOn: Binding(
						get: { effectiveEnabled },
						set: { _, _ in }
					))
						.toggleStyle(.switch)
						.labelsHidden()
						.allowsHitTesting(false)
						.overlay {
							Color.clear.contentShape(Rectangle())
								.onTapGesture {
									guard !globallyDisabled else { return }
									store.enabled.toggle()
								}
							}
				}
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)

			if expandedSettingsCard == id {
				editorControls
					.padding(.leading, 42)
					.padding(.trailing, 12)
					.padding(.bottom, 10)
					.transition(.opacity)
			}
		}
	}

	private var editorControls: some View {
		VStack(alignment: .leading, spacing: 10) {
			modifierPillsSection

			HStack(spacing: 14) {
				VStack(alignment: .leading, spacing: 4) {
					SettingsFieldLabel("Overlay")
					Picker("Overlay", selection: $store.overlay) {
						ForEach(OverlayPresentationMode.allCases, id: \.rawValue) { mode in
							Text(mode.displayName).tag(mode.rawValue)
						}
					}
					.labelsHidden()
				}

				if includeMonitorScope {
					VStack(alignment: .leading, spacing: 4) {
						SettingsFieldLabel("Windows")
						Picker("Windows", selection: $store.monitorScope) {
							ForEach(MonitorScope.allCases, id: \.rawValue) { scope in
								Text(scope.displayName).tag(scope.rawValue)
							}
						}
						.labelsHidden()
					}
				}
			}

			advancedDisclosureHeader

			if isAdvancedExpanded {
				advancedControls
					.padding(.top, 4)
					.transition(.opacity)
			}
		}
	}

	private var isAdvancedExpanded: Bool {
		expandedAdvancedCards.contains(id)
	}

	private var advancedDisclosureHeader: some View {
		settingsAdvancedDisclosureHeader(isExpanded: isAdvancedExpanded) {
			if isAdvancedExpanded {
				expandedAdvancedCards.remove(id)
			} else {
				expandedAdvancedCards.insert(id)
			}
		}
	}

	private var modifierPillsSection: some View {
		VStack(alignment: .leading, spacing: 4) {
			SettingsFieldLabel("Trigger keys")
			HStack(spacing: 6) {
				ModifierPill(
					label: "⌘",
					isOn: store.flags != 0
						&& CGEventFlags(rawValue: UInt64(store.flags)).contains(.maskCommand)
				) { toggleModifier(.maskCommand) }
				ModifierPill(
					label: "⌥",
					isOn: store.flags != 0
						&& CGEventFlags(rawValue: UInt64(store.flags)).contains(.maskAlternate)
				) { toggleModifier(.maskAlternate) }
				ModifierPill(
					label: "⌃",
					isOn: store.flags != 0
						&& CGEventFlags(rawValue: UInt64(store.flags)).contains(.maskControl)
				) { toggleModifier(.maskControl) }
				ModifierPill(
					label: "⇧",
					isOn: store.flags != 0
						&& CGEventFlags(rawValue: UInt64(store.flags)).contains(.maskShift)
				) { toggleModifier(.maskShift) }
			}

			if !allOtherFlags.isEmpty && store.flags == Double(allOtherFlags.rawValue) {
				Text("Same as another trigger")
					.font(.caption)
					.foregroundStyle(.red)
			} else if store.flags == 0 {
				Text("Select at least one modifier")
					.font(.caption)
					.foregroundStyle(.orange)
			}
		}
	}

	private func toggleModifier(_ flag: CGEventFlags) {
		var current = CGEventFlags(rawValue: UInt64(store.flags))
		if current.contains(flag) {
			current.remove(flag)
		} else {
			current.insert(flag)
		}
		store.flags = Double(current.rawValue)
	}

	private var advancedControls: some View {
		VStack(alignment: .leading, spacing: 0) {
			settingsSubgroup {
				settingToggleRow("Show overlay on trigger press", isOn: $store.showOnPress)
				Divider()
				settingToggleRow("Invert scroll direction", isOn: $store.invertDirection)
			}

			SettingsIndentedDivider(leading: 10, vertical: 3)

			settingsSubgroup {
				settingToggleRow("Keyboard navigation", isOn: $store.kbNavEnabled)

				if store.kbNavEnabled {
					Divider()
					keyBindingRow(
						label: "Forward", bindingFlags: $store.kbNavForwardFlags,
						bindingKeyCode: $store.kbNavForwardKeyCode, fieldId: "\(id).forward")
					Divider()
					keyBindingRow(
						label: "Backward", bindingFlags: $store.kbNavBackwardFlags,
						bindingKeyCode: $store.kbNavBackwardKeyCode, fieldId: "\(id).backward")
				}
			}

			SettingsIndentedDivider(leading: 10, vertical: 3)

			settingsSubgroup {
				HStack(spacing: 12) {
					Text("Trackpad Gesture")
						.font(.caption)
						.foregroundStyle(.secondary)
					Spacer()
					Picker("", selection: $store.gesture) {
						Text("None").tag(0)
						ForEach(TrackpadFingerCount.allCases, id: \.rawValue) { count in
							Text(count.displayName).tag(count.rawValue)
						}
					}
					.frame(width: 180)
					.labelsHidden()
				}
				.padding(.vertical, 4)
			}
		}
	}

	private func keyBindingRow(
		label: String, bindingFlags: Binding<Double>, bindingKeyCode: Binding<Double>, fieldId: String
	) -> some View {
		settingsKeyBindingRow(
			label: label, bindingFlags: bindingFlags, bindingKeyCode: bindingKeyCode
		) {
			keyRecorder(flags: bindingFlags, keyCode: bindingKeyCode, fieldId: fieldId)
		}
	}

	private func keyRecorder(flags: Binding<Double>, keyCode: Binding<Double>, fieldId: String) -> some View {
		let config = KeyboardHotkeyConfiguration(
			flags: CGEventFlags(rawValue: UInt64(flags.wrappedValue)),
			keyCode: CGKeyCode(keyCode.wrappedValue)
		)
		let isRecording = recordingField == fieldId
		let hasBinding = flags.wrappedValue != 0 || keyCode.wrappedValue != 0

		var liveLabel: String {
			if !isRecording { return hasBinding ? config.compactDisplayName : "None" }
			let flags = CGEventFlags(rawValue: UInt64(liveModifierFlags.rawValue))
			return KeyboardHotkeyConfiguration.compactModifierDisplayName(from: flags)
				.map { "\($0)…" } ?? "Press key combination…"
		}

		return Button(action: {
			onStartRecording(fieldId, flags, keyCode)
		}) {
			Text(liveLabel)
				.font(.caption)
				.frame(minWidth: 80)
		}
		.buttonStyle(.bordered)
		.disabled(isRecording)
	}

	private func settingToggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
		settingsToggleRow(title, isOn: isOn)
	}
}

struct ModifierPill: View {
	let label: String
	let isOn: Bool
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			Text(label)
				.font(.system(size: 13, weight: .medium))
				.padding(.horizontal, 10)
				.padding(.vertical, 5)
				.background(
					isOn
						? Color.accentColor.opacity(0.12)
						: Color(nsColor: .controlBackgroundColor)
				)
				.foregroundStyle(isOn ? Color.accentColor : .primary)
				.clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
				.overlay(
					RoundedRectangle(cornerRadius: 7, style: .continuous)
						.stroke(
							isOn
								? Color.accentColor.opacity(0.3)
								: Color.secondary.opacity(0.2))
				)
		}
		.buttonStyle(.plain)
	}
}
