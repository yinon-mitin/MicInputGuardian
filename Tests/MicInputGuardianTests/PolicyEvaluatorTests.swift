import XCTest
@testable import MicInputGuardian

final class PolicyEvaluatorTests: XCTestCase {
    private let microphone = AudioDevice(
        id: 1,
        uid: "preferred-mic",
        name: "Preferred Microphone",
        hasInput: true,
        hasOutput: false
    )

    private let triggerOutput = AudioDevice(
        id: 2,
        uid: "trigger-output",
        name: "Wireless Headphones",
        hasInput: false,
        hasOutput: true
    )

    func testOutputRuleSelectsConfiguredMicrophoneWhenTriggerIsConnected() {
        let result = resolve(
            policy: .outputTriggeredRule,
            triggerOutputUID: triggerOutput.uid,
            ruleInputUID: microphone.uid,
            outputDevices: [triggerOutput]
        )

        XCTAssertEqual(result, .setInput(uid: microphone.uid))
    }

    func testOutputRuleDoesNothingWhenTriggerIsAbsent() {
        let result = resolve(
            policy: .outputTriggeredRule,
            triggerOutputUID: triggerOutput.uid,
            ruleInputUID: microphone.uid,
            outputDevices: []
        )

        XCTAssertEqual(result, .noChange(.triggerOutputUnavailable))
    }

    func testOutputRuleRequiresBothSelections() {
        let result = resolve(
            policy: .outputTriggeredRule,
            triggerOutputUID: nil,
            ruleInputUID: microphone.uid,
            outputDevices: [triggerOutput]
        )

        XCTAssertEqual(result, .noChange(.ruleNotConfigured))
    }

    func testOutputRuleUsesUIDInsteadOfDisplayName() {
        let sameNameDifferentDevice = AudioDevice(
            id: 3,
            uid: "different-output",
            name: triggerOutput.name,
            hasInput: false,
            hasOutput: true
        )
        let result = resolve(
            policy: .outputTriggeredRule,
            triggerOutputUID: triggerOutput.uid,
            ruleInputUID: microphone.uid,
            outputDevices: [sameNameDifferentDevice]
        )

        XCTAssertEqual(result, .noChange(.triggerOutputUnavailable))
    }

    func testDisabledAutomationNeverChangesTheInput() {
        let result = PolicyEvaluator.resolve(
            policy: .outputTriggeredRule,
            automationEnabled: false,
            triggerOutputUID: triggerOutput.uid,
            ruleInputUID: microphone.uid,
            selectedDeviceUID: nil,
            inputDevices: [microphone],
            outputDevices: [triggerOutput]
        )

        XCTAssertEqual(result, .noChange(.automationDisabled))
    }

    func testFixedPolicyUsesRememberedDevice() {
        let result = resolve(
            policy: .fixedDevice,
            selectedDeviceUID: microphone.uid
        )

        XCTAssertEqual(result, .setInput(uid: microphone.uid))
    }

    func testSystemManagedPolicyNeverChangesTheInput() {
        let result = resolve(
            policy: .systemManaged,
            triggerOutputUID: triggerOutput.uid,
            ruleInputUID: microphone.uid,
            selectedDeviceUID: microphone.uid,
            outputDevices: [triggerOutput]
        )

        XCTAssertEqual(result, .noChange(.systemManaged))
    }

    private func resolve(
        policy: InputPolicy,
        triggerOutputUID: String? = nil,
        ruleInputUID: String? = nil,
        selectedDeviceUID: String? = nil,
        outputDevices: [AudioDevice] = []
    ) -> PolicyResolution {
        PolicyEvaluator.resolve(
            policy: policy,
            automationEnabled: true,
            triggerOutputUID: triggerOutputUID,
            ruleInputUID: ruleInputUID,
            selectedDeviceUID: selectedDeviceUID,
            inputDevices: [microphone],
            outputDevices: outputDevices
        )
    }
}
