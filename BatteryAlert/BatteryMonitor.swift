import Foundation
import IOKit
import IOKit.ps

// File-scope C-compatible callback — cannot capture state
private func powerSourceCallback(_ context: UnsafeMutableRawPointer?) {
    guard let ctx = context else { return }
    Unmanaged<BatteryMonitor>.fromOpaque(ctx).takeUnretainedValue().poll()
}

class BatteryMonitor {
    private var runLoopSource: CFRunLoopSource?
    private let onChange: (Int, Bool) -> Void

    init(onChange: @escaping (Int, Bool) -> Void) {
        self.onChange = onChange
    }

    func start() {
        poll()
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        guard let srcRef = IOPSNotificationCreateRunLoopSource(powerSourceCallback, ctx) else { return }
        let source = srcRef.takeRetainedValue()
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = nil
        }
    }

    func poll() {
        guard let info = readBattery() else { return }
        onChange(info.percentage, info.isCharging)
    }

    private func readBattery() -> (percentage: Int, isCharging: Bool)? {
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery"),
            &iter
        ) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iter) }

        let service = IOIteratorNext(iter)
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        var propsRef: Unmanaged<CFMutableDictionary>? = nil
        guard IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let props = propsRef?.takeRetainedValue() as? [String: Any]
        else { return nil }

        let current    = props["CurrentCapacity"] as? Int ?? 0
        let max        = props["MaxCapacity"]     as? Int ?? 100
        let isCharging = props["IsCharging"]      as? Bool ?? false

        let pct = max > 0 ? min(100, (current * 100) / max) : 0
        return (pct, isCharging)
    }
}
