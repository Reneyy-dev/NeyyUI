local NeyyUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Reneyy-dev/NeyyUI/refs/heads/main/NeyyUI_ValueFormatCompat.lua"
))()

local Window = NeyyUI:CreateWindow({
    Title = "NEYY HUB // COMPAT TEST",
    Subtitle = "VALUEFORMAT COMPATIBLE BUILD",
    Icon = "Bolt",
    Scale = 0.80,
    Blur = true,
    ParticleCount = 18,
    LiquidCount = 5,
})

local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "Bolt",
})

local Demo = MainTab:CreateSection("COMPONENT TEST")

local Status = Demo:CreateStat({
    Name = "Status",
    Value = "Ready",
    Color = Window.Theme.Emerald,
})

Demo:CreateButton({
    Name = "Test Button",
    Icon = "Check",
    Color = Window.Theme.Cyan,
    Callback = function()
        Status:Set("Clicked")
        Window:Notify({
            Content = "Button callback fired",
            Type = "Success",
        })
    end,
})

Demo:CreateToggle({
    Name = "Test Toggle",
    Default = false,
    Callback = function(value)
        Status:Set(value and "Toggle ON" or "Toggle OFF")
    end,
})

Demo:CreateInput({
    Name = "Text Input",
    Placeholder = "Type something...",
    Default = "",
    Callback = function(text, enterPressed)
        if enterPressed then
            Status:Set(text)
        end
    end,
})

Demo:CreateDropdown({
    Name = "Mode",
    Options = {"Casual", "Fast", "Ultra"},
    Default = "Casual",
    Callback = function(value)
        Status:Set("Mode: " .. tostring(value))
    end,
})

-- ValueFormat supports TWO official styles in the compatibility build:
--   1) Placeholder style: "{value} ..."
--   2) Lua string.format style: "%d ...", "%g ...", "%.1f ...", "%s ..."
--
-- Do NOT invent placeholder variants such as ${value}, {{value}},
-- [value], or {value:.1f}; they are not part of NeyyUI's API.

Demo:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    ValueFormat = "{value} studs/s",
    Callback = function(value)
        Status:Set("Speed: " .. tostring(value))
    end,
})

Demo:CreateSlider({
    Name = "Power Multiplier",
    Min = 0.5,
    Max = 10,
    Default = 1,
    Increment = 0.5,
    ValueFormat = "%.1fx",
    Callback = function(value)
        Status:Set(string.format("Multiplier: %.1fx", value))
    end,
})

Demo:CreateColorPicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(45, 226, 255),
    Callback = function(color)
        Status:Set("Color updated")
    end,
})

Demo:CreateKeybind({
    Name = "Toggle UI",
    Default = Enum.KeyCode.RightControl,
    OnPress = function()
        Window:Notify({Content = "Keybind pressed", Type = "Success"})
    end,
    Callback = function(key)
        Status:Set("Bound to " .. tostring(key))
    end,
})

Demo:CreateDivider()

Demo:CreateParagraph({
    Content = "ValueFormat: use either {value} placeholders or normal Lua string.format patterns such as %d, %g, %s, and %.1f. Keep game logic outside the UI library.",
})

local SettingsTab = Window:CreateTab({
    Name = "Settings",
    Icon = "Settings",
})

local WindowSection = SettingsTab:CreateSection("WINDOW")

WindowSection:CreateButton({
    Name = "Minimize Window",
    Icon = "Minimize",
    Callback = function()
        Window:Minimize()
    end,
})

WindowSection:CreateButton({
    Name = "Success Toast",
    Icon = "Check",
    Callback = function()
        Window:Notify({Content = "NeyyUI is running fine", Type = "Success"})
    end,
})

WindowSection:CreateButton({
    Name = "Warning Toast",
    Icon = "Bolt",
    Color = Window.Theme.Amber,
    Callback = function()
        Window:Notify({Content = "This is a warning test", Type = "Warning"})
    end,
})
