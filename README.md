# NeyyUI

A single-file, dependency-free UI library for Roblox exploit scripts. Dark glass aesthetic, mobile-responsive scaling, drag/minimize support, and a full set of interactive controls — inspired by [Rayfield](https://sirius.menu/rayfield) and [WindUI](https://wind-ui.com/), built to be usable in **any** game, not just one.

```lua
local NeyyUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/<your-username>/NeyyUI/main/NeyyUI.lua"
))()
```

> Replace `<your-username>` with your actual GitHub username/org before publishing.

---

## Features

- **Universal by design** — no game-specific logic anywhere in the library. Everything (title, icons, tabs, controls) is configured by the script that loads it.
- **Full component set**: Window, Tab, Section, Button, Toggle, Input, Dropdown, Slider, ColorPicker, Keybind, Stat, Paragraph, Divider.
- **Visual polish**: animated glitch title, glass blur background, floating liquid blobs, ambient particles, click-punch animation + in-button particle burst on `Button` clicks.
- **Mobile-first**: auto-scales to viewport size, touch-friendly drag and hit areas on every interactive element.
- **Minimize pill**: collapses the whole window into a small draggable pill instead of hiding it entirely.
- **Runtime-safe**: re-executing the script cleans up the previous instance automatically (no duplicate GUIs, no dangling connections).
- **Neutral icon set**: ships with generic icons only (`Bolt`, `Check`, `Cross`, `Minimize`, `Expand`, `Refresh`, `Trash`, `Search`, `Shield`, `Cart`, `Power`, `Data`, `Package`, `Settings`, `Misc`). Add your own via `NeyyUI.Icons.MyIcon = "rbxassetid://..."` or just pass a raw `"rbxassetid://..."` string directly to any `Icon` field.

---

## Requirements

- A Roblox executor that supports `loadstring`, `game:HttpGet`, and standard `Instance.new` GUI creation (any modern executor — Synapse-tier, Fluxus, Wave, Delta, etc.).
- No external dependencies. No key system, no third-party libraries. Everything lives in one `.lua` file.
- Optional: `getgenv()` / `gethui()` support (used automatically if available, falls back gracefully otherwise).

---

## Installation

1. Fork or copy `NeyyUI.lua` into your own GitHub repo (raw-servable, e.g. `raw.githubusercontent.com/...`).
2. In your script, load it with `loadstring(game:HttpGet("<raw-url>"))()`.
3. That's it — no build step, no config files needed to get started.

---

## Quick Start

```lua
local NeyyUI = loadstring(game:HttpGet("<raw-url-to-NeyyUI.lua>"))()

local Window = NeyyUI:CreateWindow({
    Title = "My Hub",
    Subtitle = "v1.0",
    Icon = "Bolt",       -- any key from NeyyUI.Icons, or a raw rbxassetid string
})

local Tab = Window:CreateTab({ Name = "Main", Icon = "Bolt" })
local Section = Tab:CreateSection("General")

Section:CreateButton({
    Name = "Say Hello",
    Callback = function()
        Window:Notify({ Content = "Hello!", Type = "Success" })
    end,
})
```

See [`NeyyUI_Example.lua`](./NeyyUI_Example.lua) in this repo for a full working demo covering every component.

---

## API Reference

### `NeyyUI:CreateWindow(config)`

| Field | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"NEYY HUB"` | Window title text |
| `Subtitle` | string | `"ACTIVE CLIENT // NEYY UI"` | Small text under the title |
| `Icon` | string | `"Bolt"` | Icon key or raw asset id, shown in the top bar and pill |
| `Width` / `Height` | number | `580` / `510` | Window size in pixels |
| `Scale` | number | `0.80` | Base UI scale (auto-clamped to fit small screens) |
| `Blur` | boolean | `true` | Enable/disable background blur |
| `BlurStrength` | number | `20` | Blur intensity |
| `ParticleCount` | number | `22` | Ambient background particles (0–30) |
| `LiquidCount` | number | `4` | Ambient liquid blobs (0–6) |
| `Theme` | table | — | Override any `NeyyUI.Theme` color/spacing key |
| `RuntimeKey` | string | internal default | Use a custom key to run multiple independent windows at once |
| `NotifyOnLoad` | boolean | `true` | Show a "loaded" toast automatically |
| `LoadMessage` | string | `"NeyyUI loaded"` | Text for the load toast |
| `OnClose` | function | — | Called right before the window is destroyed via the close button |

Returns a `Window` object with:

- `Window:CreateTab(config)` → returns a `Tab`
- `Window:Notify(options)` — `{ Content, Type = "Success"|"Error"|"Warning", Duration, Icon, Color }`
- `Window:SetTitle(text)`, `Window:SetSubtitle(text)`
- `Window:Minimize()`, `Window:Restore()`, `Window:IsMinimized()`
- `Window:Destroy()`

### `Window:CreateTab({ Name, Icon, Accent })`

Returns a `Tab` with `Tab:CreateSection(title)`.

### `Tab:CreateSection(title)`

Returns a `Section`. Every control below is a method on `Section`, all following the same shape: pass an options table, get back a `control` object with `:Set(value)` / `:Get()` (and any control-specific extras).

| Method | Key options | Notes |
|---|---|---|
| `CreateButton` | `Name, Icon, Color, Callback(control)` | Click-punch animation + in-button particle burst on click |
| `CreateToggle` | `Name, Default, Color, Callback(value)` | |
| `CreateInput` | `Name, Placeholder, Default, ClearTextOnFocus, Callback(text, enterPressed)` | |
| `CreateDropdown` | `Name, Options, Default, Callback(value)` | `control:Refresh(items, keepValue)` to repopulate |
| `CreateSlider` | `Name, Min, Max, Default, Increment, ValueFormat, Callback(value)` | Drag or tap along the bar |
| `CreateColorPicker` | `Name, Default (Color3), Callback(color)` | Tap header to expand the hue/SV picker |
| `CreateKeybind` | `Name, Default (Enum.KeyCode), OnPress, Callback(key)` | Tap the box, then press any key to rebind (`Esc` cancels) |
| `CreateStat` | `Name, Value, Color` | Read-only label pair, use `control:Set(value)` to update |
| `CreateParagraph` | `Content` | Wrapped static text block |
| `CreateDivider` | `Height, Color, Transparency` | Thin separator line |

---

## File Structure

```
NeyyUI/
├── NeyyUI.lua          # The library itself — everything lives in this one file
├── NeyyUI_Example.lua  # Full usage demo covering every component
└── README.md           # This file
```

There's intentionally no build step or multi-file split — the whole point is that anyone can `loadstring` one raw URL and get the whole library.

---

## Extending Icons

The default icon set is neutral on purpose (no game-specific assets). To add your own:

```lua
-- Option A: register a reusable name
NeyyUI.Icons.Coin = "rbxassetid://1234567890"
Section:CreateButton({ Name = "Buy", Icon = "Coin" })

-- Option B: just pass the asset id directly, no registration needed
Section:CreateButton({ Name = "Buy", Icon = "rbxassetid://1234567890" })
```

---

## Notes for Contributors / AI Agents

- The whole library is one Lua chunk returning a single `NeyyUI` table — there are no external `require`s.
- Internal helpers (`Tween`, `Track`, `SafeCallback`, `NewCorner`, `NewStroke`, `SpawnClickBurst`, etc.) are local to the file and reused across every control — follow the same pattern (`options` table in → `control` table with `:Set/:Get` out) when adding new components.
- `Runtime.Alive` must be checked before touching any GUI instance in async code (tweens, `task.spawn`, input callbacks) since the window can be destroyed/re-executed at any time.
- Config/flag saving (persisting control values to a file) is a planned addition, not yet implemented.

---

## Credits

Inspired by [Rayfield Interface Suite](https://sirius.menu/rayfield) and [WindUI](https://wind-ui.com/). Built and maintained independently.
