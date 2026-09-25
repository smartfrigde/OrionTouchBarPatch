//
//  SetupView.swift
//  OrionTouchBarPatch
//

import SwiftUI

struct SetupView: View {
    @ObservedObject var model: SetupModel
    var onContinueInBackground: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $model.pane) {
                ForEach(SetupModel.Pane.allCases) { pane in
                    Text(pane.title).tag(pane)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            Group {
                switch model.pane {
                case .permissions:
                    permissionsPane
                case .layout:
                    layoutPane
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            if let statusMessage = model.statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }

            HStack {
                Button("Refresh") { model.refresh() }
                    .keyboardShortcut("r", modifiers: .command)
                Button("Quit") { onQuit() }
                Spacer()
                if model.pane == .permissions, model.isFirstLaunch {
                    Button("Customize Touch Bar…") { model.pane = .layout }
                }
                Button(model.isFirstLaunch ? "Start in Background" : "Hide") {
                    model.markOnboardingCompleted()
                    onContinueInBackground()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .frame(width: 560, height: 620)
        .onAppear {
            model.refresh()
            if model.isFirstLaunch {
                model.pane = .permissions
            }
        }
    }

    // MARK: - Permissions

    private var permissionsPane: some View {
        Form {
            Section {
                permissionRow(
                    title: "Control Orion",
                    subtitle: "Required for navigation, close tab, and copy URL",
                    ok: model.orionAutomationOK,
                    actionTitle: "Allow…",
                    action: model.requestOrionAutomation
                )
                permissionRow(
                    title: "Control System Events",
                    subtitle: "Required for keyboard shortcuts",
                    ok: model.systemEventsAutomationOK,
                    actionTitle: "Allow…",
                    action: model.requestSystemEventsAutomation
                )
                permissionRow(
                    title: "Accessibility",
                    subtitle: "Optional; improves shortcut reliability",
                    ok: model.accessibilityOK,
                    actionTitle: "Enable…",
                    action: model.requestAccessibility
                )
            } header: {
                Text("Permissions")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Allow JavaScript from Apple Events")
                                .font(.body.weight(.medium))
                            Text("In Orion, open the Develop menu and enable this option. Required for Back, Forward, and Reload.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 8)
                        if model.javaScriptFromAppleEventsOK {
                            Text("Enabled")
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Open Orion…") {
                                model.showOrionJavaScriptSetting()
                            }
                        }
                    }

                    Text("Develop → Allow JavaScript from Apple Events")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            } header: {
                Text("In Orion")
            }
            Section("Startup") {
                Toggle(
                    "Open at Login",
                    isOn: Binding(
                        get: { model.loginItemEnabled },
                        set: { model.toggleLoginItem($0) }
                    )
                )
            }
        }
        .formStyle(.grouped)
    }

    private func permissionRow(
        title: String,
        subtitle: String,
        ok: Bool,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if ok {
                Text("Allowed")
                    .foregroundStyle(.secondary)
            } else {
                Button(actionTitle, action: action)
            }
        }
    }

    // MARK: - Layout

    private var layoutPane: some View {
        Form {
            Section {
                TouchBarPreviewStrip(items: model.preferences.orderedEnabledItems)
            } header: {
                Text("Preview")
            } footer: {
                Text(previewFooter)
            }

            Section("Presets") {
                Picker("Layout", selection: presetBinding) {
                    ForEach(TouchBarPreset.allCases.filter { $0 != .custom }) { preset in
                        Text(preset.title).tag(preset)
                    }
                    if model.preferences.preset == .custom {
                        Text("Custom").tag(TouchBarPreset.custom)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

                Text(model.preferences.preset.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(TouchBarSection.allCases) { section in
                Section(section.title) {
                    ForEach(TouchBarItemID.layoutOrder.filter { $0.section == section }) { item in
                        Toggle(isOn: itemBinding(item)) {
                            VStack(alignment: .leading, spacing: 1) {
                                Label(item.title, systemImage: item.symbolName)
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var previewFooter: String {
        let count = model.preferences.orderedEnabledItems.count
        let preset = model.preferences.preset.title
        return "\(count) controls · \(preset)"
    }

    private var presetBinding: Binding<TouchBarPreset> {
        Binding(
            get: { model.preferences.preset },
            set: { newValue in
                if newValue != .custom {
                    model.applyPreset(newValue)
                }
            }
        )
    }

    private func itemBinding(_ item: TouchBarItemID) -> Binding<Bool> {
        Binding(
            get: { model.preferences.isEnabled(item) },
            set: { model.setItem(item, enabled: $0) }
        )
    }
}

// MARK: - Preview

private struct TouchBarPreviewStrip: View {
    let items: [TouchBarItemID]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if items.isEmpty {
                    Text("No controls selected")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(items) { item in
                        if item == .title {
                            Text("Tab Title")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.quaternary, in: Capsule())
                        } else {
                            Image(systemName: item.symbolName)
                                .frame(width: 28, height: 24)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                                .help(item.title)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
