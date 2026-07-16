# Two-binary product plan (crane + crane Lite)

**Goal:** Ship two separate macOS app binaries from one repo — a full build for Tahoe (26.4+) with Apple Intelligence tagging, and a plain offline Lite build for macOS 14–16 without AI.

**Status:** Planned — not started. Work through this document when beginning the split.

**Last updated:** 2026-05-20

---

## Executive summary

| Binary | Minimum macOS | Features | Deployment target |
|--------|---------------|----------|-------------------|
| **crane** (full) | 26.4 (Tahoe) | Capture, history, dashboard, FM auto-tagging | `26.4` |
| **crane Lite** | 14 (Sonoma) | Same core capture/history/dashboard, no AI | `14.0` |

Both are **fully offline** for capture and persistence. The full app calls **system** Apple Intelligence APIs (`FoundationModels`); models are not bundled in either binary.

Expected installed size for **both**: ~**2.5–2.7 MB** on disk (see [Size estimates](#size-estimates)). The split is about OS compatibility and features, not download weight.

---

## Why two binaries

The current app intentionally targets **macOS 26.4 only** (see `issues.md` P0-04): Tahoe-era SwiftUI, `NSHostingView` behavior, and `FoundationModels` for tagging.

A Lite build removes the 26.4 floor by:

- Dropping the AI module and `FoundationModels` link
- Lowering `MACOSX_DEPLOYMENT_TARGET` to 14.0
- Trimming AI-only UI (dashboard top tags, tag failure affordances)

Core product — **⌘⇧Space → type → Enter → back to work** — already works without AI.

---

## Product matrix

| Capability | crane (full) | crane Lite |
|------------|:------------:|:----------:|
| Global hotkey capture pill | ✅ | ✅ |
| Thought / link modes | ✅ | ✅ |
| History + search | ✅ | ✅ |
| Menu-bar dashboard (stats, sparkline, recents) | ✅ | ✅ |
| SwiftData local store | ✅ | ✅ |
| Auto topic tags (FM) | ✅ | ❌ |
| Dashboard “Top Tags” section | ✅ | ❌ |
| Search by tags (if tags exist on drops) | ✅ | ✅ (read-only) |
| Requires Apple Intelligence hardware/settings | For tags only | ❌ |

---

## Size estimates

Measured from a **Release** build of current `crane` (2026-05-20):

| Component | Size |
|-----------|------|
| Total `.app` | ~2.7 MB |
| Mach-O binary | ~1.6 MB |
| Bundled fonts (7 files) | ~950 KB |
| `Assets.car` + icon + plist | ~150 KB |

**Full vs Lite:** negligible difference (~50–100 KB less code in Lite). `FoundationModels` is a **system framework** — it is linked, not embedded. AI models live in the OS.

**User data** (not in `.app`): `~/Library/Application Support/com.abhaycs.crane/crane.store` (+ `-wal` / `-shm`). Grows with saved drops.

**Optional future diet (Lite only):** use system fonts instead of bundled Geist / Instrument Serif → could approach ~1.5–2 MB installed. Design tradeoff; not required for v1 Lite.

---

## Architecture approach

**One repo, two Xcode targets**, two `.app` products:

```
crane.xcodeproj
├── crane          → com.abhaycs.crane       (26.4+, AI)
└── crane Lite     → com.abhaycs.crane.lite (14.0+, no AI)
```

Shared sources: most of `crane/` (capture, overlay, persistence, dashboard minus tags, design system).

Lite-excluded or `#if CRANE_AI` gated:

| Path / symbol | Full | Lite |
|---------------|:----:|:----:|
| `crane/AI/*` | ✅ | ❌ |
| `TopTagsSection.swift` | ✅ | ❌ |
| `FoundationModels` (linked framework) | ✅ | ❌ |
| `AIJobQueue.shared.enqueue` in `ContentView` | ✅ | ❌ |
| `AITaggingCoordinator` in `AppDelegate` | ✅ | ❌ |
| Tag chips / “tagging failed” in `DropRow` | ✅ | optional hide |

### OS-specific guards

| Code | Action |
|------|--------|
| `OverlayController` NSHostingView clear-layer hack (macOS 26 default material backing) | Wrap in `#available(macOS 26, *)`; no-op on 14–16 |
| `menuBarExtraStyle(.window)` | Confirm availability on 14+ (expected OK); test on Sonoma |

---

## Data & schema

### Open decisions (pick before implementation)

1. **Bundle IDs**
   - Full: `com.abhaycs.crane` (existing)
   - Lite: `com.abhaycs.crane.lite` (recommended — both can coexist)

2. **Store path**
   - **Shared** (`com.abhaycs.crane` support dir for both): same drops if user installs both; confusing if schemas diverge
   - **Separate** (Lite uses `com.abhaycs.crane.lite`): isolated data; recommended for v1

3. **Schema strategy**
   - **A — Same `Drop` model (recommended for v1):** keep `tags`, `aiProcessedAt`, `aiTaggingFailed`; Lite never writes them. One `CraneMigrationPlan`, minimal churn.
   - **B — Lite schema without AI fields:** cleaner model, requires migration if user switches binaries on shared store.

4. **Display names**
   - Menu bar / Finder: e.g. **crane** vs **crane Lite**
   - App icons: same mark vs subtle “Lite” badge (optional)

---

## Implementation phases

### Phase 0 — Decisions

- [ ] Confirm bundle IDs, store paths, display names
- [ ] Confirm minimum Lite target: **14.0** (SwiftData floor) vs 15.0 only
- [ ] Choose compile-flag vs separate excluded file lists per target

### Phase 1 — Xcode target

- [ ] Duplicate target → **crane Lite**
- [ ] Set `MACOSX_DEPLOYMENT_TARGET = 14.0` on Lite
- [ ] Set `MACOSX_DEPLOYMENT_TARGET = 26.4` on full (unchanged)
- [ ] Add `CRANE_AI=1` / `CRANE_AI=0` Swift active compilation conditions (or equivalent excluded sources)
- [ ] Lite: remove `FoundationModels` from `OTHER_LDFLAGS`
- [ ] Separate `PRODUCT_BUNDLE_IDENTIFIER`, `PRODUCT_NAME`, app icon if needed

### Phase 2 — Strip AI from Lite

- [ ] Gate or exclude `crane/AI/*`
- [ ] `AppDelegate`: no `AITaggingCoordinator` / backfill when `CRANE_AI=0`
- [ ] `ContentView`: no `AIJobQueue.enqueue` after save
- [ ] `DashboardView`: remove `TopTagsSection` from Lite build
- [ ] `DropRow`: hide tag UI when `CRANE_AI=0` (or when `drop.tags.isEmpty && !CRANE_AI`)
- [ ] `DropStatistics`: skip `topTags` aggregation in Lite (or return empty)

### Phase 3 — Compatibility

- [ ] `#available` guard for macOS 26 `NSHostingView` workaround
- [ ] Build Lite with Xcode that supports macOS 14 SDK (or validate against deployment target)
- [ ] Manual smoke test matrix: 14 / 15 / 16 / 26.4 — capture, save, history, dashboard, hotkey, sleep/wake hotkey

### Phase 4 — CI & docs

- [ ] CI: two jobs (or matrix) — full requires macOS 26.4 SDK; Lite builds on older SDK runner if available
- [ ] Update `README.md`, `issues.md` (resolve or amend P0-04 for Lite)
- [ ] Landing page: two download rows when releases exist
- [ ] Privacy manifest: Lite may omit FM-related declarations if any are added later

### Phase 5 — Release (future)

- [ ] Notarized builds for both products
- [ ] GitHub Releases: `crane-{version}-macos26.dmg` + `crane-lite-{version}-macos14.dmg` (or zip)
- [ ] App Store: optional; two listings if submitted

---

## What stays the same (both binaries)

- Carbon global hotkey (`GlobalHotkey.swift`)
- Borderless overlay panel (`OverlayPanel`, `OverlayController`)
- SwiftData persistence (`Persistence`, `CraneSchema`, migration plan)
- Single-instance guard (`SingleInstance`)
- Design tokens (`Design`, `CraneColors`, `CraneTypography`)
- Menu-bar dashboard layout (minus Top Tags in Lite)

---

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| SwiftUI / `MenuBarExtra` behavior differs 14 vs 26 | Test matrix; keep Lite UI conservative (existing `.regularMaterial`, no Liquid Glass) |
| Accidentally linking FM in Lite | CI check: `otool -L` Lite binary must not require FoundationModels |
| Shared store corruption if both apps run | Separate bundle IDs + store paths for v1 |
| Maintainer burden (two targets) | Shared sources; `#if CRANE_AI` only at boundaries; avoid duplicated view files |

---

## References

- Current deployment target: `crane.xcodeproj` → `MACOSX_DEPLOYMENT_TARGET = 26.4`
- AI module: `crane/AI/`
- Issue tracker: `issues.md` P0-04 (26.4-only — update when Lite ships)
- Architecture: `docs/ARCHITECTURE.md`
- Refactor plan (orthogonal): `docs/REFACTOR_PLAN.md`

---

## Changelog (this document)

| Date | Change |
|------|--------|
| 2026-05-20 | Initial plan from product discussion (two binaries, size measurements, phased rollout) |
