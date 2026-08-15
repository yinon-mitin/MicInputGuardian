import SwiftUI

struct SettingsView: View {
    @ObservedObject var controller: AudioController

    var body: some View {
        Form {
            Section("Automation") {
                Toggle(
                    "Automatically apply the selected policy",
                    isOn: Binding(
                        get: { controller.automationEnabled },
                        set: controller.setAutomationEnabled
                    )
                )

                Picker(
                    "Policy",
                    selection: Binding(
                        get: { controller.policy },
                        set: controller.setPolicy
                    )
                ) {
                    ForEach(InputPolicy.allCases) { policy in
                        Text(policy.title).tag(policy)
                    }
                }
            }

            if controller.policy == .outputTriggeredRule {
                Section("Output-triggered rule") {
                    Picker(
                        "When this output is connected",
                        selection: Binding(
                            get: { controller.triggerOutputUID },
                            set: controller.setTriggerOutputUID
                        )
                    ) {
                        Text("Choose an output…").tag(nil as String?)
                        ForEach(controller.outputDevices) { device in
                            Text(device.name).tag(Optional(device.uid))
                        }
                    }

                    Picker(
                        "Use this microphone",
                        selection: Binding(
                            get: { controller.ruleInputUID },
                            set: controller.setRuleInputUID
                        )
                    ) {
                        Text("Choose a microphone…").tag(nil as String?)
                        ForEach(controller.inputDevices) { device in
                            Text(device.name).tag(Optional(device.uid))
                        }
                    }

                    Text("When the selected output is absent, Mic Input Guardian leaves the system default unchanged.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if controller.policy == .fixedDevice {
                Section("Fixed microphone") {
                    Picker(
                        "Microphone",
                        selection: Binding(
                            get: { controller.selectedDeviceUID },
                            set: selectFixedInput
                        )
                    ) {
                        Text("Choose a microphone…").tag(nil as String?)
                        ForEach(controller.inputDevices) { device in
                            Text(device.name).tag(Optional(device.uid))
                        }
                    }
                }
            }

            Section("Status") {
                LabeledContent("Current input", value: controller.currentInputName)
                LabeledContent("Automation", value: controller.statusMessage)

                Button("Refresh Devices") {
                    controller.refreshNow()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 430)
    }

    private func selectFixedInput(_ uid: String?) {
        guard
            let uid,
            let device = controller.inputDevices.first(where: { $0.uid == uid })
        else {
            return
        }
        controller.selectInput(device)
    }
}
