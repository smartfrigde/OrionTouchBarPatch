//
//  TouchBarPreferences.swift
//  OrionTouchBarPatch
//

import Combine
import Foundation

extension Notification.Name {
    static let touchBarPreferencesDidChange = Notification.Name("touchBarPreferencesDidChange")
}

final class TouchBarPreferences: ObservableObject {
    static let shared = TouchBarPreferences()

    private let presetKey = "touchBarPreset"
    private let enabledKey = "touchBarEnabledItems"

    @Published private(set) var preset: TouchBarPreset {
        didSet { persist() }
    }

    @Published private(set) var enabledItems: Set<TouchBarItemID> {
        didSet { persist() }
    }

    private init() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: presetKey),
           let stored = TouchBarPreset(rawValue: raw) {
            preset = stored
        } else {
            preset = .compact
        }

        if let rawItems = defaults.array(forKey: enabledKey) as? [String] {
            let decoded = Set(rawItems.compactMap(TouchBarItemID.init(rawValue:)))
            enabledItems = decoded.isEmpty ? (TouchBarPreset.compact.items ?? []) : decoded
        } else {
            enabledItems = TouchBarPreset.compact.items ?? []
            preset = .compact
        }
    }

    var orderedEnabledItems: [TouchBarItemID] {
        TouchBarItemID.layoutOrder.filter { enabledItems.contains($0) }
    }

    func applyPreset(_ preset: TouchBarPreset) {
        guard let items = preset.items else { return }
        self.preset = preset
        enabledItems = items
        notify()
    }

    func setItem(_ item: TouchBarItemID, enabled: Bool) {
        if enabled {
            enabledItems.insert(item)
        } else {
            enabledItems.remove(item)
        }
        preset = matchingPreset(for: enabledItems) ?? .custom
        notify()
    }

    func isEnabled(_ item: TouchBarItemID) -> Bool {
        enabledItems.contains(item)
    }

    private func matchingPreset(for items: Set<TouchBarItemID>) -> TouchBarPreset? {
        for preset in TouchBarPreset.allCases where preset != .custom {
            if preset.items == items { return preset }
        }
        return nil
    }

    private func persist() {
        UserDefaults.standard.set(preset.rawValue, forKey: presetKey)
        UserDefaults.standard.set(orderedEnabledItems.map(\.rawValue), forKey: enabledKey)
    }

    private func notify() {
        NotificationCenter.default.post(name: .touchBarPreferencesDidChange, object: self)
    }
}
