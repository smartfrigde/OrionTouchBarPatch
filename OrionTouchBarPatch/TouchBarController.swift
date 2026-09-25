//
//  TouchBarController.swift
//  OrionTouchBarPatch
//

import AppKit
import Darwin
import Foundation

final class TouchBarController: NSObject, NSTouchBarDelegate {
    static let shared = TouchBarController()

    private let stripIdentifier = NSTouchBarItem.Identifier("dev.pzurek.OrionTouchBarPatch.strip")
    private let barIdentifier = NSTouchBar.CustomizationIdentifier("dev.pzurek.OrionTouchBarPatch.bar")

    private var stripItem: NSCustomTouchBarItem?
    private var touchBar: NSTouchBar?
    private var titleItem: NSCustomTouchBarItem?
    private var orionOwnsBar = false
    private var titleTimer: Timer?
    private var prefsObserver: NSObjectProtocol?

    private override init() {
        super.init()
    }

    func install() {
        loadPrivateFramework()
        DFRSystemModalShowsCloseBoxWhenFrontMost(false)

        let item = NSCustomTouchBarItem(identifier: stripIdentifier)
        item.view = NSButton(
            image: NSImage(systemSymbolName: "globe", accessibilityDescription: "Orion")
                ?? NSImage(named: NSImage.applicationIconName)!,
            target: self,
            action: #selector(reassertFromStrip)
        )
        stripItem = item
        NSTouchBarItem.addSystemTrayItem(item)
        DFRElementSetControlStripPresenceForIdentifier(stripIdentifier, true)

        let bar = NSTouchBar()
        bar.delegate = self
        bar.customizationIdentifier = barIdentifier
        touchBar = bar
        applyLayoutFromPreferences()

        prefsObserver = NotificationCenter.default.addObserver(
            forName: .touchBarPreferencesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyLayoutFromPreferences()
            if OrionController.isFrontmost() {
                self?.presentBar()
            }
        }

        observeAppActivation()
        syncWithFrontmostApp()
    }

    func uninstall() {
        if let prefsObserver {
            NotificationCenter.default.removeObserver(prefsObserver)
        }
        titleTimer?.invalidate()
        titleTimer = nil
        if let touchBar {
            NSTouchBar.dismissSystemModalTouchBar(touchBar)
        }
        orionOwnsBar = false
        if let stripItem {
            NSTouchBarItem.removeSystemTrayItem(stripItem)
        }
        DFRElementSetControlStripPresenceForIdentifier(stripIdentifier, false)
    }

    func applyLayoutFromPreferences() {
        guard let touchBar else { return }
        var ids = TouchBarPreferences.shared.orderedEnabledItems.map(\.touchBarIdentifier)
        if ids.contains(TouchBarItemID.title.touchBarIdentifier) {
            ids.removeAll { $0 == TouchBarItemID.title.touchBarIdentifier }
            ids.append(.flexibleSpace)
            ids.append(TouchBarItemID.title.touchBarIdentifier)
        }
        touchBar.defaultItemIdentifiers = ids
        titleItem = nil
    }

    // MARK: - NSTouchBarDelegate

    func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        guard let kind = TouchBarItemID.from(touchBarIdentifier: identifier) else { return nil }

        if kind == .title {
            let item = NSCustomTouchBarItem(identifier: identifier)
            let label = NSTextField(labelWithString: "Orion")
            label.font = .systemFont(ofSize: 13)
            label.lineBreakMode = .byTruncatingMiddle
            item.view = label
            titleItem = item
            return item
        }

        return buttonItem(
            identifier,
            symbol: kind.symbolName,
            tooltip: kind.title,
            action: #selector(handleTouchBarButton(_:))
        )
    }

    // MARK: - Presentation

    @objc private func reassertFromStrip() {
        guard OrionController.isFrontmost() else { return }
        presentBar()
    }

    func presentBar() {
        guard let touchBar else { return }
        NSTouchBar.presentSystemModalTouchBar(touchBar, systemTrayItemIdentifier: stripIdentifier)
        orionOwnsBar = true
        DFRElementSetControlStripPresenceForIdentifier(stripIdentifier, true)
        if TouchBarPreferences.shared.isEnabled(.title) {
            startTitleUpdates()
            refreshTitle()
        } else {
            titleTimer?.invalidate()
            titleTimer = nil
        }
    }

    private func noteOrionLostFocus() {
        // Avoid dismissSystemModalTouchBar here; dismissing on app-switch can drop Escape.
        orionOwnsBar = false
        titleTimer?.invalidate()
        titleTimer = nil
        DFRElementSetControlStripPresenceForIdentifier(stripIdentifier, true)
    }

    private func syncWithFrontmostApp() {
        if OrionController.isFrontmost() {
            presentBar()
        } else if orionOwnsBar {
            noteOrionLostFocus()
        }
    }

    private func observeAppActivation() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                self?.syncWithFrontmostApp()
            }
        }
    }

    private func startTitleUpdates() {
        titleTimer?.invalidate()
        titleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshTitle()
        }
    }

    private func refreshTitle() {
        guard let label = titleItem?.view as? NSTextField else { return }
        let title = OrionController.currentTabTitle()?.trimmingCharacters(in: .whitespacesAndNewlines)
        label.stringValue = (title?.isEmpty == false) ? title! : "Orion"
    }

    @objc private func handleTouchBarButton(_ sender: NSButton) {
        guard
            let raw = sender.identifier?.rawValue,
            let kind = TouchBarItemID(rawValue: raw)
        else { return }
        OrionController.perform(kind)
    }

    private func buttonItem(
        _ identifier: NSTouchBarItem.Identifier,
        symbol: String,
        tooltip: String,
        action: Selector
    ) -> NSCustomTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: identifier)
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)
            ?? NSImage(size: NSSize(width: 20, height: 20))
        let button = NSButton(image: image, target: self, action: action)
        button.toolTip = tooltip
        if let kind = TouchBarItemID.from(touchBarIdentifier: identifier) {
            button.identifier = NSUserInterfaceItemIdentifier(kind.rawValue)
        }
        item.view = button
        return item
    }

    private func loadPrivateFramework() {
        let path = "/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation"
        dlopen(path, RTLD_NOW)
    }
}

private extension TouchBarItemID {
    var touchBarIdentifier: NSTouchBarItem.Identifier {
        NSTouchBarItem.Identifier("dev.pzurek.OrionTouchBarPatch.\(rawValue)")
    }

    static func from(touchBarIdentifier: NSTouchBarItem.Identifier) -> TouchBarItemID? {
        let prefix = "dev.pzurek.OrionTouchBarPatch."
        let raw = touchBarIdentifier.rawValue
        guard raw.hasPrefix(prefix) else { return nil }
        return TouchBarItemID(rawValue: String(raw.dropFirst(prefix.count)))
    }
}
