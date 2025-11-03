//
//  PreferencesViewController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 11/1/25.
//

import Cocoa

// NOTE: this is an updated PreferencesViewController that includes a per-display layout chooser and Preview action.
// Drop this file into your project (replace the existing PreferencesViewController if present).
// It depends on DefaultLayouts, LayoutManager, ZoneEngine, and OverlayController already being in the project.

final class PreferencesViewController: NSViewController {
    // UI Controls
    private let displayLabel: NSTextField = {
        let textField = NSTextField(labelWithString: "Display:")
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    private let displayPopup: NSPopUpButton = {
        let popUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
        popUpButton.translatesAutoresizingMaskIntoConstraints = false
        return popUpButton
    }()

    private let layoutLabel: NSTextField = {
        let textField = NSTextField(labelWithString: "Layout:")
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    private let layoutPopup: NSPopUpButton = {
        let popUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
        popUpButton.translatesAutoresizingMaskIntoConstraints = false
        return popUpButton
    }()

    private let previewButton: NSButton = {
        let button = NSButton(title: "Preview on Display", target: nil, action: #selector(previewPressed(_:)))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        return button
    }()

    private let saveButton: NSButton = {
        let button = NSButton(title: "Save Selection", target: nil, action: #selector(savePressed(_:)))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        return button
    }()

    private let closeButton: NSButton = {
        let button = NSButton(title: "Close", target: nil, action: #selector(closePressed(_:)))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        return button
    }()

    // Internal state
    private var displays: [(id: Int, name: String, screen: NSScreen)] = []
    private var zoneSets: [ZoneSet] = DefaultLayouts.all

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        populateDisplays()
        populateLayoutPopup()
        loadCurrentSelection()
    }

    private func setupUI() {
        view.addSubview(displayLabel)
        view.addSubview(displayPopup)
        view.addSubview(layoutLabel)
        view.addSubview(layoutPopup)
        view.addSubview(previewButton)
        view.addSubview(saveButton)
        view.addSubview(closeButton)

        displayPopup.target = self
        displayPopup.action = #selector(displaySelectionChanged(_:))
        layoutPopup.target = self
        layoutPopup.action = #selector(layoutSelectionChanged(_:))
        previewButton.target = self
        saveButton.target = self
        closeButton.target = self

        let margin: CGFloat = 16
        NSLayoutConstraint.activate([
            displayLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: margin),
            displayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),

            displayPopup.centerYAnchor.constraint(equalTo: displayLabel.centerYAnchor),
            displayPopup.leadingAnchor.constraint(equalTo: displayLabel.trailingAnchor, constant: 12),
            displayPopup.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -margin),

            layoutLabel.topAnchor.constraint(equalTo: displayLabel.bottomAnchor, constant: 18),
            layoutLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),

            layoutPopup.centerYAnchor.constraint(equalTo: layoutLabel.centerYAnchor),
            layoutPopup.leadingAnchor.constraint(equalTo: layoutLabel.trailingAnchor, constant: 12),
            layoutPopup.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -margin),

            previewButton.topAnchor.constraint(equalTo: layoutLabel.bottomAnchor, constant: 22),
            previewButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),

            saveButton.centerYAnchor.constraint(equalTo: previewButton.centerYAnchor),
            saveButton.leadingAnchor.constraint(equalTo: previewButton.trailingAnchor, constant: 12),

            closeButton.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: 18),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
            closeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -margin)
        ])
    }

    private func populateDisplays() {
        displays = LayoutManager.shared.availableDisplays()
        displayPopup.removeAllItems()
        for display in displays {
            displayPopup.addItem(withTitle: display.name)
        }
        // select main screen by default
        if let mainIndex = displays.firstIndex(where: { $0.screen == NSScreen.main }) {
            displayPopup.selectItem(at: mainIndex)
        } else {
            displayPopup.selectItem(at: 0)
        }
    }

    private func populateLayoutPopup() {
        layoutPopup.removeAllItems()
        for zoneSet in zoneSets {
            // Use name as the menu title; store the id as representedObject for persistence
            let item = NSMenuItem(title: zoneSet.name, action: nil, keyEquivalent: "")
            item.representedObject = zoneSet.id
            layoutPopup.menu?.addItem(item)
        }
    }

    private func loadCurrentSelection() {
        // If we have a selected layout for the currently selected display, select it in the popup
        guard !displays.isEmpty else { return }
        let selectedDisplay = displays[displayPopup.indexOfSelectedItem]
        if let selectedId = LayoutManager.shared.selectedLayoutId(forDisplayID: selectedDisplay.id) {
            if let menuItem = layoutPopup.menu?.items.first(where: { ($0.representedObject as? String) == selectedId }) {
                layoutPopup.select(menuItem)
            }
        } else {
            // no persisted value -> select default (Grid 2×2) if exists
            if let defaultItem = layoutPopup.menu?.items.first(where: { $0.title == "Grid 2×2" }) {
                layoutPopup.select(defaultItem)
            } else {
                layoutPopup.selectItem(at: 0)
            }
        }
    }

    @objc private func displaySelectionChanged(_ sender: Any?) {
        loadCurrentSelection()
    }

    @objc private func layoutSelectionChanged(_ sender: Any?) {
        // no-op for now; user must click Save to persist. You may choose to auto-save here.
    }

    @objc private func previewPressed(_ sender: Any?) {
        guard !displays.isEmpty else { return }
        let selectedDisplay = displays[displayPopup.indexOfSelectedItem]
        guard let selectedItem = layoutPopup.selectedItem else { return }
        // find ZoneSet by id or name
        let selectedId = (selectedItem.representedObject as? String) ?? selectedItem.title
        let zoneSet = DefaultLayouts.all.first(where: { $0.id == selectedId || $0.name == selectedId }) ?? DefaultLayouts.all.first!
        LayoutManager.shared.preview(zoneSet: zoneSet, on: selectedDisplay.screen)
    }

    @objc private func savePressed(_ sender: Any?) {
        guard !displays.isEmpty else { return }
        let selectedDisplay = displays[displayPopup.indexOfSelectedItem]
        guard let selectedItem = layoutPopup.selectedItem else { return }
        let selectedId = (selectedItem.representedObject as? String) ?? selectedItem.title
        LayoutManager.shared.setSelectedLayout(selectedId, forDisplayID: selectedDisplay.id)
        // Show a small confirmation alert
        let alert = NSAlert()
        alert.messageText = "Saved"
        alert.informativeText = "Saved layout '\(selectedItem.title)' for \(selectedDisplay.name)."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func closePressed(_ sender: Any?) {
        view.window?.close()
    }
}
