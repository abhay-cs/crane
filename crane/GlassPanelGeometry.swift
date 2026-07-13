//
//  GlassPanelGeometry.swift
//  crane
//
//  The geometry contract every AppKit Liquid Glass panel shares (capture
//  overlay, onboarding card, menu-bar dashboard): the window is the glass
//  rect plus a transparent gutter on every side, so the glass drop shadow
//  follows the rounded shape instead of being clipped to the window bounds.
//

import AppKit

enum GlassPanelGeometry {

    /// Window size for a glass surface of `glass`, with the shadow gutter added.
    static func panelSize(
        forGlass glass: NSSize,
        margin: CGFloat = DesignMetrics.glassShadowMargin
    ) -> NSSize {
        NSSize(
            width: glass.width + margin * 2,
            height: glass.height + margin * 2
        )
    }

    /// Window frame whose `insetBy(margin)` rect is exactly `glass`.
    static func panelFrame(
        forGlass glass: NSRect,
        margin: CGFloat = DesignMetrics.glassShadowMargin
    ) -> NSRect {
        glass.insetBy(dx: -margin, dy: -margin)
    }

    /// Keeps `frame` fully inside `visible`, never shrinking below `minSize`.
    static func clamp(
        _ frame: NSRect,
        to visible: NSRect,
        margin: CGFloat,
        minSize: NSSize
    ) -> NSRect {
        var f = frame
        let maxW = max(minSize.width, visible.width - margin * 2)
        let maxH = max(minSize.height, visible.height - margin * 2)
        f.size.width = min(f.width, maxW)
        f.size.height = min(f.height, maxH)
        f.origin.x = min(
            max(f.origin.x, visible.minX + margin),
            visible.maxX - f.width - margin
        )
        f.origin.y = min(
            max(f.origin.y, visible.minY + margin),
            visible.maxY - f.height - margin
        )
        return f
    }
}
