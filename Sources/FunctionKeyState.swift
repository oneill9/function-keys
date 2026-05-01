import AppKit
import Combine
import Foundation
import IOKit

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
            guard let self else { return }
            Task { @MainActor in
                self.refresh()
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
        applyHardwareKeyboardMode(enabled: enabled)
        return standardFunctionKeysEnabled()
    }

    private func notifyKeyboardPreferenceChanged() {
        typealias NotifyPostFn = @convention(c) (UnsafePointer<CChar>) -> UInt32
        let handle = dlopen("/usr/lib/system/libsystem_notify.dylib", RTLD_LAZY)
        defer { dlclose(handle) }
        guard let sym = dlsym(handle, "notify_post") else { return }
        let fn = unsafeBitCast(sym, to: NotifyPostFn.self)
        _ = "com.apple.keyboard.fnstatedidchange".withCString { fn($0) }
    }

    private func applyHardwareKeyboardMode(enabled: Bool) {
        #if compiler(>=5.5) && canImport(IOKit)
        let port = kIOMainPortDefault
        #else
        let port = kIOMasterPortDefault
        #endif
        let handle = IORegistryEntryFromPath(port, "IOService:/IOResources/IOHIDSystem")
        guard handle != .zero else { return }
        defer { IOObjectRelease(handle) }

        var service: io_connect_t = .zero
        guard IOServiceOpen(handle, mach_task_self_, 1, &service) == KERN_SUCCESS else { return }
        defer { IOServiceClose(service) }

        typealias IOHIDSetCFTypeParameterFn = @convention(c) (io_connect_t, CFString, CFTypeRef) -> kern_return_t
        let dylibHandle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY)
        guard dylibHandle != nil else { return }
        defer { dlclose(dylibHandle) }

        guard let sym = dlsym(dylibHandle, "IOHIDSetCFTypeParameter") else { return }
        let IOHIDSetCFTypeParameter = unsafeBitCast(sym, to: IOHIDSetCFTypeParameterFn.self)

        let value = (enabled ? 1 : 0) as CFNumber
        _ = IOHIDSetCFTypeParameter(service, "HIDFKeyMode" as CFString, value)
    }
}
