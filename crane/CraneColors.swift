//
//  CraneColors.swift
//  crane
//
//  Brand palette from landing/styles.css — adaptive light/dark assets.
//  Asset names map to generated `Color.craneInk` etc. when the catalog
//  provides Swift symbols; this enum is the stable call site.
//

import SwiftUI

enum CraneColor {
    static let ink = Color("CraneInk")
    static let inkSecondary = Color("CraneInkSecondary")
    static let inkTertiary = Color("CraneInkTertiary")
    static let cream = Color("CraneCream")
    static let surface = Color("CraneSurface")
    static let thought = Color("CraneThought")
    static let link = Color("CraneLink")
    static let warning = Color("CraneWarning")
    static let accent = Color.accentColor

    static let accentSoft = accent.opacity(0.14)
    static let creamLine = cream.opacity(0.07)
    static let inkLine = ink.opacity(0.08)

    /// Capture-field insertion point: cream in dark mode, black in light mode.
    static func caret(for scheme: ColorScheme) -> Color {
        scheme == .dark ? cream : .black
    }
}
