//
//  craneApp.swift
//  crane
//
//  Created by Abhay Sharma on 2026-05-17.
//
//  Menu-bar-only entry. crane owns no SwiftUI windows: the capture overlay,
//  the onboarding card and the menu-bar dashboard are all AppKit glass panels
//  held by AppDelegate. That is deliberate — only a window crane owns can be
//  fully transparent, which is what lets `NSGlassEffectView` sample the desktop
//  and render real Liquid Glass. A `MenuBarExtra(.window)` keeps its own system
//  backing under the glass and flattens it into frost.
//

import SwiftUI
import SwiftData

@main
struct craneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // SwiftUI still requires at least one Scene. `Settings` creates no window
        // until it is opened, and under `.accessory` activation policy the main
        // menu is never drawn, so it never can be.
        //
        // The shared ModelContainer is installed on the hosting roots instead
        // (`OverlayController.attach` / `DashboardController.attach`). The old
        // `.commands` block is gone with the menu bar it lived in: every item was
        // either already duplicated in-view (⌘⇧Space is the global hotkey, ⌘⇧H and
        // ⌘F and ⌘Q are shortcuts inside the overlay, Reset is in the dashboard
        // footer) or, like Welcome Tour, unreachable. Those now live on the status
        // item's right-click menu.
        Settings {
            EmptyView()
        }
    }
}
