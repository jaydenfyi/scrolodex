import ScrolodexCore
import SwiftUI

struct SettingsSectionHeader<Accessory: View>: View {
	private let title: String
	private let accessory: Accessory

	init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
		self.title = title
		self.accessory = accessory()
	}

	var body: some View {
		HStack {
			Text(title)
				.font(.system(size: 13, weight: .semibold))
				.foregroundStyle(.secondary)
			Spacer()
			accessory
		}
		.padding(.leading, 12)
		.padding(.trailing, 12)
		.padding(.bottom, 7)
	}
}

extension SettingsSectionHeader where Accessory == EmptyView {
	init(_ title: String) {
		self.title = title
		self.accessory = EmptyView()
	}
}

struct SettingsFieldLabel: View {
	private let title: String

	init(_ title: String) {
		self.title = title
	}

	var body: some View {
		Text(title)
			.font(.caption.weight(.semibold))
			.foregroundStyle(.secondary)
	}
}

struct SettingsIndentedDivider: View {
	private let leading: CGFloat
	private let vertical: CGFloat?

	init(leading: CGFloat = 42, vertical: CGFloat? = nil) {
		self.leading = leading
		self.vertical = vertical
	}

	var body: some View {
		Divider()
			.padding(.leading, leading)
			.padding(.vertical, vertical ?? 0)
	}
}

struct SettingsRow<Trailing: View>: View {
	private let icon: String
	private let iconColor: Color
	private let title: String
	private let subtitle: String?
	private let trailing: Trailing

	init(
		icon: String,
		iconColor: Color,
		title: String,
		subtitle: String? = nil,
		@ViewBuilder trailing: () -> Trailing
	) {
		self.icon = icon
		self.iconColor = iconColor
		self.title = title
		self.subtitle = subtitle
		self.trailing = trailing()
	}

	var body: some View {
		HStack(spacing: 10) {
			settingsIconBox(systemName: icon, color: iconColor)
			if let subtitle {
				VStack(alignment: .leading, spacing: 1) {
					Text(title)
						.font(.body)
					Text(subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			} else {
				Text(title)
					.font(.body)
			}
			Spacer()
			trailing
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
	}
}

extension SettingsRow where Trailing == EmptyView {
	init(icon: String, iconColor: Color, title: String, subtitle: String? = nil) {
		self.icon = icon
		self.iconColor = iconColor
		self.title = title
		self.subtitle = subtitle
		self.trailing = EmptyView()
	}
}

extension View {
	func settingsIconBox(systemName: String, color: Color) -> some View {
		Image(systemName: systemName)
			.font(.system(size: 12, weight: .medium))
			.foregroundStyle(color)
			.frame(width: 26, height: 26)
			.background(color.opacity(0.12))
			.clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
	}

	func settingsMiniChips(_ chips: [String]) -> some View {
		HStack(spacing: 4) {
			ForEach(chips, id: \.self) { chip in
				Text(chip)
					.font(.system(size: 9, weight: .semibold))
					.lineLimit(1)
					.fixedSize(horizontal: true, vertical: false)
					.padding(.horizontal, 5)
					.padding(.vertical, 2)
					.background(
						chip == "Disabled"
							? Color.secondary.opacity(0.08) : Color.accentColor.opacity(0.1)
					)
					.foregroundStyle(chip == "Disabled" ? Color.secondary : Color.accentColor)
					.clipShape(Capsule())
			}
		}
	}

	func settingsSubgroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
		VStack(spacing: 0) {
			content()
		}
		.padding(.horizontal, 10)
		.background(
			RoundedRectangle(cornerRadius: 8, style: .continuous)
				.fill(Color(nsColor: .textBackgroundColor).opacity(0.45))
		)
	}

	func settingsToggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
		HStack(spacing: 12) {
			Text(title)
				.font(.caption)
				.foregroundStyle(.secondary)
			Spacer()
			Toggle("", isOn: isOn)
				.toggleStyle(.switch)
				.controlSize(.small)
				.labelsHidden()
		}
		.padding(.vertical, 4)
	}

	func settingsKeyBindingRow(
		label: String, bindingFlags: Binding<Double>, bindingKeyCode: Binding<Double>,
		keyRecorder: () -> some View
	) -> some View {
		let hasBinding = bindingFlags.wrappedValue != 0 || bindingKeyCode.wrappedValue != 0
		return HStack(spacing: 12) {
			Text(label)
				.font(.caption)
				.foregroundStyle(.secondary)
			Spacer()
			if hasBinding {
				Button {
					bindingFlags.wrappedValue = 0
					bindingKeyCode.wrappedValue = 0
				} label: {
					Image(systemName: "xmark.circle.fill")
						.font(.system(size: 12))
						.foregroundStyle(.secondary)
				}
				.buttonStyle(.plain)
			}
			keyRecorder()
		}
		.padding(.vertical, 4)
	}

	func settingsAdvancedDisclosureHeader(isExpanded: Bool, toggle: @escaping () -> Void) -> some View {
		Button {
			withAnimation(.easeOut(duration: 0.16)) {
				toggle()
			}
		} label: {
			HStack(spacing: 6) {
				Image(systemName: "chevron.right")
					.font(.system(size: 10, weight: .semibold))
					.foregroundStyle(.secondary)
					.rotationEffect(.degrees(isExpanded ? 90 : 0))
				Text("Advanced Options")
					.foregroundStyle(.primary)
				Spacer()
			}
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}
}
