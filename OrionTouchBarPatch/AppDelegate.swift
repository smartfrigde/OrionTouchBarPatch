//
//  AppDelegate.swift
//  OrionTouchBarPatch
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let setupModel = SetupModel()
    private var setupWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        TouchBarController.shared.install()

        if setupModel.isFirstLaunch {
            showSetupWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        TouchBarController.shared.uninstall()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showSetupWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func showSetupWindow() {
        setupModel.refresh()

        if setupWindow == nil {
            let root = SetupView(
                model: setupModel,
                onContinueInBackground: { [weak self] in
                    self?.hideSetupWindow()
                },
                onQuit: {
                    NSApp.terminate(nil)
                }
            )
            let hosting = NSHostingController(rootView: root)
            let window = NSWindow(contentViewController: hosting)
            window.title = "Orion Touch Bar"
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.center()
            window.delegate = self
            setupWindow = window
        } else if let hosting = setupWindow?.contentViewController as? NSHostingController<SetupView> {
            hosting.rootView = SetupView(
                model: setupModel,
                onContinueInBackground: { [weak self] in
                    self?.hideSetupWindow()
                },
                onQuit: {
                    NSApp.terminate(nil)
                }
            )
        }

        NSApp.setActivationPolicy(.regular)
        setupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideSetupWindow() {
        setupWindow?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if setupModel.isFirstLaunch {
            setupModel.markOnboardingCompleted()
        }
        NSApp.setActivationPolicy(.accessory)
    }
}
