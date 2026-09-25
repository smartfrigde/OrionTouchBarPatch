//
//  OrionTouchBarPatchApp.swift
//  OrionTouchBarPatch
//

import SwiftUI

@main
struct OrionTouchBarPatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
