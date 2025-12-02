//
//  EditorViewController.swift
//  FracTile
//
//  Created by Jacob Stringfellow on 10/31/25.
//

import Cocoa

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

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(infoLabel)

        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
        ])
    }
}
