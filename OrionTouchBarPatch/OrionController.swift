//
//  OrionController.swift
//  OrionTouchBarPatch
//

import AppKit
import Foundation

enum OrionController {
    static let bundleIdentifier = "com.kagi.kagimacOS"

    static func isFrontmost() -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifier
    }

    static func currentTabTitle() -> String? {
        runAppleScript(
            """
            tell application "Orion"
                if (count of windows) is 0 then return ""
                return name of current tab of window 1
            end tell
            """
        )
    }

    static func perform(_ item: TouchBarItemID) {
        guard item.isAction else { return }

        switch item {
        case .back:
            runInCurrentTab("history.back()")
        case .forward:
            runInCurrentTab("history.forward()")
        case .reload:
            runInCurrentTab("location.reload()")
        case .hardReload:
            keystroke("r", using: [.command, .shift])
        case .home:
            keystroke("h", using: [.command, .shift])
        case .newTab:
            keystroke("t", using: [.command])
        case .closeTab:
            _ = runAppleScript(
                """
                tell application "Orion"
                    if (count of windows) is 0 then return
                    close current tab of window 1
                end tell
                """
            )
        case .previousTab:
            keystroke("\t", using: [.control, .shift])
        case .nextTab:
            keystroke("\t", using: [.control])
        case .focusAddressBar:
            keystroke("l", using: [.command])
        case .copyURL:
            _ = runAppleScript(
                """
                tell application "Orion"
                    if (count of windows) is 0 then return
                    set the clipboard to (URL of current tab of window 1 as text)
                end tell
                """
            )
        case .findInPage:
            keystroke("f", using: [.command])
        case .focusMode:
            keystroke("f", using: [.command, .shift])
        case .zoomOut:
            keystroke("-", using: [.command])
        case .zoomIn:
            keystroke("=", using: [.command])
        case .devTools:
            keystroke("i", using: [.command, .option])
        case .title:
            break
        }
    }

    // MARK: - Private

    private static func runInCurrentTab(_ javaScript: String) {
        let escaped = javaScript
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        _ = runAppleScript(
            """
            tell application "Orion"
                if (count of windows) is 0 then return
                do JavaScript "\(escaped)" in current tab of window 1
            end tell
            """
        )
    }

    private static func keystroke(_ key: String, using modifiers: NSEvent.ModifierFlags) {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("command down") }
        if modifiers.contains(.shift) { parts.append("shift down") }
        if modifiers.contains(.option) { parts.append("option down") }
        if modifiers.contains(.control) { parts.append("control down") }

        let usingClause: String
        if parts.isEmpty {
            usingClause = ""
        } else if parts.count == 1 {
            usingClause = " using \(parts[0])"
        } else {
            usingClause = " using {\(parts.joined(separator: ", "))}"
        }

        let escapedKey = key
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        _ = runAppleScript(
            """
            tell application "System Events"
                tell process "Orion"
                    set frontmost to true
                    keystroke "\(escapedKey)"\(usingClause)
                end tell
            end tell
            """
        )
    }

    @discardableResult
    private static func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        if let error {
            NSLog("OrionTouchBar AppleScript error: %@", error)
            return nil
        }
        return result.stringValue
    }
}
