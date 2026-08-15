import Combine
import CoreAudio
import Foundation

final class AudioController: ObservableObject {
    @Published private(set) var inputDevices: [AudioDevice] = []
    @Published private(set) var outputDevices: [AudioDevice] = []
    @Published private(set) var currentInputUID: String?
    @Published private(set) var statusMessage = "Starting…"
    @Published private(set) var policy: InputPolicy
    @Published private(set) var triggerOutputUID: String?
    @Published private(set) var ruleInputUID: String?
    @Published private(set) var selectedDeviceUID: String?
    @Published private(set) var automationEnabled: Bool

    private enum DefaultsKey {
        static let policy = "inputPolicy"
        static let triggerOutputUID = "triggerOutputUID"
        static let ruleInputUID = "ruleInputUID"
        static let selectedDeviceUID = "selectedDeviceUID"
        static let automationEnabled = "automationEnabled"
    }

    private let audioService: CoreAudioService
    private let defaults: UserDefaults
    private var refreshWorkItem: DispatchWorkItem?

    private let observedAddresses = [
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        ),
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        ),
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    ]

    private lazy var propertyListener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        self?.scheduleRefresh()
    }

    init(
        audioService: CoreAudioService = CoreAudioService(),
        defaults: UserDefaults = .standard
    ) {
        self.audioService = audioService
        self.defaults = defaults

        let storedPolicy = defaults.string(forKey: DefaultsKey.policy)
            .flatMap(InputPolicy.init(rawValue:))
        policy = storedPolicy ?? .systemManaged
        triggerOutputUID = defaults.string(forKey: DefaultsKey.triggerOutputUID)
        ruleInputUID = defaults.string(forKey: DefaultsKey.ruleInputUID)
        selectedDeviceUID = defaults.string(forKey: DefaultsKey.selectedDeviceUID)

        if defaults.object(forKey: DefaultsKey.automationEnabled) == nil {
            automationEnabled = true
        } else {
            automationEnabled = defaults.bool(forKey: DefaultsKey.automationEnabled)
        }

        installListeners()
        refreshNow()
    }

    deinit {
        refreshWorkItem?.cancel()
        for var address in observedAddresses {
            AudioObjectRemovePropertyListenerBlock(
                CoreAudioService.systemObject,
                &address,
                .main,
                propertyListener
            )
        }
    }

    var currentInputName: String {
        guard let currentInputUID else { return "Unavailable" }
        return inputDevices.first(where: { $0.uid == currentInputUID })?.name ?? "Unavailable"
    }

    func setPolicy(_ newPolicy: InputPolicy) {
        policy = newPolicy
        defaults.set(newPolicy.rawValue, forKey: DefaultsKey.policy)
        applyPolicy()
    }

    func setTriggerOutputUID(_ uid: String?) {
        triggerOutputUID = uid
        storeOptional(uid, forKey: DefaultsKey.triggerOutputUID)
        applyPolicy()
    }

    func setRuleInputUID(_ uid: String?) {
        ruleInputUID = uid
        storeOptional(uid, forKey: DefaultsKey.ruleInputUID)
        applyPolicy()
    }

    func selectInput(_ device: AudioDevice) {
        selectedDeviceUID = device.uid
        defaults.set(device.uid, forKey: DefaultsKey.selectedDeviceUID)

        policy = .fixedDevice
        defaults.set(InputPolicy.fixedDevice.rawValue, forKey: DefaultsKey.policy)
        applyPolicy()
    }

    func setAutomationEnabled(_ isEnabled: Bool) {
        automationEnabled = isEnabled
        defaults.set(isEnabled, forKey: DefaultsKey.automationEnabled)
        applyPolicy()
    }

    func refreshNow() {
        refreshWorkItem?.cancel()

        do {
            let devices = try audioService.devices()
            inputDevices = devices
                .filter(\.hasInput)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            outputDevices = devices.filter(\.hasOutput)

            if let defaultInputID = try audioService.defaultInputDeviceID() {
                currentInputUID = inputDevices.first(where: { $0.id == defaultInputID })?.uid
            } else {
                currentInputUID = nil
            }

            applyPolicy()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func installListeners() {
        for var address in observedAddresses {
            AudioObjectAddPropertyListenerBlock(
                CoreAudioService.systemObject,
                &address,
                .main,
                propertyListener
            )
        }
    }

    private func scheduleRefresh() {
        refreshWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.refreshNow()
        }
        refreshWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
    }

    private func applyPolicy() {
        let resolution = PolicyEvaluator.resolve(
            policy: policy,
            automationEnabled: automationEnabled,
            triggerOutputUID: triggerOutputUID,
            ruleInputUID: ruleInputUID,
            selectedDeviceUID: selectedDeviceUID,
            inputDevices: inputDevices,
            outputDevices: outputDevices
        )

        switch resolution {
        case let .setInput(uid):
            guard let device = inputDevices.first(where: { $0.uid == uid }) else {
                statusMessage = "Selected input is unavailable"
                return
            }

            guard currentInputUID != uid else {
                statusMessage = "Input locked"
                return
            }

            do {
                try audioService.setDefaultInputDevice(device.id)
                currentInputUID = uid
                statusMessage = "Input switched"
            } catch {
                statusMessage = error.localizedDescription
            }

        case let .noChange(reason):
            switch reason {
            case .automationDisabled:
                statusMessage = "Automatic fixing is paused"
            case .systemManaged:
                statusMessage = "macOS controls the input"
            case .ruleNotConfigured:
                statusMessage = "Configure the rule in Settings"
            case .triggerOutputUnavailable:
                statusMessage = "Trigger output is not connected"
            case .ruleInputUnavailable:
                statusMessage = "Rule microphone is unavailable"
            case .selectedInputUnavailable:
                statusMessage = "Selected input is unavailable"
            }
        }
    }

    private func storeOptional(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
