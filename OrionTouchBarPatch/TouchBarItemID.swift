//
//  TouchBarItemID.swift
//  OrionTouchBarPatch
//

import Foundation

enum TouchBarSection: String, CaseIterable, Identifiable {
    case navigation
    case tabs
    case page
    case view
    case developer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .navigation: return "Navigation"
        case .tabs: return "Tabs"
        case .page: return "Page"
        case .view: return "View"
        case .developer: return "Developer"
        }
    }
}

enum TouchBarItemID: String, CaseIterable, Codable, Identifiable {
    case back
    case forward
    case reload
    case hardReload
    case home
    case newTab
    case closeTab
    case previousTab
    case nextTab
    case focusAddressBar
    case copyURL
    case findInPage
    case focusMode
    case zoomOut
    case zoomIn
    case title
    case devTools

    var id: String { rawValue }

    var title: String {
        switch self {
        case .back: return "Back"
        case .forward: return "Forward"
        case .reload: return "Reload"
        case .hardReload: return "Hard Reload"
        case .home: return "Home"
        case .newTab: return "New Tab"
        case .closeTab: return "Close Tab"
        case .previousTab: return "Previous Tab"
        case .nextTab: return "Next Tab"
        case .focusAddressBar: return "Focus Address Bar"
        case .copyURL: return "Copy URL"
        case .findInPage: return "Find in Page"
        case .focusMode: return "Focus Mode"
        case .zoomOut: return "Zoom Out"
        case .zoomIn: return "Zoom In"
        case .title: return "Tab Title"
        case .devTools: return "Web Inspector"
        }
    }

    var subtitle: String {
        switch self {
        case .back: return "history.back()"
        case .forward: return "history.forward()"
        case .reload: return "Reload page"
        case .hardReload: return "⇧⌘R"
        case .home: return "⇧⌘H"
        case .newTab: return "⌘T"
        case .closeTab: return "Close current tab"
        case .previousTab: return "⌃⇧⇥"
        case .nextTab: return "⌃⇥"
        case .focusAddressBar: return "⌘L"
        case .copyURL: return "Copy tab URL"
        case .findInPage: return "⌘F"
        case .focusMode: return "⇧⌘F"
        case .zoomOut: return "⌘−"
        case .zoomIn: return "⌘+"
        case .title: return "Current tab title"
        case .devTools: return "⌥⌘I"
        }
    }

    var symbolName: String {
        switch self {
        case .back: return "chevron.backward"
        case .forward: return "chevron.forward"
        case .reload: return "arrow.clockwise"
        case .hardReload: return "arrow.clockwise.circle"
        case .home: return "house"
        case .newTab: return "plus"
        case .closeTab: return "xmark"
        case .previousTab: return "chevron.backward.2"
        case .nextTab: return "chevron.forward.2"
        case .focusAddressBar: return "safari"
        case .copyURL: return "doc.on.doc"
        case .findInPage: return "magnifyingglass"
        case .focusMode: return "doc.plaintext"
        case .zoomOut: return "minus.magnifyingglass"
        case .zoomIn: return "plus.magnifyingglass"
        case .title: return "macwindow"
        case .devTools: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var section: TouchBarSection {
        switch self {
        case .back, .forward, .reload, .hardReload, .home:
            return .navigation
        case .newTab, .closeTab, .previousTab, .nextTab:
            return .tabs
        case .focusAddressBar, .copyURL, .findInPage:
            return .page
        case .focusMode, .zoomOut, .zoomIn, .title:
            return .view
        case .devTools:
            return .developer
        }
    }

    var isAction: Bool { self != .title }

    static let layoutOrder: [TouchBarItemID] = [
        .back, .forward, .reload, .hardReload, .home,
        .newTab, .closeTab, .previousTab, .nextTab,
        .focusAddressBar, .copyURL, .findInPage,
        .focusMode, .zoomOut, .zoomIn,
        .devTools,
        .title,
    ]
}

enum TouchBarPreset: String, CaseIterable, Identifiable, Codable {
    case compact
    case standard
    case power
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Standard"
        case .power: return "Power"
        case .custom: return "Custom"
        }
    }

    var subtitle: String {
        switch self {
        case .compact: return "Back, forward, reload, new tab"
        case .standard: return "Compact + close & tab switch + address bar"
        case .power: return "Standard + copy URL, find, home, hard reload, title"
        case .custom: return "Manually selected controls"
        }
    }

    var items: Set<TouchBarItemID>? {
        switch self {
        case .compact:
            return [.back, .forward, .reload, .newTab]
        case .standard:
            return [.back, .forward, .reload, .newTab, .closeTab, .previousTab, .nextTab, .focusAddressBar]
        case .power:
            return [
                .back, .forward, .reload, .hardReload, .home,
                .newTab, .closeTab, .previousTab, .nextTab,
                .focusAddressBar, .copyURL, .findInPage, .title,
            ]
        case .custom:
            return nil
        }
    }
}
