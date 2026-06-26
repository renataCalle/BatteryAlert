import Cocoa
import ServiceManagement

class PopoverViewController: NSViewController {

    private var lowSlider: NSSlider!
    private var highSlider: NSSlider!
    private var lowValueLabel: NSTextField!
    private var highValueLabel: NSTextField!
    private var lowSoundPicker: NSPopUpButton!
    private var highSoundPicker: NSPopUpButton!
    private var volumeSlider: NSSlider!
    private var volumeValueLabel: NSTextField!
    private var loginToggle: NSButton!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    // MARK: - Build

    private func buildUI() {
        let am = AlertManager.shared

        let title       = label("BatteryAlert", size: 13, bold: true)
        let sep1        = separator()
        let sep2        = separator()
        let sep3        = separator()
        let sep4        = separator()
        let sep5        = separator()

        lowValueLabel   = valueLabel("\(am.lowThreshold)%")
        highValueLabel  = valueLabel("\(am.highThreshold)%")

        lowSlider       = makeSlider(value: am.lowThreshold,  min: 5,  max: 50, action: #selector(lowChanged))
        highSlider      = makeSlider(value: am.highThreshold, min: 50, max: 95, action: #selector(highChanged))

        lowSoundPicker  = makeSoundPicker(selected: am.lowSound,  action: #selector(lowSoundChanged))
        highSoundPicker = makeSoundPicker(selected: am.highSound, action: #selector(highSoundChanged))

        let volPct = Int(am.alertVolume * 100)
        volumeValueLabel = valueLabel("\(volPct)%")
        volumeSlider = NSSlider(value: Double(volPct), minValue: 0, maxValue: 100, target: self, action: #selector(volumeChanged))
        volumeSlider.isContinuous = true

        let isLoginEnabled = SMAppService.mainApp.status == .enabled
        loginToggle = NSButton(checkboxWithTitle: "Start at login", target: self, action: #selector(loginToggleChanged))
        loginToggle.state = isLoginEnabled ? .on : .off

        let previewLowBtn  = NSButton(title: "Preview low alert",  target: self, action: #selector(previewLow))
        let previewHighBtn = NSButton(title: "Preview high alert", target: self, action: #selector(previewHigh))
        previewLowBtn.bezelStyle  = .rounded
        previewHighBtn.bezelStyle = .rounded
        let previewBtnRow = previewRow(previewLowBtn, previewHighBtn)

        let quitBtn = NSButton(title: "Quit BatteryAlert", target: self, action: #selector(quit))
        quitBtn.bezelStyle = .rounded

        let stack = NSStackView(views: [
            title,
            sep1,
            row(label("Low battery alert"), lowValueLabel),
            lowSlider,
            row(label("Sound"), lowSoundPicker),
            sep2,
            row(label("High battery alert"), highValueLabel),
            highSlider,
            row(label("Sound"), highSoundPicker),
            sep3,
            row(label("Alert volume"), volumeValueLabel),
            volumeSlider,
            sep4,
            previewBtnRow,
            sep5,
            loginToggle,
            quitBtn,
        ])
        stack.orientation          = .vertical
        stack.alignment            = .leading
        stack.spacing              = 7
        stack.edgeInsets           = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let fullWidth = stack.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Sliders and separators fill the width
            lowSlider.widthAnchor.constraint(equalTo:    stack.widthAnchor, constant: -28),
            highSlider.widthAnchor.constraint(equalTo:   stack.widthAnchor, constant: -28),
            volumeSlider.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),
            sep1.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),
            sep2.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),
            sep3.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),
            sep4.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),
            sep5.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),
            previewBtnRow.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),

            // Quit button right-aligned
            quitBtn.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -14),
        ])
        _ = fullWidth  // unused warning suppression
    }

    // MARK: - Factory helpers

    private func label(_ text: String, size: CGFloat = 12, bold: Bool = false) -> NSTextField {
        let tf = NSTextField(labelWithString: text)
        tf.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        return tf
    }

    private func valueLabel(_ text: String) -> NSTextField {
        let tf = NSTextField(labelWithString: text)
        tf.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        tf.alignment = .right
        tf.widthAnchor.constraint(equalToConstant: 36).isActive = true
        return tf
    }

    private func separator() -> NSBox {
        let b = NSBox(); b.boxType = .separator; return b
    }

    private func makeSlider(value: Int, min: Int, max: Int, action: Selector) -> NSSlider {
        NSSlider(value: Double(value), minValue: Double(min), maxValue: Double(max), target: self, action: action)
    }

    private func makeSoundPicker(selected: String, action: Selector) -> NSPopUpButton {
        let popup = NSPopUpButton()
        popup.addItems(withTitles: AlertManager.soundNames)
        popup.selectItem(withTitle: selected)
        popup.target = self
        popup.action = action
        popup.controlSize = .small
        popup.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        popup.widthAnchor.constraint(equalToConstant: 120).isActive = true
        return popup
    }

    private func row(_ left: NSView, _ right: NSView) -> NSView {
        let h = NSStackView(views: [left, right])
        h.orientation  = .horizontal
        h.distribution = .equalSpacing
        h.widthAnchor.constraint(greaterThanOrEqualToConstant: 230).isActive = true
        return h
    }

    private func previewRow(_ left: NSView, _ right: NSView) -> NSView {
        let h = NSStackView(views: [left, right])
        h.orientation  = .horizontal
        h.distribution = .fillEqually
        h.spacing      = 8
        h.widthAnchor.constraint(greaterThanOrEqualToConstant: 230).isActive = true
        return h
    }

    // MARK: - Actions

    @objc private func lowChanged() {
        let v = lowSlider.integerValue
        AlertManager.shared.lowThreshold = v
        lowValueLabel.stringValue = "\(v)%"
    }

    @objc private func highChanged() {
        let v = highSlider.integerValue
        AlertManager.shared.highThreshold = v
        highValueLabel.stringValue = "\(v)%"
    }

    private var volumePreviewTimer: Timer?

    @objc private func volumeChanged() {
        let v = volumeSlider.integerValue
        AlertManager.shared.alertVolume = Float(v) / 100.0
        volumeValueLabel.stringValue = "\(v)%"
        // Play a preview 0.4 s after dragging stops so it's not spammy
        volumePreviewTimer?.invalidate()
        volumePreviewTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
            AlertManager.shared.playPreview(AlertManager.shared.lowSound)
        }
    }

    @objc private func lowSoundChanged() {
        guard let name = lowSoundPicker.selectedItem?.title else { return }
        AlertManager.shared.lowSound = name
        AlertManager.shared.playPreview(name)
    }

    @objc private func highSoundChanged() {
        guard let name = highSoundPicker.selectedItem?.title else { return }
        AlertManager.shared.highSound = name
        AlertManager.shared.playPreview(name)
    }

    @objc private func previewLow() {
        AlertManager.shared.previewLowAlert()
    }

    @objc private func previewHigh() {
        AlertManager.shared.previewHighAlert()
    }

    @objc private func loginToggleChanged() {
        do {
            if loginToggle.state == .on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert if registration fails
            loginToggle.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
