//
//  DashboardController.swift
//  crane
//
//  Owns the menu-bar dashboard panel. Mirrors `OnboardingController`: an
//  app-owned transparent `NSPanel` hosting SwiftUI inside `CraneGlassHost`,
//  so the dashboard renders the same AppKit Liquid Glass as the capture
//  overlay instead of the flat frost a `MenuBarExtra` window produced.
//

import AppKit
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class DashboardController {

    private static let margin = DesignMetrics.glassShadowMargin

    /// The visible card.
    static let glassSize = NSSize(
        width: DesignMetrics.dashboardWidth,
        height: DesignMetrics.dashboardHeight
    )
    /// The window: glass plus the transparent shadow gutter on every side.
    static let panelSize = GlassPanelGeometry.panelSize(forGlass: glassSize, margin: margin)

    /// Gap between the menu bar and the top of the card.
    private static let statusItemGap: CGFloat = 6
    /// Keeps the card off the screen edge when the icon sits in a corner.
    private static let screenEdgeMargin: CGFloat = 8

    /// Bumped on every `show()`. `DashboardView` watches this to recompute
    /// statistics: unlike `MenuBarExtra`, which rebuilt the view on each open,
    /// the hosting view here is built once and only ordered in and out, so
    /// `onAppear` fires exactly once for the process lifetime.
    private(set) var showToken = UUID()

    /// Anchor for positioning; set by `AppDelegate` once the status item exists.
    weak var statusItemButton: NSStatusBarButton?

    private let panel: DashboardPanel
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    var isVisible: Bool { panel.isVisible }

    init() {
        panel = DashboardPanel(initialSize: Self.panelSize)
        panel.onCancel = { [weak self] in self?.hide() }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.panel.isVisible else { return }
                self.position()
            }
        }
    }

    /// Installs the SwiftUI root. The view is sized to the *glass* rect;
    /// `CraneGlassHost` adds the gutter around it to reach the panel size.
    func attach() {
        let root = AnyView(
            DashboardView()
                .environment(self)
                .modelContainer(Persistence.container)
                // Fix the ideal size: a fully flexible SwiftUI root drives the
                // hosting view's Auto Layout and balloons the panel.
                .frame(width: Self.glassSize.width, height: Self.glassSize.height)
        )
        let host = NSHostingView(rootView: root)
        let container = CraneGlassHost.wrap(
            contentView: host,
            containerSize: Self.panelSize,
            margin: Self.margin
        )
        panel.contentView = container
    }

    // MARK: - Show / hide / toggle

    func toggle() {
        if panel.isVisible { hide() } else { show() }
    }

    func show() {
        showToken = UUID()
        position()
        // No `NSApp.activate` — a nonactivating panel takes key for clicks and
        // Esc without stealing activation from the user's frontmost app.
        panel.orderFrontRegardless()
        panel.makeKey()
        statusItemButton?.highlight(true)
        startDismissMonitors()
    }

    func hide() {
        stopDismissMonitors()
        statusItemButton?.highlight(false)
        panel.orderOut(nil)
    }

    /// Automated checks for the AppKit glass host (see `scripts/test-overlay-glass.sh`).
    @MainActor
    func verifyGlassSetupForTesting() -> OverlayGlassVerifier.Result {
        OverlayGlassVerifier.verify(
            window: panel,
            expectedContainerSize: Self.panelSize,
            margin: Self.margin,
            label: "dashboard"
        )
    }

    // MARK: - Layout

    /// Hangs the card under the status item. Positions the *glass* rect, then
    /// outsets to the panel frame — clamping the panel directly would count the
    /// 30pt gutter as part of the card and push a screen-edge card out of
    /// alignment with its icon.
    private func position() {
        guard let button = statusItemButton,
              let buttonWindow = button.window,
              let screen = buttonWindow.screen ?? NSScreen.main else {
            positionFallbackTopRight()
            return
        }

        // Status-item rect in screen coordinates — handles the notch, a second
        // display, and the user reordering menu-bar items.
        let inWindow = button.convert(button.bounds, to: nil)
        let onScreen = buttonWindow.convertToScreen(inWindow)

        var glass = NSRect(origin: .zero, size: Self.glassSize)
        glass.origin.x = (onScreen.midX - glass.width / 2).rounded()
        glass.origin.y = (onScreen.minY - Self.statusItemGap - glass.height).rounded()

        glass = GlassPanelGeometry.clamp(
            glass,
            to: screen.visibleFrame,
            margin: Self.screenEdgeMargin,
            minSize: Self.glassSize
        )

        panel.setFrame(
            GlassPanelGeometry.panelFrame(forGlass: glass, margin: Self.margin),
            display: true
        )
    }

    /// The status item has no window when it is pushed into the menu-bar
    /// overflow (a crowded notch, Bartender / Ice). Fall back to the corner the
    /// icon would have been in.
    private func positionFallbackTopRight() {
        guard let visible = (NSScreen.main ?? panel.screen)?.visibleFrame else { return }

        var glass = NSRect(origin: .zero, size: Self.glassSize)
        glass.origin.x = visible.maxX - glass.width - Self.screenEdgeMargin
        glass.origin.y = visible.maxY - glass.height - Self.statusItemGap

        glass = GlassPanelGeometry.clamp(
            glass,
            to: visible,
            margin: Self.screenEdgeMargin,
            minSize: Self.glassSize
        )

        panel.setFrame(
            GlassPanelGeometry.panelFrame(forGlass: glass, margin: Self.margin),
            display: true
        )
    }

    // MARK: - Dismissal

    private func startDismissMonitors() {
        guard globalClickMonitor == nil else { return }

        // Clicks in other apps.
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.hide()
            }
        }

        // Clicks inside crane but outside the card — a global monitor never sees
        // our own events. Returning the event keeps normal delivery intact.
        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self else { return event }
            // The status-item button toggles through its own action. Without this
            // the panel would close on mouseDown and reopen on mouseUp.
            if event.window === self.statusItemButton?.window { return event }
            if event.window !== self.panel { self.hide() }
            return event
        }
    }

    private func stopDismissMonitors() {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
    }
}
