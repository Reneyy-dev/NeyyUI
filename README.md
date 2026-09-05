# NeyyUI — ValueFormat Compatibility Build

This README is aligned with `NeyyUI.lua`, the compatibility build of NeyyUI. It keeps the same single-file, dependency-free UI design while documenting the slider `ValueFormat` syntax explicitly so scripts and AI-generated integrations use the API correctly.

NeyyUI uses a dark glass aesthetic, mobile-responsive scaling, drag/minimize support, and a full set of interactive controls — inspired by [Rayfield](https://sirius.menu/rayfield) and [WindUI](https://wind-ui.com/), built to be usable in **any** game, not just one.

```lua
local NeyyUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Reneyy-dev/NeyyUI/refs/heads/main/NeyyUI_ValueFormatCompat.lua"
))()
```

> This compatibility README targets the `Reneyy-dev/NeyyUI` repository and `NeyyUI_ValueFormatCompat.lua` file.

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

1. Use `NeyyUI_ValueFormatCompat.lua` as the library file (raw-servable from GitHub).
2. Load `https://raw.githubusercontent.com/Reneyy-dev/NeyyUI/refs/heads/main/NeyyUI_ValueFormatCompat.lua` with `loadstring(game:HttpGet(...))()`.
3. That's it — no build step, no config files needed to get started.

---

## Quick Start

```lua
local NeyyUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Reneyy-dev/NeyyUI/refs/heads/main/NeyyUI_ValueFormatCompat.lua"
))()

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

See [`Example_ValueFormatCompat.lua`](./Example_ValueFormatCompat.lua) for a full working demo. It includes both supported `ValueFormat` styles.

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
| `CreateSlider` | `Name, Min, Max, Default, Increment, ValueFormat, Callback(value)` | Drag or tap along the bar. `ValueFormat` rules are documented below. |
| `CreateColorPicker` | `Name, Default (Color3), Callback(color)` | Tap header to expand the hue/SV picker |
| `CreateKeybind` | `Name, Default (Enum.KeyCode), OnPress, Callback(key)` | Tap the box, then press any key to rebind (`Esc` cancels) |
| `CreateStat` | `Name, Value, Color` | Read-only label pair, use `control:Set(value)` to update |
| `CreateParagraph` | `Content` | Wrapped static text block |
| `CreateDivider` | `Height, Color, Transparency` | Thin separator line |


### `CreateSlider` and `ValueFormat`

`ValueFormat` is optional. The compatibility build officially supports **two string styles**:

```lua
-- Style 1: NeyyUI placeholder
Section:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 50,
    Increment = 1,
    ValueFormat = "{value} studs/s",
    Callback = function(value)
        print(value)
    end,
})

-- Style 2: normal Lua string.format syntax
Section:CreateSlider({
    Name = "Multiplier",
    Min = 0.5,
    Max = 10,
    Default = 1,
    Increment = 0.5,
    ValueFormat = "%.1fx",
    Callback = function(value)
        print(value)
    end,
})
```

Supported examples:

| `ValueFormat` | Example value | Display |
|---|---:|---|
| `"{value} studs/s"` | `50` | `50 studs/s` |
| `"Speed: {value}"` | `50` | `Speed: 50` |
| `"%d studs/s"` | `50` | `50 studs/s` |
| `"%g studs/s"` | `50` | `50 studs/s` |
| `"%s studs/s"` | `50` | `50 studs/s` |
| `"%.1fx"` | `5.5` | `5.5x` |
| omitted / `nil` | `50` | `50` |

Important behavior:

- If the string contains the exact literal `{value}`, NeyyUI replaces that token with `tostring(value)`.
- Otherwise NeyyUI tries `string.format(ValueFormat, value)`.
- A malformed printf-style format is protected with `pcall`; the display safely falls back to `tostring(value)` instead of crashing the slider.
- `ValueFormat` is a **string option** in this build. Function-based formatters are not part of the API.

Do **not** use or generate these unsupported placeholder variants:

```lua
ValueFormat = "${value} studs/s"
ValueFormat = "{{value}} studs/s"
ValueFormat = "[value] studs/s"
ValueFormat = "{value:.1f}x"
```

Use one of the two official forms instead:

```lua
ValueFormat = "{value} studs/s"
-- or
ValueFormat = "%d studs/s"
```

---

## File Structure

```
NeyyUI/
├── NeyyUI_ValueFormatCompat.lua      # Compatibility library build
├── Example_ValueFormatCompat.lua     # Full usage demo + ValueFormat examples
├── README_ValueFormatCompat.md       # Documentation for the compatibility build
└── LICENSE                           # MIT License + attribution notice
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

### Strict slider schema

When generating a NeyyUI slider, use these exact option names:

```lua
Section:CreateSlider({
    Name = "Example",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 1,
    ValueFormat = "{value}%",
    Callback = function(value)
        -- game logic here
    end,
})
```

For `ValueFormat`, use only:

```lua
ValueFormat = "{value}%"
ValueFormat = "%d%%"
ValueFormat = "%.1fx"
```

Do not silently substitute APIs from other UI libraries such as `Range`, `CurrentValue`, `Suffix`, `Minimum`, `Maximum`, `Format`, or Python-style placeholders unless the NeyyUI source explicitly adds support for them.

- The whole library is one Lua chunk returning a single `NeyyUI` table — there are no external `require`s.
- Internal helpers (`Tween`, `Track`, `SafeCallback`, `NewCorner`, `NewStroke`, `SpawnClickBurst`, etc.) are local to the file and reused across every control — follow the same pattern (`options` table in → `control` table with `:Set/:Get` out) when adding new components.
- `Runtime.Alive` must be checked before touching any GUI instance in async code (tweens, `task.spawn`, input callbacks) since the window can be destroyed/re-executed at any time.
- Config/flag saving (persisting control values to a file) is a planned addition, not yet implemented.

---

## License & Attribution

NeyyUI is released under the [MIT License](./LICENSE) with an additional (non-binding) attribution request: please keep the in-UI credit label and the copyright notice intact if you fork or redistribute this library. See the `LICENSE` file for details.

Every window built with NeyyUI shows a small, low-opacity credit line at the bottom of the window ("NeyyUI  •  github.com/Reneyy-dev/NeyyUI"). This is baked into the library's source (`BuildCredit`), not a togglable option — it exists so forks and reposts stay traceable back to the original project.

---

## Credits

Inspired by [Rayfield Interface Suite](https://sirius.menu/rayfield) and [WindUI](https://wind-ui.com/). Built and maintained independently.
