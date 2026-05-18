//
//  Design.swift
//  crane
//
//  Shared design tokens for the Liquid Glass surfaces across the input bar,
//  history view, and menu-bar dashboard. Keeping them here lets every
//  surface share one motion language, one corner radius, and one edge
//  highlight so the app feels like a single coordinated system.
//

import SwiftUI

// MARK: - Motion tokens

extension Animation {
    /// View-to-view transitions (input <-> history, panel resize).
    static let craneSpring = Animation.spring(response: 0.35, dampingFraction: 0.82)

    /// Hover / press / small state changes that should snap.
    static let craneSnappy = Animation.spring(response: 0.22, dampingFraction: 0.86)

    /// Opacity-only fades; matches the existing 0.18s easeInOut.
    static let craneSubtle = Animation.easeInOut(duration: 0.18)
}

// MARK: - Metric tokens

enum DesignMetrics {
    /// Corner radius used by the input bar, history card, and dashboard card.
    static let surfaceCornerRadius: CGFloat = 22
}

// MARK: - Specular border

/// The faint top-leading highlight that gives Liquid Glass surfaces their
/// "edge light". Drawn as a 0.5pt linear-gradient stroke from a brighter
/// white at the top-leading corner to almost transparent at the bottom-
/// trailing corner. Pair with `.glassEffect(...)` on the same shape.
struct SpecularBorder: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.22),
                            .white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }
}

extension View {
    /// Apply the standard Liquid Glass edge highlight to the receiver,
    /// matching the rounded-rect shape used by the surface itself.
    func specularBorder(cornerRadius: CGFloat = DesignMetrics.surfaceCornerRadius) -> some View {
        modifier(SpecularBorder(cornerRadius: cornerRadius))
    }
}
