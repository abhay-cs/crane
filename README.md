<p align="center">
  <img src="assets/logo.png" width="96" alt="crane logo">
</p>

<h1 align="center">crane</h1>

<p align="center"><strong>Press a key. Type a thought. Go back to work.</strong></p>

<p align="center">
  A tiny Mac menu-bar app that catches ideas before they disappear.<br>
  No Dock icon. No big window. Just a quick floating bar.
</p>

---

## What is this?

Your brain throws ideas while you work:

> *Email Maya about Friday.*  
> *Save that link Jay sent.*

**crane** lets you save them in ~2 seconds without leaving your app.

1. Press **⌘⇧Space**
2. Type
3. Press **Enter**

Done. The bar closes. Your thought is saved.

Open the **menu-bar icon** later to see recent entries, tags, and stats.

---

## Shortcuts

| Press | What happens |
|-------|----------------|
| **⌘⇧Space** | Open / close the capture bar |
| **Enter** | Save and close |
| **⌘L** | Switch thought ↔ link |
| **⌘⇧H** | Open history |
| **⌘F** | Search (in history) |
| **Esc** | Close bar, or go back |
| **⌘Q** | Quit |

Menu bar → **Capture** has the same actions, plus **Reset All Data…**

---

## Run it

**Needs:** macOS 26.4+ and Xcode 26+

```bash
git clone https://github.com/abhay-cs/crane.git
cd crane
open crane.xcodeproj
```

Press **⌘R** in Xcode.

---

## Where is my data?

Saved on your Mac only:

```
~/Library/Application Support/com.abhaycs.crane/crane.store
```

**Reset everything:** menu-bar window → **Reset**, or **Capture → Reset All Data…**

---

## Design

crane should feel calm, fast, and native — like Spotlight or Raycast, not a busy notes app.

Simple rules: [docs/ui-design-brain.md](docs/ui-design-brain.md)

Code tokens live in `crane/Design.swift`, `CraneColors.swift`, and `CraneTypography.swift`.

---

## More docs

| Doc | For |
|-----|-----|
| [docs/ui-design-brain.md](docs/ui-design-brain.md) | How the UI should look and behave |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the app is built |
| [docs/ONBOARDING.md](docs/ONBOARDING.md) | New developer walkthrough |
| [issues.md](issues.md) | Known bugs and todo list |
