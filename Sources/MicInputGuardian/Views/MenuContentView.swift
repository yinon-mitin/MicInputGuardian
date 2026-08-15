import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var controller: AudioController
    @ObservedObject var launchAtLoginController: LaunchAtLoginController
    @ObservedObject var settingsWindowPresenter: SettingsWindowPresenter

    var body: some View {
        Text("Input: \(shortTitle(controller.currentInputName))")
        Text(shortTitle(controller.statusMessage))

        Divider()

        Toggle(
            "Automatic fixing",
            isOn: Binding(
                get: { controller.automationEnabled },
                set: controller.setAutomationEnabled
            )
        )

        Menu("Policy") {
            ForEach(InputPolicy.allCases) { policy in
                Button {
                    controller.setPolicy(policy)
                } label: {
                    if controller.policy == policy {
                        Label(policy.title, systemImage: "checkmark")
                    } else {
                        Text(policy.title)
                    }
                }
            }
        }

        Divider()

        Text("Input devices")
        ForEach(controller.inputDevices) { device in
            Button {
                controller.selectInput(device)
            } label: {
                if controller.policy == .fixedDevice && controller.selectedDeviceUID == device.uid {
                    Label(shortTitle(device.name), systemImage: "checkmark")
                } else {
                    Text(shortTitle(device.name))
                }
            }
        }

        if controller.inputDevices.isEmpty {
            Text("No input devices found")
        }

        Divider()

        Button("Settings…") {
            settingsWindowPresenter.open(
                controller: controller,
                launchAtLoginController: launchAtLoginController
            )
        }
        .keyboardShortcut(",")

        Button("Refresh") {
            controller.refreshNow()
        }

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func shortTitle(_ value: String) -> String {
        guard value.count > 30 else { return value }
        return String(value.prefix(27)) + "…"
    }

}
