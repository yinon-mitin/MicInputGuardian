import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

@main
struct MicInputGuardianApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = AudioController()
    @StateObject private var launchAtLoginController = LaunchAtLoginController()
    @StateObject private var settingsWindowPresenter = SettingsWindowPresenter()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(
                controller: controller,
                launchAtLoginController: launchAtLoginController,
                settingsWindowPresenter: settingsWindowPresenter
            )
        } label: {
            Image(
                systemName: controller.automationEnabled
                    ? "mic.circle.fill"
                    : "mic.slash.circle"
            )
            .accessibilityLabel("Mic Input Guardian")
        }
        .menuBarExtraStyle(.menu)
    }
}
