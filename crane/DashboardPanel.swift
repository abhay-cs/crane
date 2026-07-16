//
//  DashboardPanel.swift
//  crane
//
//  Borderless, transparent panel behind the menu-bar icon. Same recipe as
//  `OverlayPanel` and the onboarding card: crane owns the window, so it can
//  be fully clear and let `NSGlassEffectView` sample the desktop directly.
//  A `MenuBarExtra(.window)` cannot — its system backing sits under the glass
//  and flattens it into frost.
//

import AppKit

final class DashboardPanel: NSPanel {

    /// Needed so the dashboard's buttons, scroll and Esc work. Deliberately not
    /// `canBecomeMain`: there is no field editor here, and staying non-main keeps
    /// the panel from pulling focus off the user's frontmost app.
    override var canBecomeKey: Bool { true }

    var onCancel: (() -> Void)?

    init(initialSize: NSSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isFloatingPanel = true
        // `.floating` (3), not `.statusBar` (25): the 30pt transparent shadow
        // gutter overlaps the menu bar when the card hangs under the icon, and
        // above the menu-bar level that gutter would smear the glass shadow
        // across it. At `.floating` the menu bar cleanly occludes the gutter.
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isMovableByWindowBackground = false
        animationBehavior = .utilityWindow
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        becomesKeyOnlyIfNeeded = false
        // Pinned per-panel rather than app-wide (`NSApp.appearance`), which would
        // also tint the status-item button and can hide the template icon in a
        // light menu bar.
        appearance = NSAppearance(named: .darkAqua)
        invalidateShadow()
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
