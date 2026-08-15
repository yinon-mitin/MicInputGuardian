import Foundation

enum InputPolicy: String, CaseIterable, Identifiable {
    case outputTriggeredRule
    case fixedDevice
    case systemManaged

    var id: String { rawValue }

    var title: String {
        switch self {
        case .outputTriggeredRule:
            return "Output-triggered rule"
        case .fixedDevice:
            return "Keep selected input"
        case .systemManaged:
            return "System managed"
        }
    }
}

enum PolicyNoChangeReason: Equatable {
    case automationDisabled
    case systemManaged
    case ruleNotConfigured
    case triggerOutputUnavailable
    case ruleInputUnavailable
    case selectedInputUnavailable
}

enum PolicyResolution: Equatable {
    case setInput(uid: String)
    case noChange(PolicyNoChangeReason)
}

enum PolicyEvaluator {
    static func resolve(
        policy: InputPolicy,
        automationEnabled: Bool,
        triggerOutputUID: String?,
        ruleInputUID: String?,
        selectedDeviceUID: String?,
        inputDevices: [AudioDevice],
        outputDevices: [AudioDevice]
    ) -> PolicyResolution {
        guard automationEnabled else {
            return .noChange(.automationDisabled)
        }

        switch policy {
        case .systemManaged:
            return .noChange(.systemManaged)

        case .outputTriggeredRule:
            guard let triggerOutputUID, let ruleInputUID else {
                return .noChange(.ruleNotConfigured)
            }
            guard outputDevices.contains(where: {
                $0.hasOutput && $0.uid == triggerOutputUID
            }) else {
                return .noChange(.triggerOutputUnavailable)
            }
            guard inputDevices.contains(where: {
                $0.hasInput && $0.uid == ruleInputUID
            }) else {
                return .noChange(.ruleInputUnavailable)
            }
            return .setInput(uid: ruleInputUID)

        case .fixedDevice:
            guard
                let selectedDeviceUID,
                inputDevices.contains(where: { $0.hasInput && $0.uid == selectedDeviceUID })
            else {
                return .noChange(.selectedInputUnavailable)
            }
            return .setInput(uid: selectedDeviceUID)
        }
    }
}
