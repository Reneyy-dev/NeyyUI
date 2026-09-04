local NeyyUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local THEME = {
    Width = 580,
    Height = 510,
    TopBarHeight = 52,

    Background = Color3.fromRGB(8, 10, 16),
    Surface = Color3.fromRGB(13, 16, 26),

    Text = Color3.fromRGB(240, 246, 255),
    Muted = Color3.fromRGB(140, 153, 178),
    Cyan = Color3.fromRGB(45, 226, 255),
}

local function GetGuiParent()
    local ok, result = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end

        return game:GetService("CoreGui")
    end)

    if ok and result then
        return result
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end


function NeyyUI:CreateWindow(config)
    config = config or {}

    local parent = GetGuiParent()

    -- Destroy NeyyUI lama kalau diexecute ulang.
    local oldGui = parent:FindFirstChild("NeyyUI")
    if oldGui then
        oldGui:Destroy()
    end


    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NeyyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = parent


    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.fromOffset(
        THEME.Width,
        THEME.Height
    )
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)

    Main.BackgroundColor3 = THEME.Background
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui


    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 14)
    MainCorner.Parent = Main


    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = THEME.Cyan
    MainStroke.Transparency = 0.6
    MainStroke.Thickness = 1
    MainStroke.Parent = Main


    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(
        1,
        0,
        0,
        THEME.TopBarHeight
    )

    TopBar.BackgroundColor3 = THEME.Surface
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Main


    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 14)
    TopCorner.Parent = TopBar


    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1

    Title.Position = UDim2.fromOffset(
        16,
        8
    )

    Title.Size = UDim2.new(
        1,
        -32,
        0,
        20
    )

    Title.Text =
        config.Title
        or "NEYY HUB"

    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 14
    Title.TextColor3 = THEME.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar


    local Subtitle = Instance.new("TextLabel")
    Subtitle.BackgroundTransparency = 1

    Subtitle.Position = UDim2.fromOffset(
        16,
        28
    )

    Subtitle.Size = UDim2.new(
        1,
        -32,
        0,
        14
    )

    Subtitle.Text =
        config.Subtitle
        or "NEYY UI FRAMEWORK"

    Subtitle.Font = Enum.Font.GothamMedium
    Subtitle.TextSize = 9
    Subtitle.TextColor3 = THEME.Cyan
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = TopBar


    local Window = {}

    Window.Gui = ScreenGui
    Window.Main = Main
    Window.TopBar = TopBar

    function Window:Destroy()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end

    return Window
end


return NeyyUI
