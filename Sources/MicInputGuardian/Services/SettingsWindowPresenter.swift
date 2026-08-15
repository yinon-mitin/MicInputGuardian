import AppKit

@MainActor
enum SettingsWindowPresenter {
    static func open() {
        let application = NSApplication.shared
        application.activate(ignoringOtherApps: true)

        if !application.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: nil
        ) {
            application.sendAction(
                Selector(("showPreferencesWindow:")),
                to: nil,
                from: nil
            )
        }

        bringToFront(attemptsRemaining: 6)
    }

    private static func bringToFront(attemptsRemaining: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let application = NSApplication.shared

            if let settingsWindow = application.windows.first(where: {
                $0.canBecomeKey && $0.styleMask.contains(.titled)
            }) {
                settingsWindow.makeKeyAndOrderFront(nil)
                settingsWindow.orderFrontRegardless()
                application.activate(ignoringOtherApps: true)
                return
            }

            if attemptsRemaining > 1 {
                bringToFront(attemptsRemaining: attemptsRemaining - 1)
            }
        }
    }
}
