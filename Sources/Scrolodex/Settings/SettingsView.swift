import ApplicationServices
import CoreGraphics
import ScrolodexCore
import ScrolodexSettings
import ServiceManagement
import SwiftUI

struct SettingsView: View {
	@State private var launchAtLogin = SMAppService.mainApp.status == .enabled
	@State private var accessibilityGranted = AXIsProcessTrusted()
	@State private var screenRecordingGranted = CGPreflightScreenCaptureAccess()
	@State private var permissionPollTimer: Timer?
	@State private var expandedSettingsCard: String?
	@State private var expandedAdvancedCards: Set<String> = []

	private var appVersion: String {
		Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
	}

	@AppStorage(SettingKey.scrollSensitivity) private var scrollSensitivity: Double = SettingDefaults.scrollSensitivity
	@AppStorage(SettingKey.theme) private var theme: String = SettingDefaults.theme.rawValue
	@AppStorage(SettingKey.animate) private var animate: Bool = SettingDefaults.animate
	@AppStorage(SettingKey.wrapAround) private var wrapAround: Bool = SettingDefaults.wrapAround
	@AppStorage(SettingKey.peekEnabled) private var peekEnabled: Bool = SettingDefaults.peekEnabled
	@AppStorage(SettingKey.peekOpacity) private var peekOpacity: Double = SettingDefaults.peekOpacity
	@AppStorage(SettingKey.disabled) private var globallyDisabled: Bool = false

	@State private var trigger1 = TriggerSettingsStore(
		entry: TriggerSettingCatalog.windowEntries[0], defaultHotkey: .defaultScrollAtPoint)
	@State private var trigger2 = TriggerSettingsStore(
		entry: TriggerSettingCatalog.windowEntries[1], defaultHotkey: .defaultScrollAllWindows)
	@State private var trigger3 = TriggerSettingsStore(
		entry: TriggerSettingCatalog.featureFlaggedEntries[0])
	@State private var trigger4 = TriggerSettingsStore(
		entry: TriggerSettingCatalog.featureFlaggedEntries[1])

	@State private var dockHoverCurrent = TriggerSettingsStore(
		entry: TriggerSettingCatalog.featureFlaggedEntries[2], defaultHotkey: .init(flags: .maskAlternate))
	@State private var dockHoverAll = TriggerSettingsStore(
		entry: TriggerSettingCatalog.dockHoverEntries[0], defaultHotkey: .init(flags: .maskAlternate),
		migrationPrefix: "dockHover")

	@AppStorage("desktopSwitch.enabled") private var desktopSwitchEnabled: Bool = SettingDefaults.desktopSwitchEnabled
	@AppStorage("desktopSwitch.flags") private var desktopSwitchFlags: Double = Double(
		HotkeyConfiguration.defaultDesktopSwitch.flags.rawValue)
	@AppStorage("desktopSwitch.invertDirection") private var desktopSwitchInvertDirection: Bool = false
	@AppStorage("desktopSwitch.animate") private var desktopSwitchAnimate: Bool = SettingDefaults.desktopSwitchAnimate
	@AppStorage("desktopSwitch.wrapAround") private var desktopSwitchWrapAround: Bool = SettingDefaults.desktopSwitchWrapAround
	@AppStorage("desktopSwitch.keyboardNav.enabled") private var desktopSwitchKbNavEnabled: Bool = SettingDefaults.desktopSwitchKeyboardNavEnabled
	@AppStorage("desktopSwitch.keyboardNav.forwardFlags") private var desktopSwitchKbNavForwardFlags:
		Double = 0
	@AppStorage("desktopSwitch.keyboardNav.forwardKeyCode") private var desktopSwitchKbNavForwardKeyCode:
		Double = 0
	@AppStorage("desktopSwitch.keyboardNav.backwardFlags") private var desktopSwitchKbNavBackwardFlags:
		Double = 0
	@AppStorage("desktopSwitch.keyboardNav.backwardKeyCode") private var desktopSwitchKbNavBackwardKeyCode:
		Double = 0


