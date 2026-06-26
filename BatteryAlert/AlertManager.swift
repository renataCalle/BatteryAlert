import Cocoa
import UserNotifications

class AlertManager {
    static let shared = AlertManager()
    private init() {}

    static let soundNames = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass",
        "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink",
    ]

    private var initialized = false
    private var lowFired = false
    private var highFired = false
    private var flashWindows: Set<NSWindow> = []

    var lowThreshold: Int {
        get { let v = UserDefaults.standard.integer(forKey: "lowThreshold");  return v == 0 ? 20 : v }
        set { UserDefaults.standard.set(newValue, forKey: "lowThreshold") }
    }

    var highThreshold: Int {
        get { let v = UserDefaults.standard.integer(forKey: "highThreshold"); return v == 0 ? 80 : v }
        set { UserDefaults.standard.set(newValue, forKey: "highThreshold") }
    }

    var lowSound: String {
        get { UserDefaults.standard.string(forKey: "lowSound") ?? "Basso" }
        set { UserDefaults.standard.set(newValue, forKey: "lowSound") }
    }

    var highSound: String {
        get { UserDefaults.standard.string(forKey: "highSound") ?? "Glass" }
        set { UserDefaults.standard.set(newValue, forKey: "highSound") }
    }

    var alertVolume: Float {
        get { UserDefaults.standard.object(forKey: "alertVolume") == nil ? 1.0 : UserDefaults.standard.float(forKey: "alertVolume") }
        set { UserDefaults.standard.set(newValue, forKey: "alertVolume") }
    }

    func evaluate(percentage: Int, isCharging: Bool) {
        let isLow  = !isCharging && percentage <= lowThreshold
        let isHigh =  isCharging && percentage >= highThreshold

        // On first call, seed the fired flags from current state without alerting.
        // This prevents an immediate alert when the app launches into an already-threshold state.
        guard initialized else {
            initialized = true
            lowFired    = isLow
            highFired   = isHigh
            return
        }

        if isLow {
            if !lowFired {
                lowFired = true
                fire(title: "Low Battery", body: "Battery is at \(percentage)%. Connect your charger.", sound: lowSound, flashColor: .systemRed)
            }
        } else {
            lowFired = false
        }

        if isHigh {
            if !highFired {
                highFired = true
                fire(title: "Battery Charged", body: "Battery is at \(percentage)%. You can unplug.", sound: highSound, flashColor: .systemGreen)
            }
        } else {
            highFired = false
        }
    }

    func previewLowAlert() {
        fire(title: "Low Battery", body: "Battery is at \(lowThreshold)%. Connect your charger.", sound: lowSound, flashColor: .systemRed)
    }

    func previewHighAlert() {
        fire(title: "Battery Charged", body: "Battery is at \(highThreshold)%. You can unplug.", sound: highSound, flashColor: .systemGreen)
    }

    func playPreview(_ name: String) {
        DispatchQueue.main.async { [weak self] in
            guard let sound = NSSound(named: NSSound.Name(name)) else { return }
            sound.volume = self?.alertVolume ?? 1.0
            sound.play()
        }
    }

    private func fire(title: String, body: String, sound: String, flashColor: NSColor) {
        sendNotification(title: title, body: body)
        playPreview(sound)
        flashScreen(color: flashColor)
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    private func flashScreen(color: NSColor) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for screen in NSScreen.screens {
                let win = NSWindow(
                    contentRect: screen.frame,
                    styleMask: .borderless,
                    backing: .buffered,
                    defer: false
                )
                win.backgroundColor = color
                win.alphaValue = 0
                win.level = NSWindow.Level(NSWindow.Level.screenSaver.rawValue + 1)
                win.ignoresMouseEvents = true
                win.isOpaque = false
                win.hasShadow = false
                win.isReleasedWhenClosed = false  // prevents double-release crash via autorelease pool
                win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                win.orderFrontRegardless()
                self.flashWindows.insert(win)

                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.12
                    win.animator().alphaValue = 0.55
                }) {
                    NSAnimationContext.runAnimationGroup({ ctx in
                        ctx.duration = 0.38
                        win.animator().alphaValue = 0
                    }) {
                        self.flashWindows.remove(win)
                        win.orderOut(nil)  // hide without releasing; ARC owns the lifetime
                    }
                }
            }
        }
    }
}
