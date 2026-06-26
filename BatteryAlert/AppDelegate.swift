import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var batteryMonitor: BatteryMonitor!
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        setupStatusItem()

        batteryMonitor = BatteryMonitor { [weak self] pct, charging in
            self?.updateStatusIcon(percentage: pct, isCharging: charging)
            AlertManager.shared.evaluate(percentage: pct, isCharging: charging)
        }
        batteryMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        batteryMonitor.stop()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let img = NSImage(systemSymbolName: "battery.50", accessibilityDescription: "Battery")
            img?.isTemplate = true
            button.image = img
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 400)
        popover.behavior = .transient
        popover.contentViewController = PopoverViewController()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover.isShown == true { self?.popover.performClose(nil) }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func updateStatusIcon(percentage: Int, isCharging: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let img = batteryIcon(percentage: percentage, isCharging: isCharging) {
                self.statusItem.button?.image = img
            }
            self.statusItem.button?.toolTip = "\(percentage)%\(isCharging ? " · Charging" : "")"
        }
    }
}

// MARK: - Battery icon

// macOS 26 removed battery.{0,25,50,75}.bolt; only battery.100.bolt remains.
// For partial-charge states we composite the fill symbol + bolt.fill overlay.
private func batteryIcon(percentage: Int, isCharging: Bool) -> NSImage? {
    let level: String
    switch percentage {
    case ..<10: level = "battery.0"
    case ..<35: level = "battery.25"
    case ..<60: level = "battery.50"
    case ..<85: level = "battery.75"
    default:    level = "battery.100"
    }

    // Not charging — plain fill icon
    if !isCharging {
        let img = NSImage(systemSymbolName: level, accessibilityDescription: nil)
        img?.isTemplate = true
        return img
    }

    // Full charge: dedicated bolt symbol exists and looks correct
    if percentage >= 85 {
        let img = NSImage(systemSymbolName: "battery.100.bolt", accessibilityDescription: nil)
        img?.isTemplate = true
        return img
    }

    // Partial charge: compose fill icon + small bolt to the right.
    // Both symbols render as black on clear, so the composite is a valid template mask.
    let size = NSSize(width: 25, height: 14)
    let composite = NSImage(size: size, flipped: false) { _ in
        NSImage(systemSymbolName: level,       accessibilityDescription: nil)?.draw(in: NSRect(x: 0,  y: 0, width: 19, height: 14))
        NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)?.draw(in: NSRect(x: 18, y: 1, width:  7, height: 12))
        return true
    }
    composite.isTemplate = true
    return composite
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound])
    }
}
