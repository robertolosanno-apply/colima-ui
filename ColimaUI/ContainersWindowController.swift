//
//  ContainersWindowController.swift
//  ColimaUI
//
//  Created by Roberto Losanno on 16/02/2026.
//

import AppKit
import SwiftUI

/// Presents a single window showing the list of Docker containers (Docker Desktop–style).
/// Reuses the same window when opened multiple times.
final class ContainersWindowController {

    /// Width sized to fit table columns (Name + Image + Status + Actions) without horizontal scroll.
    private static let windowWidth: CGFloat = 760
    private static let windowHeight: CGFloat = 420
    /// Minimum width so the Actions column remains visible when resized.
    private static let minWidth: CGFloat = 620
    private static let minHeight: CGFloat = 240

    private var window: NSWindow?

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            return
        }
        let content = ContainersView()
        let hosting = NSHostingView(rootView: content)
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.windowWidth, height: Self.windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        w.title = "Containers"
        w.contentView = hosting
        w.center()
        w.minSize = NSSize(width: Self.minWidth, height: Self.minHeight)
        w.isReleasedWhenClosed = false
        window = w
        w.makeKeyAndOrderFront(nil)
    }
}
