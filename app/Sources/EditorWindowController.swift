//
//  EditorWindowController.swift
//  FracTile
//
//  Deprecated shim - import/editor window removed for v0. Kept as a no-op in case other modules reference it.
//

import AppKit

@available(*, deprecated, message: "EditorWindowController removed — use GridEditorOverlayController for editing instead.")
final class EditorWindowController {
    static let shared = EditorWindowController()

    private init() {}

    func showEditor() {
        // No-op: editor window removed for v0. If you need an editor, use GridEditorOverlayController.
    }
}
