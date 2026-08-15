import CoreAudio
import Foundation

struct CoreAudioServiceError: LocalizedError {
    let operation: String
    let status: OSStatus

    var errorDescription: String? {
        "\(operation) failed (CoreAudio status \(status))."
    }
}

final class CoreAudioService {
    static let systemObject = AudioObjectID(kAudioObjectSystemObject)

    func devices() throws -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        try check(
            AudioObjectGetPropertyDataSize(Self.systemObject, &address, 0, nil, &dataSize),
            operation: "Read audio device list size"
        )

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        guard count > 0 else { return [] }

        var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
        let readStatus = deviceIDs.withUnsafeMutableBytes { buffer in
            AudioObjectGetPropertyData(
                Self.systemObject,
                &address,
                0,
                nil,
                &dataSize,
                buffer.baseAddress!
            )
        }
        try check(readStatus, operation: "Read audio device list")

        return deviceIDs.compactMap { deviceID in
            guard
                let uid = stringProperty(
                    objectID: deviceID,
                    selector: kAudioDevicePropertyDeviceUID
                ),
                let name = stringProperty(
                    objectID: deviceID,
                    selector: kAudioObjectPropertyName
                )
            else {
                return nil
            }

            return AudioDevice(
                id: deviceID,
                uid: uid,
                name: name,
                hasInput: hasStreams(deviceID: deviceID, scope: kAudioObjectPropertyScopeInput),
                hasOutput: hasStreams(deviceID: deviceID, scope: kAudioObjectPropertyScopeOutput)
            )
        }
    }

    func defaultInputDeviceID() throws -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        try check(
            AudioObjectGetPropertyData(
                Self.systemObject,
                &address,
                0,
                nil,
                &dataSize,
                &deviceID
            ),
            operation: "Read default input"
        )

        return deviceID == kAudioObjectUnknown ? nil : deviceID
    }

    func setDefaultInputDevice(_ deviceID: AudioDeviceID) throws {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var mutableDeviceID = deviceID
        let dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        try check(
            AudioObjectSetPropertyData(
                Self.systemObject,
                &address,
                0,
                nil,
                dataSize,
                &mutableDeviceID
            ),
            operation: "Set default input"
        )
    }

    private func stringProperty(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector
    ) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)

        let status = AudioObjectGetPropertyData(
            objectID,
            &address,
            0,
            nil,
            &dataSize,
            &value
        )
        guard status == noErr, let value else { return nil }
        return value.takeUnretainedValue() as String
    }

    private func hasStreams(deviceID: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        return status == noErr && dataSize >= UInt32(MemoryLayout<AudioStreamID>.size)
    }

    private func check(_ status: OSStatus, operation: String) throws {
        guard status == noErr else {
            throw CoreAudioServiceError(operation: operation, status: status)
        }
    }
}
