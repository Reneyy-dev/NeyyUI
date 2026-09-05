local NeyyUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Reneyy-dev/NeyyUI/refs/heads/main/NeyyUI.lua"
))()

local Window = NeyyUI:CreateWindow({
    Title = "NEYY HUB // TEST",
    Subtitle = "REUSABLE UI LIBRARY",
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

Demo:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Callback = function(value)
        Status:Set("Speed: " .. tostring(value))
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
    Content = "If every component above shows up and works, NeyyUI is ready to be wired into any game's logic.",
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
