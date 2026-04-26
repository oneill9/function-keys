import AppKit
import Combine
import Foundation

@MainActor
final class FunctionKeyState: ObservableObject {
    @Published var standardFunctionKeys: Bool {
        didSet {
            guard standardFunctionKeys != oldValue else { return }
            guard !isRefreshingFromSystem else { return }
            let confirmedValue = store.setStandardFunctionKeysEnabled(standardFunctionKeys)
            guard confirmedValue != standardFunctionKeys else { return }

            isRefreshingFromSystem = true
            standardFunctionKeys = confirmedValue
            isRefreshingFromSystem = false
        }
    }

    private let store: FunctionKeyPreferences
    private var refreshTimer: Timer?
    private var isRefreshingFromSystem = false

    init(store: FunctionKeyPreferences = DefaultsFunctionKeyPreferences()) {
        self.store = store
        self.standardFunctionKeys = store.standardFunctionKeysEnabled()
        startRefreshing()
    }

    var menuTitle: String {
        standardFunctionKeys ? "Fn: F1-F12" : "Fn: Media"
    }

    var modeTitle: String {
        standardFunctionKeys ? "F1, F2 as Standard Keys" : "Media Keys"
    }

    func refresh() {
        let currentValue = store.standardFunctionKeysEnabled()
        guard standardFunctionKeys != currentValue else { return }

        isRefreshingFromSystem = true
        standardFunctionKeys = currentValue
        isRefreshingFromSystem = false
    }

    func toggleMode() {
        standardFunctionKeys.toggle()
    }

    func setMode(standardFunctionKeys enabled: Bool) {
        standardFunctionKeys = enabled
    }

    func openKeyboardSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startRefreshing() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

}

protocol FunctionKeyPreferences {
    func standardFunctionKeysEnabled() -> Bool
    @discardableResult
    func setStandardFunctionKeysEnabled(_ enabled: Bool) -> Bool
}

struct DefaultsFunctionKeyPreferences: FunctionKeyPreferences {
    private let key = "com.apple.keyboard.fnState" as CFString

    func standardFunctionKeysEnabled() -> Bool {
        guard let value = CFPreferencesCopyValue(
            key,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        ) else {
            return false
        }

        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return CFBooleanGetValue((value as! CFBoolean))
        }

        if CFGetTypeID(value) == CFNumberGetTypeID() {
            var intValue: Int32 = 0
            CFNumberGetValue((value as! CFNumber), .sInt32Type, &intValue)
            return intValue != 0
        }

        return false
    }

    @discardableResult
    func setStandardFunctionKeysEnabled(_ enabled: Bool) -> Bool {
        CFPreferencesSetValue(
            key,
            enabled ? kCFBooleanTrue : kCFBooleanFalse,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
        CFPreferencesSynchronize(
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
        notifyKeyboardPreferenceChanged()
        return standardFunctionKeysEnabled()
    }

    private func notifyKeyboardPreferenceChanged() {
        DistributedNotificationCenter.default().post(
            name: Notification.Name("AppleKeyboardPreferencesChangedNotification"),
            object: nil
        )
    }
}
