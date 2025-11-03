//
//  EditorViewController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import Cocoa
import UniformTypeIdentifiers

final class EditorViewController: NSViewController {

    private let infoLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Grid Editor (placeholder)\nConfigure grid layouts here.")
        label.alignment = .center
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        return label
    }()

    private let importButton: NSButton = {
        let button = NSButton(title: "Import FancyZones JSON…", target: nil, action: #selector(importJSON(_:)))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(infoLabel)
        view.addSubview(importButton)

        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            importButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            importButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        importButton.target = self
    }

    @objc private func importJSON(_ sender: Any?) {
        let dlg = NSOpenPanel()
        dlg.allowedContentTypes = [.json]
        dlg.allowsMultipleSelection = false
        dlg.canChooseDirectories = false
        dlg.title = "Import FancyZones layout JSON"
        dlg.begin { result in
            if result == .OK, let url = dlg.url {
                self.handleImportedJSON(url: url)
            }
        }
    }

    private func handleImportedJSON(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let alert = NSAlert()
            alert.messageText = "Imported JSON"
            alert.informativeText = "Imported \(url.lastPathComponent) (\(data.count) bytes). We'll parse this into grid layout in a later step."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
}
