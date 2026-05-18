//
//  DropStats.swift
//  crane
//
//  Cheap, in-memory aggregates over a `[Drop]` array. Used by the menu-bar
//  dashboard. These used to hang off `DropsStore` but live as a free
//  extension now that SwiftData's `@Query` is the source of truth — any
//  view holding the (already-sorted) drops array can ask for stats
//  without going through a shared store.
//

import Foundation

extension Array where Element == Drop {

    /// Number of drops whose timestamp falls on the user's current day.
    var todayCount: Int {
        let cal = Calendar.current
        return reduce(into: 0) { count, drop in
            if cal.isDateInToday(drop.timestamp) { count += 1 }
        }
    }

    /// Consecutive day count ending today where at least one drop exists.
    /// If today has no drops, the streak is 0. If today has drops but
    /// yesterday doesn't, the streak is 1, etc.
    var streakDays: Int {
        let cal = Calendar.current
        let buckets = Set(map { cal.startOfDay(for: $0.timestamp) })
        guard !buckets.isEmpty else { return 0 }

        var streak = 0
        var cursor = cal.startOfDay(for: Date())
        while buckets.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Drops bucketed by day for the last `days` days, oldest-first,
    /// zero-filled for empty days. Ideal as Swift Charts input.
    func dailyCounts(days: Int) -> [(date: Date, count: Int)] {
        guard days > 0 else { return [] }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        var counts: [Date: Int] = [:]
        for drop in self {
            let day = cal.startOfDay(for: drop.timestamp)
            counts[day, default: 0] += 1
        }

        return (0..<days).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (date: day, count: counts[day] ?? 0)
        }
    }

    /// Split of the array into thoughts vs. links, for the dashboard's
    /// type-breakdown bar.
    var typeBreakdown: (thoughts: Int, links: Int) {
        var thoughts = 0
        var links = 0
        for drop in self {
            switch drop.dropType {
            case .thought: thoughts += 1
            case .link:    links += 1
            }
        }
        return (thoughts, links)
    }
}
