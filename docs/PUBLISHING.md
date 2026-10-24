# Publishing checklist

This file is for you (the maintainer). It's excluded from the packaged addon by `.pkgmeta`.

## 0. Before anything else: test in game

The addon has been syntax-checked and smoke-tested against a mocked WoW API, but it has **not** been run in a real client yet. Before the first release, run through this on every version you can:

- [ ] Addon loads without a Lua error (enable *Display Lua Errors*: `/console scriptErrors 1`)
- [ ] `/thespian` opens the window; Esc closes it; dragging works; position survives `/reload`
- [ ] Click a *Standard emote* button (Wave) and an *Emote (/me)* button; check chat output
- [ ] Target someone, click a button with `%t`; then with no target
- [ ] Create a custom emote of each type; edit it (right-click); delete it (confirmation appears)
- [ ] Options panel opens from: Options button, minimap right-click, `/thespian options`, game settings
- [ ] Every option does what it says (scale, opacity, lock, close-after-use, tooltips, minimap toggle)
- [ ] Minimap button: click, right-click, drag; the icon displays correctly
- [ ] Addon list shows the icon and the title "Thespian" (Retail)

## 1. Replace the placeholders

Search the repo for these and replace them:

| Placeholder | Where | Replace with |
|---|---|---|
| `YOUR NAME` | `LICENSE` | Your name or nickname |
| `YOUR_GITHUB_USER` | `docs/curseforge-description.*` | Your GitHub username |
| `https://www.curseforge.com/wow/addons/thespian` | `README.md` | The real URL once the CurseForge project exists |

```bash
grep -rn "YOUR_GITHUB_USER\|YOUR NAME" .
```

## 2. Take screenshots

Save these in `docs/screenshots/` and uncomment the *Screenshots* block in `README.md`:

1. `soundboard.png`: main window on the Greetings tab
2. `builder.png`: the **New Emote** window with the preview filled in
3. `options.png`: the options panel
4. `minimap.png`: the minimap button

Upload the same shots in the CurseForge *Images* tab.

## 3. GitHub

1. Create a new repository named `Thespian` and push this folder to it.
2. *Settings → General → Social preview:* upload `docs/social-preview.png` (1280×640).
3. Add topics: `warcraft`, `wow-addon`, `roleplay`, `lua`, `world-of-warcraft`.

## 4. CurseForge project

Create the project at <https://authors.curseforge.com/> with:

| Field | Value |
|---|---|
| Game | World of Warcraft, *Addons* |
| Name | Thespian |
| Category | Roleplay |
| License | MIT |
| Logo | `docs/logo.png` (512×512) |
| Summary (max 250 chars) | See below |
| Description | Paste `docs/curseforge-description.html` (use the editor's source/HTML mode) or the `.md` version |
| Source URL / Issues URL | Your GitHub repo and its `/issues` page |

**Summary:**

> The emote soundboard for your roleplay. One-click /me emotes, say lines and standard emotes, 70+ presets, a custom emote builder with %t target support, a minimap button and options. Retail and Classic.

After the project is created, copy its numeric **Project ID** and add this line to `Thespian.toc`:

```
## X-Curse-Project-ID: 123456
```

## 5. Automatic releases (GitHub Actions)

The workflow in `.github/workflows/release.yml` uses the [BigWigs packager](https://github.com/BigWigsMods/packager). On every tag starting with `v` it builds the zip, attaches it to a GitHub Release and uploads it to CurseForge.

1. On CurseForge, create an API token (*Account → API Tokens*).
2. In GitHub, go to *Settings → Secrets and variables → Actions* and add the secret **`CF_API_KEY`**.
3. Optional, for Wago.io: add **`WAGO_API_TOKEN`** and put `## X-Wago-ID: <id>` in the `.toc`.

## 6. Cutting a release

1. Update `CHANGELOG.md` (add a new `## [x.y.z] - date` section on top).
2. If a new WoW patch shipped, update the `## Interface:` line in `Thespian.toc`.
3. Commit, then tag and push:

```bash
git tag v1.0.0
git push origin main --tags
```

The packager replaces `@project-version@` in the `.toc` with the tag name, publishes the release notes from `CHANGELOG.md`, and reads the supported game versions from the `## Interface:` line.

> Running from a plain git checkout? The AddOns list will show the literal text `@project-version@` as the version. That's expected; packaged releases show the real number.

## Updating the Interface numbers

Each patch, check the numbers in game with `/dump select(4, GetBuildInfo())` (or on the Warcraft Wiki's *TOC format* page) and add new ones to the front of the `## Interface:` list. Old numbers can stay.