	private let sensitivityRange: ClosedRange<Double> = 1...20

	@State private var recordingField: String? = nil
	@State private var keyMonitor: Any? = nil
	@State private var flagsMonitor: Any? = nil
	@State private var liveModifierFlags: NSEvent.ModifierFlags = []

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 20) {
				if !(accessibilityGranted && screenRecordingGranted) {
					permissionsBanner
				}
				generalGroup
				triggersGroup
				appearanceGroup

				HStack {
					Spacer()
					Text("Scrolodex \(appVersion)")
						.font(.caption)
						.foregroundStyle(.tertiary)
				}
			}
			.padding(20)
		}
		.frame(width: 560)
		.onAppear { startPermissionPolling() }
		.onDisappear {
			permissionPollTimer?.invalidate()
			endRecording()
		}
	}

	private var permissionsBanner: some View {
		VStack(alignment: .leading, spacing: 10) {
			HStack(spacing: 10) {
				Image(systemName: "exclamationmark.shield.fill")
					.font(.title3)
					.foregroundStyle(.orange)
				VStack(alignment: .leading, spacing: 2) {
					Text("Permissions Required")
						.font(.headline)
					Text("Scrolodex needs these once to see windows and show previews.")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				Spacer()
			}

			VStack(spacing: 6) {
				permissionRow(
					title: "Accessibility",
					subtitle: "Lets Scrolodex detect hotkeys and focus windows",
					granted: accessibilityGranted,
					request: requestAccessibility,
					openSettings: permissions.openAccessibilitySettings
				)

				permissionRow(
					title: "Screen Recording",
					subtitle: "Lets Scrolodex show window previews",
					granted: screenRecordingGranted,
					request: requestScreenRecording,
					openSettings: permissions.openScreenRecordingSettings
				)
			}
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.fill(Color(nsColor: .controlBackgroundColor))
		)
		.overlay(
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.stroke(Color.secondary.opacity(0.12))
		)
	}

	private func permissionRow(
		title: String,
		subtitle: String,
		granted: Bool,
		request: @escaping () -> Void,
		openSettings: @escaping () -> Void
	) -> some View {
		HStack(spacing: 8) {
			Circle()
				.fill(granted ? Color.green : Color.orange)
				.frame(width: 7, height: 7)
			VStack(alignment: .leading, spacing: 1) {
				Text(title)
					.font(.caption.weight(.semibold))
				Text(granted ? "Granted" : subtitle)
					.font(.caption2)
					.foregroundStyle(.secondary)
			}
			Spacer()
			if granted {
				Text("Granted")
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
			} else {
				Button("Request", action: request)
					.controlSize(.small)
				Button("Settings", action: openSettings)
					.buttonStyle(.plain)
					.font(.caption.weight(.medium))
					.foregroundStyle(.blue)
			}
		}
		.padding(.vertical, 3)
	}

	private var triggersGroup: some View {
		VStack(alignment: .leading, spacing: 0) {
			SettingsSectionHeader("Triggers") {
				Toggle("", isOn: Binding(
					get: { !globallyDisabled },
					set: { globallyDisabled = !$0 }
				))
				.toggleStyle(.switch)
				.controlSize(.small)
				.labelsHidden()
			}

			groupedContainer {
				TriggerRowView(
					id: "windowsUnderCursor",
					icon: "cursorarrow",
					iconColor: .purple,
					title: "Windows Under Cursor",
					subtitle: "Cycle windows beneath the pointer",
					includeMonitorScope: false,
					allOtherFlags: allOtherFlagsForTrigger(excluding: trigger1),
					globallyDisabled: globallyDisabled,
					store: trigger1,
					expandedSettingsCard: $expandedSettingsCard,
					expandedAdvancedCards: $expandedAdvancedCards,
					recordingField: $recordingField,
					liveModifierFlags: $liveModifierFlags,
					onStartRecording: { fieldId, flags, keyCode in
						startRecording(fieldId: fieldId, flags: flags, keyCode: keyCode)
					},
					onEndRecording: endRecording
				)

				groupedDivider()

				TriggerRowView(
					id: "allWindowsOnScreen",
					icon: "rectangle.on.rectangle",
					iconColor: .purple,
					title: "All Windows",
					subtitle: "Cycle every visible window",
					includeMonitorScope: true,
					allOtherFlags: allOtherFlagsForTrigger(excluding: trigger2),
					globallyDisabled: globallyDisabled,
					store: trigger2,
					expandedSettingsCard: $expandedSettingsCard,
					expandedAdvancedCards: $expandedAdvancedCards,
					recordingField: $recordingField,
					liveModifierFlags: $liveModifierFlags,
					onStartRecording: { fieldId, flags, keyCode in
						startRecording(fieldId: fieldId, flags: flags, keyCode: keyCode)
					},
					onEndRecording: endRecording
				)

				groupedDivider()

				// Feature flag: dock simplified to single option with monitor scope picker
				TriggerRowView(
					id: "dockAll",
					icon: "dock.rectangle",
					iconColor: .teal,
					title: "Dock Windows",
					subtitle: "Cycle Dock app windows by scrolling",
					includeMonitorScope: true,
					allOtherFlags: allOtherFlagsForDockHover(excluding: dockHoverAll),
					globallyDisabled: globallyDisabled,
					store: dockHoverAll,
					expandedSettingsCard: $expandedSettingsCard,
					expandedAdvancedCards: $expandedAdvancedCards,
					recordingField: $recordingField,
					liveModifierFlags: $liveModifierFlags,
					onStartRecording: { fieldId, flags, keyCode in
						startRecording(fieldId: fieldId, flags: flags, keyCode: keyCode)
					},
					onEndRecording: endRecording
				)

				groupedDivider()

				desktopRow
			}
			.opacity(globallyDisabled ? 0.45 : 1)
			.allowsHitTesting(!globallyDisabled)
		}
		.onChange(of: globallyDisabled) { _, newValue in
			if newValue {
				expandedSettingsCard = nil
				expandedAdvancedCards.removeAll()
			}
		}
	}

	private var appearanceGroup: some View {
		VStack(alignment: .leading, spacing: 0) {
			SettingsSectionHeader("Appearance")

			groupedContainer {
				SettingsRow(icon: "paintbrush", iconColor: .purple, title: "Theme") {
					Picker("", selection: $theme) {
						ForEach(OverlayTheme.allCases, id: \.rawValue) { t in
							Text(t.displayName).tag(t.rawValue)
						}
					}
					.frame(width: 140)
					.labelsHidden()
				}

				groupedDivider()

				SettingsRow(icon: "eye", iconColor: .blue, title: "Show Window Preview") {
					Toggle("", isOn: $peekEnabled)
						.toggleStyle(.switch)
						.labelsHidden()
				}

				if peekEnabled {
					groupedDivider()

					SettingsRow(icon: "circle.lefthalf.filled", iconColor: .blue, title: "Window Preview Opacity") {
						Slider(value: $peekOpacity, in: 0.5...1)
							.frame(width: 120)
						Text("\(Int((peekOpacity * 100).rounded()))%")
							.monospacedDigit()
							.font(.body)
							.foregroundStyle(.secondary)
							.frame(width: 38, alignment: .trailing)
					}
				}

				groupedDivider()

				SettingsRow(icon: "arrow.triangle.2.circlepath", iconColor: .green, title: "Animate scrolling") {
					Toggle("", isOn: $animate)
						.toggleStyle(.switch)
						.labelsHidden()
				}

				groupedDivider()

				SettingsRow(icon: "repeat", iconColor: .green, title: "Wrap around") {
					Toggle("", isOn: $wrapAround)
						.toggleStyle(.switch)
						.labelsHidden()
				}
			}
		}
	}

	private var generalGroup: some View {
		VStack(alignment: .leading, spacing: 0) {
			SettingsSectionHeader("General")

			groupedContainer {
				SettingsRow(icon: "power", iconColor: .secondary, title: "Launch at Login") {
					Toggle("", isOn: $launchAtLogin)
						.toggleStyle(.switch)
						.labelsHidden()
				}
				.onChange(of: launchAtLogin) { _, newValue in
					do {
						if newValue {
							try SMAppService.mainApp.register()
						} else {
							try SMAppService.mainApp.unregister()
						}
					} catch {
						launchAtLogin = !newValue
					}
				}

				groupedDivider()

				SettingsRow(icon: "slider.horizontal.3", iconColor: .secondary, title: "Scroll Sensitivity") {
					Slider(value: $scrollSensitivity, in: sensitivityRange, step: 1)
						.frame(width: 120)
					Text("\(Int(scrollSensitivity))")
						.monospacedDigit()
						.font(.body)
						.foregroundStyle(.secondary)
						.frame(width: 24, alignment: .trailing)
				}
			}
		}
	}

	private var desktopRow: some View {
		VStack(spacing: 0) {
			Button {
				withAnimation(.easeOut(duration: 0.16)) {
					expandedSettingsCard =
						expandedSettingsCard == "desktopSwitch" ? nil : "desktopSwitch"
				}
			} label: {
				SettingsRow(
					icon: "rectangle.stack",
					iconColor: .orange,
					title: "Desktop Spaces",
					subtitle: "Switch between Spaces"
				) {
					settingsMiniChips(globallyDisabled ? ["Disabled"] : desktopSwitchSummaryChips)
					Toggle("", isOn: Binding(
						get: { !globallyDisabled && desktopSwitchEnabled },
						set: { _, _ in }
					))
						.toggleStyle(.switch)
						.labelsHidden()
						.allowsHitTesting(false)
						.overlay {
							Color.clear.contentShape(Rectangle())
								.onTapGesture {
									guard !globallyDisabled else { return }
									desktopSwitchEnabled.toggle()
								}
						}
				}
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)

			if expandedSettingsCard == "desktopSwitch" {
				VStack(alignment: .leading, spacing: 10) {
					modifierPills(
						flags: Binding(
							get: { CGEventFlags(rawValue: UInt64(desktopSwitchFlags)) },
							set: { desktopSwitchFlags = Double($0.rawValue) }
						),
						allOtherFlags: allOtherFlagsForDesktop
					)

					settingsSubgroup {
						settingsToggleRow(
							"Invert scroll direction", isOn: $desktopSwitchInvertDirection)
						Divider()
						settingsToggleRow("Animate scrolling", isOn: $desktopSwitchAnimate)
						Divider()
						settingsToggleRow("Wrap around", isOn: $desktopSwitchWrapAround)
					}

					settingsSubgroup {
						settingsToggleRow(
							"Keyboard navigation", isOn: $desktopSwitchKbNavEnabled)

						if desktopSwitchKbNavEnabled {
							Divider()
							settingsKeyBindingRow(
								label: "Forward",
								bindingFlags: $desktopSwitchKbNavForwardFlags,
								bindingKeyCode: $desktopSwitchKbNavForwardKeyCode
							) {
								keyRecorder(
									flags: $desktopSwitchKbNavForwardFlags,
									keyCode: $desktopSwitchKbNavForwardKeyCode,
									fieldId: "Desktop Switching.forward")
							}
							Divider()
							settingsKeyBindingRow(
								label: "Backward",
								bindingFlags: $desktopSwitchKbNavBackwardFlags,
								bindingKeyCode: $desktopSwitchKbNavBackwardKeyCode
							) {
								keyRecorder(
									flags: $desktopSwitchKbNavBackwardFlags,
									keyCode: $desktopSwitchKbNavBackwardKeyCode,
									fieldId: "Desktop Switching.backward")
							}
						}
					}

					Text("Scroll up moves right; scroll down moves left unless inverted.")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				.padding(.leading, 42)
				.padding(.trailing, 12)
				.padding(.bottom, 10)
				.transition(.opacity)
			}
		}
	}

	private func groupedContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
		VStack(spacing: 0) {
			content()
		}
		.background(
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.fill(Color(nsColor: .controlBackgroundColor))
		)
		.overlay(
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.stroke(Color.secondary.opacity(0.12))
		)
		.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
	}

	private func groupedDivider() -> some View {
		SettingsIndentedDivider()
	}

	private var desktopSwitchSummaryChips: [String] {
		guard desktopSwitchEnabled else { return ["Disabled"] }
		var chips = [HotkeyConfiguration(rawValue: UInt64(desktopSwitchFlags)).compactDisplayName]
		chips.append(desktopSwitchAnimate ? "Animated" : "Instant")
		chips.append(desktopSwitchWrapAround ? "Wrap" : "No Wrap")
		if desktopSwitchKbNavEnabled { chips.append("Keys") }
		return chips
	}

	private func modifierCheckboxes(flags: Binding<CGEventFlags>, allOtherFlags: CGEventFlags) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack(spacing: 16) {
				modifierToggle("⌘", flag: .maskCommand, flags: flags)
				modifierToggle("⌥", flag: .maskAlternate, flags: flags)
				modifierToggle("⌃", flag: .maskControl, flags: flags)
				modifierToggle("⇧", flag: .maskShift, flags: flags)
			}

			if !allOtherFlags.isEmpty && flags.wrappedValue == allOtherFlags {
				Text("Same as another trigger")
					.font(.caption)
					.foregroundStyle(.red)
			} else if flags.wrappedValue.isEmpty {
				Text("Select at least one modifier")
					.font(.caption)
					.foregroundStyle(.orange)
			}
		}
	}

	private func modifierToggle(_ label: String, flag: CGEventFlags, flags: Binding<CGEventFlags>) -> some View {
		Toggle(
			label,
			isOn: Binding(
				get: { flags.wrappedValue.contains(flag) },
				set: { isOn in
					if isOn {
						flags.wrappedValue.insert(flag)
					} else {
						flags.wrappedValue.remove(flag)
					}
				}
			)
		)
		.toggleStyle(.checkbox)
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
			startRecording(fieldId: fieldId, flags: flags, keyCode: keyCode)
		}) {
			Text(liveLabel)
				.font(.caption)
				.frame(minWidth: 80)
		}
		.buttonStyle(.bordered)
		.disabled(isRecording)
	}

	private func startRecording(fieldId: String, flags: Binding<Double>, keyCode: Binding<Double>) {
		endRecording()
		recordingField = fieldId
		liveModifierFlags = []
		NotificationCenter.default.post(name: .scrolodexPauseEventTap, object: nil)

		flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
			guard recordingField == fieldId else { return event }
			liveModifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
				.intersection([.command, .option, .control, .shift])
			return event
		}

		keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
			guard recordingField == fieldId else { return event }
			let rawMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
			let code = CGKeyCode(event.keyCode)

			if code == 53 && rawMods.isEmpty {
				endRecording()
				return nil
			}

			flags.wrappedValue = Double(rawMods.rawValue)
			keyCode.wrappedValue = Double(code)
			endRecording()
			return nil
		}
	}

	private func endRecording() {
		if let monitor = keyMonitor {
			NSEvent.removeMonitor(monitor)
			keyMonitor = nil
		}
		if let monitor = flagsMonitor {
			NSEvent.removeMonitor(monitor)
			flagsMonitor = nil
		}
		let wasRecording = recordingField != nil
		recordingField = nil
		liveModifierFlags = []
		if wasRecording {
			NotificationCenter.default.post(name: .scrolodexResumeEventTap, object: nil)
		}
	}

	private func modifierPills(flags: Binding<CGEventFlags>, allOtherFlags: CGEventFlags) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			SettingsFieldLabel("Trigger keys")
			HStack(spacing: 6) {
				ModifierPill(label: "⌘", isOn: flags.wrappedValue.contains(.maskCommand)) {
					toggleFlag(.maskCommand, flags: flags)
				}
				ModifierPill(label: "⌥", isOn: flags.wrappedValue.contains(.maskAlternate)) {
					toggleFlag(.maskAlternate, flags: flags)
				}
				ModifierPill(label: "⌃", isOn: flags.wrappedValue.contains(.maskControl)) {
					toggleFlag(.maskControl, flags: flags)
				}
				ModifierPill(label: "⇧", isOn: flags.wrappedValue.contains(.maskShift)) {
					toggleFlag(.maskShift, flags: flags)
				}
			}

			if !allOtherFlags.isEmpty && flags.wrappedValue == allOtherFlags {
				Text("Same as another trigger")
					.font(.caption)
					.foregroundStyle(.red)
			} else if flags.wrappedValue.isEmpty {
				Text("Select at least one modifier")
					.font(.caption)
					.foregroundStyle(.orange)
			}
		}
	}

	private func toggleFlag(_ flag: CGEventFlags, flags: Binding<CGEventFlags>) {
		if flags.wrappedValue.contains(flag) {
			flags.wrappedValue.remove(flag)
		} else {
			flags.wrappedValue.insert(flag)
		}
	}

	private func allOtherFlagsForTrigger(excluding current: TriggerSettingsStore) -> CGEventFlags {
		var combined = CGEventFlags()
		let allFlags: [Double] = [
			trigger1.flags, trigger2.flags, trigger3.flags, trigger4.flags, desktopSwitchFlags,
			dockHoverCurrent.flags, dockHoverAll.flags,
		]
		for flags in allFlags where flags != current.flags {
			combined.formUnion(CGEventFlags(rawValue: UInt64(flags)))
		}
		return combined
	}

	private var allOtherFlagsForDesktop: CGEventFlags {
		var combined = CGEventFlags()
		let allFlags: [Double] = [
			trigger1.flags, trigger2.flags, trigger3.flags, trigger4.flags,
			dockHoverCurrent.flags, dockHoverAll.flags,
		]
		for flags in allFlags {
			combined.formUnion(CGEventFlags(rawValue: UInt64(flags)))
		}
		return combined
	}

	private func allOtherFlagsForDockHover(excluding current: TriggerSettingsStore) -> CGEventFlags {
		var combined = CGEventFlags()
		let allFlags: [Double] = [
			trigger1.flags, trigger2.flags, trigger3.flags, trigger4.flags, desktopSwitchFlags,
			dockHoverCurrent.flags == current.flags ? 0 : dockHoverCurrent.flags,
			dockHoverAll.flags == current.flags ? 0 : dockHoverAll.flags,
		]
		for flags in allFlags where flags > 0 {
			combined.formUnion(CGEventFlags(rawValue: UInt64(flags)))
		}
		return combined
	}

	private let permissions = PermissionController()

	private func requestAccessibility() {
		permissions.requestAccessibilityPermission()
	}

	private func requestScreenRecording() {
		if !CGRequestScreenCaptureAccess() {
			permissions.openScreenRecordingSettings()
		}
	}

	private func startPermissionPolling() {
		permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
			let acc = AXIsProcessTrusted()
			let sr = CGPreflightScreenCaptureAccess()
			DispatchQueue.main.async {
				accessibilityGranted = acc
				screenRecordingGranted = sr
				if acc && sr {
					permissionPollTimer?.invalidate()
					permissionPollTimer = nil
				}
			}
		}
	}
}
