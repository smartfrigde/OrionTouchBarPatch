//
//  SetupModel.swift
//  OrionTouchBarPatch
//

import AppKit
import ApplicationServices
import Combine
import Foundation
import ServiceManagement

final class SetupModel: ObservableObject {
    static let onboardingCompletedKey = "didCompleteOnboarding"

    enum Pane: String, CaseIterable, Identifiable {
        case permissions
        case layout

        var id: String { rawValue }

        var title: String {
            switch self {
            case .permissions: return "Setup"
            case .layout: return "Touch Bar"
            }
        }
    }

    @Published var pane: Pane = .permissions
    @Published var loginItemEnabled = false
    @Published var orionAutomationOK = false
    @Published var systemEventsAutomationOK = false
    @Published var accessibilityOK = false
    @Published var javaScriptFromAppleEventsOK = false
    @Published var statusMessage: String?
    @Published private(set) var preferences: TouchBarPreferences

    private var prefsCancellable: AnyCancellable?

    var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
    }

    init(preferences: TouchBarPreferences = .shared) {
        self.preferences = preferences
        prefsCancellable = preferences.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func refresh() {
        loginItemEnabled = (SMAppService.mainApp.status == .enabled)
        orionAutomationOK = probeAppleScript(
            """
            tell application "Orion" to get name
            """
        )
        systemEventsAutomationOK = probeAppleScript(
            """
            tell application "System Events" to get name
            """
        )
        accessibilityOK = AXIsProcessTrusted()
        javaScriptFromAppleEventsOK = probeJavaScriptFromAppleEvents()
        statusMessage = nil
    }

    func toggleLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemEnabled = (SMAppService.mainApp.status == .enabled)
            statusMessage = loginItemEnabled ? "Open at Login enabled." : "Open at Login disabled."
        } catch {
            statusMessage = error.localizedDescription
            loginItemEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }

    func requestOrionAutomation() {
        _ = probeAppleScript(
            """
            tell application "Orion"
                if (count of windows) > 0 then
                    return name of current tab of window 1
                end if
                return "ok"
            end tell
            """,
            logErrors: false
        )
        refresh()
        if !orionAutomationOK {
            openAutomationSettings()
            statusMessage = "Allow this app to control Orion, then click Refresh."
        }
    }

    func requestSystemEventsAutomation() {
        _ = probeAppleScript(
            """
            tell application "System Events" to get name
            """,
            logErrors: false
        )
        refresh()
        if !systemEventsAutomationOK {
            openAutomationSettings()
            statusMessage = "Allow this app to control System Events, then click Refresh."
        }
    }

    func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        refresh()
        if !accessibilityOK {
            openAccessibilitySettings()
            statusMessage = "Enable this app under Accessibility, then click Refresh."
        }
    }

    func showOrionJavaScriptSetting() {
        _ = probeAppleScript(
            """
            tell application "Orion" to activate
            """,
            logErrors: false
        )
        statusMessage = "In Orion: Develop → Allow JavaScript from Apple Events (leave it checked), then click Refresh."
    }

    func applyPreset(_ preset: TouchBarPreset) {
        preferences.applyPreset(preset)
        statusMessage = "Applied \(preset.title) layout."
    }

    func setItem(_ item: TouchBarItemID, enabled: Bool) {
        preferences.setItem(item, enabled: enabled)
    }

    func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
    }

    private func openAutomationSettings() {
        openSettings(
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation",
            modern: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Automation"
        )
    }

    private func openAccessibilitySettings() {
        openSettings(
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            modern: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        )
    }

    private func openSettings(_ legacy: String, modern: String) {
        let modernURL = URL(string: modern)!
        if NSWorkspace.shared.open(modernURL) { return }
        if let legacyURL = URL(string: legacy) {
            NSWorkspace.shared.open(legacyURL)
        }
    }

    private func probeJavaScriptFromAppleEvents() -> Bool {
        // Requires an open Orion window/tab to verify; otherwise stays unchecked.
        probeAppleScript(
            """
            tell application "Orion"
                if (count of windows) is 0 then error "no window"
                return do JavaScript "true" in current tab of window 1
            end tell
            """,
            logErrors: false
        )
    }

    @discardableResult
    private func probeAppleScript(_ source: String, logErrors: Bool = true) -> Bool {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return false }
        _ = script.executeAndReturnError(&error)
        if let error {
            if logErrors {
                NSLog("Setup probe error: %@", error)
            }
            return false
        }
        return true
    }
}
