//
//  PreferencesViewController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import Cocoa

// PreferencesViewController.swift
// Simple preferences UI for FracTile / FancyZonesMac MVP.
// - Shows current modifier key settings for Snap and Multi-Zone modifiers
// - Allows changing them (via pop-up menus) and saving to UserDefaults
// - Exposes a toggle for "Ignore overlay mouse events" (affects overlay behavior)
// - Minimal, self-contained AppKit view controller suitable for presentation in a Preferences window

final class PreferencesViewController: NSViewController {

    // Keys for storing preferences in UserDefaults
    private enum Keys {
        static let snapModifier = "FracTile.SnapModifier"              // String, e.g. "Shift"
        static let multiZoneModifier = "FracTile.MultiZoneModifier"   // String, e.g. "Shift+Command"
        static let overlayIgnoresMouse = "FracTile.OverlayIgnoresMouse" // Bool
    }

    // Default values matching your choices
    private let defaultSnap = "Shift"                      // Snap = Shift
    private let defaultMulti = "Shift+Command"            // Multi-zone = Shift+Command

    // UI Controls
    private let snapLabel: NSTextField = {
        let field = NSTextField(labelWithString: "Snap modifier:")
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let snapPopup: NSPopUpButton = {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let multiLabel: NSTextField = {
        let field = NSTextField(labelWithString: "Multi-zone modifier:")
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let multiPopup: NSPopUpButton = {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let ignoresMouseCheckbox: NSButton = {
        let cb = NSButton(checkboxWithTitle: "Overlay ignores mouse events (click-through)", target: nil, action: nil)
        cb.translatesAutoresizingMaskIntoConstraints = false
        return cb
    }()

    private let saveButton: NSButton = {
        let button = NSButton(title: "Save", target: nil, action: #selector(savePressed(_:)))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let cancelButton: NSButton = {
        let button = NSButton(title: "Cancel", target: nil, action: #selector(cancelPressed(_:)))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPreferences()
    }

    private func setupUI() {
        view.addSubview(snapLabel)
        view.addSubview(snapPopup)
        view.addSubview(multiLabel)
        view.addSubview(multiPopup)
        view.addSubview(ignoresMouseCheckbox)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)

        // Populate modifier choices (common combos)
        let modifierChoices = [
            "Shift",
            "Control",
            "Option",
            "Command",
            "Shift+Command",
            "Control+Command",
            "Option+Command",
            "Shift+Option",
            "None"
        ]

        snapPopup.addItems(withTitles: modifierChoices)
        multiPopup.addItems(withTitles: modifierChoices)

        // Targets
        saveButton.target = self
        cancelButton.target = self

        // Layout
        let margin: CGFloat = 16
        NSLayoutConstraint.activate([
            snapLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: margin),
            snapLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),

            snapPopup.centerYAnchor.constraint(equalTo: snapLabel.centerYAnchor),
            snapPopup.leadingAnchor.constraint(equalTo: snapLabel.trailingAnchor, constant: 12),
            snapPopup.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -margin),

            multiLabel.topAnchor.constraint(equalTo: snapLabel.bottomAnchor, constant: 16),
            multiLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),

            multiPopup.centerYAnchor.constraint(equalTo: multiLabel.centerYAnchor),
            multiPopup.leadingAnchor.constraint(equalTo: multiLabel.trailingAnchor, constant: 12),
            multiPopup.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -margin),

            ignoresMouseCheckbox.topAnchor.constraint(equalTo: multiLabel.bottomAnchor, constant: 18),
            ignoresMouseCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            ignoresMouseCheckbox.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -margin),

            saveButton.topAnchor.constraint(equalTo: ignoresMouseCheckbox.bottomAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),

            cancelButton.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),

            // bottom anchor for intrinsic content size
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -margin)
        ])
    }

    private func loadPreferences() {
        let defaults = UserDefaults.standard
        let snap = defaults.string(forKey: Keys.snapModifier) ?? defaultSnap
        let multi = defaults.string(forKey: Keys.multiZoneModifier) ?? defaultMulti
        let ignoresMouse = defaults.bool(forKey: Keys.overlayIgnoresMouse) // default false

        // indexOfItem(withTitle:) returns Int (not Optional). Check against -1 for "not found".
        let idx = snapPopup.indexOfItem(withTitle: snap)
        if idx != -1 {
            snapPopup.selectItem(at: idx)
        } else {
            snapPopup.selectItem(withTitle: defaultSnap)
        }

        let idx2 = multiPopup.indexOfItem(withTitle: multi)
        if idx2 != -1 {
            multiPopup.selectItem(at: idx2)
        } else {
            multiPopup.selectItem(withTitle: defaultMulti)
        }

        ignoresMouseCheckbox.state = ignoresMouse ? .on : .off
    }

    @objc private func savePressed(_ sender: Any?) {
        let defaults = UserDefaults.standard
        let snapValue = snapPopup.titleOfSelectedItem ?? defaultSnap
        let multiValue = multiPopup.titleOfSelectedItem ?? defaultMulti
        let ignoresMouse = (ignoresMouseCheckbox.state == .on)

        defaults.set(snapValue, forKey: Keys.snapModifier)
        defaults.set(multiValue, forKey: Keys.multiZoneModifier)
        defaults.set(ignoresMouse, forKey: Keys.overlayIgnoresMouse)
        defaults.synchronize()

        // Notify other parts of the app about these changes
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil, userInfo: [
            Keys.snapModifier: snapValue,
            Keys.multiZoneModifier: multiValue,
            Keys.overlayIgnoresMouse: ignoresMouse
        ])

        // Close window (if presented in a window)
        view.window?.close()
    }

    @objc private func cancelPressed(_ sender: Any?) {
        view.window?.close()
    }
}

// Notification name for preference changes
extension Notification.Name {
    static let preferencesDidChange = Notification.Name("FracTile.PreferencesDidChange")
}
