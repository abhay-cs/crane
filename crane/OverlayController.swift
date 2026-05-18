//
//  OverlayController.swift
//  crane
//
//  Owns the floating panel and the SwiftUI hierarchy hosted inside it.
//  Replaces the Rust `toggle_window` and view-state management that
//  the Tauri version handled by emitting "reset-to-input".
//

import AppKit
import SwiftUI
import SwiftData
import Observation

/// What's currently shown in the overlay panel.
enum OverlayView: Equatable {
    case input
    case history
}

@Observable
@MainActor
final class OverlayController {

    /// Logical sizes. Input panel hugs the 64pt capture pill with 12pt of
    /// transparent padding on each side; history keeps the original 480pt
    /// height so the list has room to scroll.
    static let inputSize  = NSSize(width: 620, height: 88)
    static let historySize = NSSize(width: 620, height: 480)

    /// Currently displayed view. Mutating this animates the panel resize.
    var currentView: OverlayView = .input {
        didSet { applySize(for: currentView, animated: true) }
    }

    private let panel: OverlayPanel
    private var hostingView: NSHostingView<AnyView>?

    init() {
        panel = OverlayPanel(initialSize: Self.inputSize)
        panel.onCancel = { [weak self] in self?.hide() }
    }

    /// Install the SwiftUI root once the controller is wired up — we pass
    /// `self` as an environment object so views can resize / dismiss, and
    /// attach the shared SwiftData `ModelContainer` so the input bar and
    /// history list see the same drops the menu-bar dashboard does.
    func attach(rootView: some View) {
        let wrapped = AnyView(
            rootView
                .environment(self)
                .modelContainer(Persistence.container)
        )
        let host = NSHostingView(rootView: wrapped)
        host.frame = NSRect(origin: .zero, size: panel.frame.size)
        host.autoresizingMask = [.width, .height]
        // macOS 26 gives NSHostingView a translucent material backing by
        // default, which shows up as a faint rounded rectangle behind the
        // input pill (visible in the 12pt padding around the bar and the
        // ~20pt of empty panel space below it). Force the backing layer
        // fully clear so only the pill's own `.glassEffect` is visible.
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        host.layer?.isOpaque = false
        panel.contentView = host
        hostingView = host
    }

    // MARK: - Show / Hide / Toggle

    func show() {
        // Always start in the input view (matches Tauri "reset-to-input").
        if currentView != .input {
            currentView = .input
        }
        positionOnActiveScreen()
        // orderFrontRegardless avoids needing app activation, since we run
        // as an Accessory app (no Dock icon).
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle() {
        if panel.isVisible { hide() } else { show() }
    }

    var isVisible: Bool { panel.isVisible }

    // MARK: - Layout

    /// Place the panel horizontally centered, vertically in the upper third
    /// (the Spotlight / Raycast resting position).
    private func positionOnActiveScreen() {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
            ?? NSScreen.main
            ?? panel.screen
        guard let visible = screen?.visibleFrame else { return }

        let size = panel.frame.size
        let x = visible.origin.x + (visible.width - size.width) / 2
        let y = visible.origin.y + visible.height - size.height - (visible.height * 0.28)
        panel.setFrameOrigin(NSPoint(x: x.rounded(), y: y.rounded()))
    }

    private func applySize(for view: OverlayView, animated: Bool) {
        let target = view == .input ? Self.inputSize : Self.historySize
        let current = panel.frame
        // Anchor to the top edge so the bar stays put while the panel grows
        // downward into the history list.
        let newOrigin = NSPoint(
            x: current.origin.x + (current.width - target.width) / 2,
            y: current.origin.y + (current.height - target.height)
        )
        let newFrame = NSRect(origin: newOrigin, size: target)
        panel.setFrame(newFrame, display: true, animate: animated)
    }
}
