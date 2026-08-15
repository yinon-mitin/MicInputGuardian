import AppKit
import Combine
import SwiftUI

@MainActor
final class SettingsWindowPresenter: ObservableObject {
    private var windowController: NSWindowController?

    func open(
        controller: AudioController,
        launchAtLoginController: LaunchAtLoginController
    ) {
        let windowController = windowController ?? makeWindowController(
            controller: controller,
            launchAtLoginController: launchAtLoginController
        )
        self.windowController = windowController

        let application = NSApplication.shared
        application.activate(ignoringOtherApps: true)
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.window?.orderFrontRegardless()
    }

    private func makeWindowController(
        controller: AudioController,
        launchAtLoginController: LaunchAtLoginController
    ) -> NSWindowController {
        let rootView = SettingsView(
            controller: controller,
            launchAtLoginController: launchAtLoginController
        )
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)

        window.title = "Mic Input Guardian Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("MicInputGuardianSettingsWindow")

        return NSWindowController(window: window)
    }
}
