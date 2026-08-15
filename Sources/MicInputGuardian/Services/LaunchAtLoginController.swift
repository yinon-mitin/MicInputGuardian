import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var requiresApproval = false
    @Published private(set) var errorMessage: String?

    private let service = SMAppService.mainApp

    init() {
        refresh()
    }

    func setEnabled(_ shouldEnable: Bool) {
        errorMessage = nil

        do {
            if shouldEnable {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        refresh(preservingError: true)
    }

    func refresh() {
        refresh(preservingError: false)
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private func refresh(preservingError: Bool) {
        if !preservingError {
            errorMessage = nil
        }

        switch service.status {
        case .enabled:
            isEnabled = true
            requiresApproval = false
        case .requiresApproval:
            isEnabled = true
            requiresApproval = true
        case .notRegistered:
            isEnabled = false
            requiresApproval = false
        case .notFound:
            isEnabled = false
            requiresApproval = false
            if errorMessage == nil {
                errorMessage = "Install the app in Applications before enabling launch at login."
            }
        @unknown default:
            isEnabled = false
            requiresApproval = false
        }
    }
}
