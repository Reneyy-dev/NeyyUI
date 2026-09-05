--// ==============================================================================
--// NEYY UI // V2 REUSABLE LIBRARY
--// Dark glass UI | Responsive mobile scale | Tabs | Sections | Controls
--// Button | Toggle | Input | Dropdown | Slider | ColorPicker | Keybind | Stat | Paragraph | Divider
--// Minimize pill | Blur | Glitch | Liquid | Particles | Runtime protection
--// ============================================================================== 

local NeyyUI = {}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local ENV = (getgenv and getgenv()) or _G
local DEFAULT_RUNTIME_KEY = "__NEYY_UI_RUNTIME_V2"

local DEFAULT_THEME = {
    WindowWidth = 580,
    WindowHeight = 510,
    TopBarHeight = 52,
    SidebarWidth = 135,
    CornerRadius = 14,
    SmallRadius = 9,

    Bg = Color3.fromRGB(8, 10, 16),
    Surface = Color3.fromRGB(13, 16, 26),
    SurfaceHover = Color3.fromRGB(20, 24, 38),
    SurfaceActive = Color3.fromRGB(28, 34, 52),

    Text = Color3.fromRGB(240, 246, 255),
    Muted = Color3.fromRGB(140, 153, 178),

    Cyan = Color3.fromRGB(45, 226, 255),
    Purple = Color3.fromRGB(168, 92, 255),
    Emerald = Color3.fromRGB(52, 230, 150),
    Rose = Color3.fromRGB(255, 82, 110),
    Amber = Color3.fromRGB(255, 195, 75),

    BlurStrength = 20,
    TweenFast = 0.15,
    TweenNormal = 0.26,
    TweenSpring = 0.42,

    BaseScale = 0.80,
    MinScale = 0.58,

    ParticleCount = 22,
    LiquidCount = 4,
}

local ICONS = {
    Misc     = "rbxassetid://10734950309",

    Check    = "rbxassetid://10709790644",
    Cross    = "rbxassetid://10747384394",
    Minimize = "rbxassetid://10734895698",
    Expand   = "rbxassetid://10734886496",
    Refresh  = "rbxassetid://10734933222",
    Trash    = "rbxassetid://10747362241",
    Search   = "rbxassetid://10734943674",
    Bolt     = "rbxassetid://10723345749",
    Shield   = "rbxassetid://10734951367",
    Cart     = "rbxassetid://10734952479",
    Power    = "rbxassetid://10734930466",
    Data     = "rbxassetid://10709818996",
    Package  = "rbxassetid://10734908793",
    Settings = "rbxassetid://10734950309",
}

NeyyUI.Icons = ICONS
NeyyUI.Theme = DEFAULT_THEME
NeyyUI.Version = "2.1.0-universal"
NeyyUI._LastWindow = nil

local function ShallowCopy(source)
    local result = {}
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function ResolveIcon(icon)
    if icon == nil then
        return ICONS.Misc
    end
    if type(icon) == "string" and ICONS[icon] then
        return ICONS[icon]
    end
    return tostring(icon)
end

local function GetGuiParent()
    local ok, parent = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
        return CoreGui
    end)

    if ok and parent then
        local writable = pcall(function()
            local probe = Instance.new("Folder")
            probe.Name = "__neyy_ui_probe"
            probe.Parent = parent
            probe:Destroy()
        end)
        if writable then
            return parent
        end
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function SafeDisconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function Track(Runtime, connection)
    if connection then
        table.insert(Runtime.Connections, connection)
    end
    return connection
end

local function SafeCallback(Runtime, label, callback, ...)
    if not Runtime.Alive or type(callback) ~= "function" then
        return true
    end

    local args = table.pack(...)
    task.spawn(function()
        if not Runtime.Alive then
            return
        end
        local ok, err = pcall(function()
            callback(table.unpack(args, 1, args.n))
        end)
        if not ok then
            warn(string.format("[NeyyUI] %s callback error: %s", tostring(label), tostring(err)))
        end
    end)
    return true
end

local function Tween(Runtime, object, duration, props, style, direction)
    if not Runtime.Alive or not object or not object.Parent then
        return nil
    end

    local ok, tween = pcall(function()
        return TweenService:Create(
            object,
            TweenInfo.new(
                duration or DEFAULT_THEME.TweenNormal,
                style or Enum.EasingStyle.Quart,
                direction or Enum.EasingDirection.Out
            ),
            props
        )
    end)

    if ok and tween then
        tween:Play()
        return tween
    end
    return nil
end

local function NewCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function NewStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function BuildRuntime(runtimeKey)
    local previous = rawget(ENV, runtimeKey)
    if type(previous) == "table" and type(previous.Cleanup) == "function" then
        pcall(previous.Cleanup, "reexecute")
    end

    local Runtime = {
        Alive = true,
        Connections = {},
        Gui = nil,
        Blur = nil,
        Key = runtimeKey,
        DestroyReason = nil,
    }

    function Runtime.Cleanup(reason)
        if not Runtime.Alive then
            return
        end

        Runtime.Alive = false
        Runtime.DestroyReason = reason or "cleanup"

        for index = #Runtime.Connections, 1, -1 do
            SafeDisconnect(Runtime.Connections[index])
            Runtime.Connections[index] = nil
        end

        local blur = Runtime.Blur
        Runtime.Blur = nil
        if blur and blur.Parent then
            pcall(function()
                blur:Destroy()
            end)
        end

        local gui = Runtime.Gui
        Runtime.Gui = nil
        if gui and gui.Parent then
            pcall(function()
                gui:Destroy()
            end)
        end


        if rawget(ENV, runtimeKey) == Runtime then
            ENV[runtimeKey] = nil
        end
    end

    ENV[runtimeKey] = Runtime
    return Runtime
end

local function BuildScreen(Runtime, config, theme)
    local ui = {}
    local parent = GetGuiParent()

    ui.ScreenGui = Instance.new("ScreenGui")
    ui.ScreenGui.Name = config.GuiName or "NeyyUI"
    ui.ScreenGui.ResetOnSpawn = false
    ui.ScreenGui.IgnoreGuiInset = true
    ui.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.ScreenGui.DisplayOrder = config.DisplayOrder or 999999
    ui.ScreenGui.Parent = parent
    Runtime.Gui = ui.ScreenGui

    ui.ClickSound = Instance.new("Sound")
    ui.ClickSound.Name = "ClickSound"
    ui.ClickSound.SoundId = config.ClickSoundId or "rbxasset://sounds/button.wav"
    ui.ClickSound.Volume = config.ClickSoundVolume or 0.24
    ui.ClickSound.Parent = ui.ScreenGui

    ui.Main = Instance.new("Frame")
    ui.Main.Name = "Main"
    ui.Main.Size = UDim2.fromOffset(theme.WindowWidth, theme.WindowHeight)
    ui.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    ui.Main.Position = config.Position or UDim2.fromScale(0.5, 0.5)
    ui.Main.BackgroundColor3 = theme.Bg
    ui.Main.BackgroundTransparency = 0.08
    ui.Main.BorderSizePixel = 0
    ui.Main.Active = false
    ui.Main.ClipsDescendants = false
    ui.Main.Parent = ui.ScreenGui
    NewCorner(ui.Main, theme.CornerRadius)

    ui.MainStroke = NewStroke(ui.Main, theme.Cyan, 0.65, 1.2)

    ui.MainGradient = Instance.new("UIGradient")
    ui.MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 13, 22)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(17, 12, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 24, 28)),
    })
    ui.MainGradient.Rotation = 20
    ui.MainGradient.Parent = ui.Main

    ui.ResponsiveScale = Instance.new("UIScale")
    ui.ResponsiveScale.Name = "ResponsiveScale"
    ui.ResponsiveScale.Scale = theme.BaseScale
    ui.ResponsiveScale.Parent = ui.Main

    ui.Shadow = Instance.new("ImageLabel")
    ui.Shadow.Name = "DropShadow"
    ui.Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    ui.Shadow.Position = UDim2.fromScale(0.5, 0.5)
    ui.Shadow.Size = UDim2.new(1, 48, 1, 48)
    ui.Shadow.BackgroundTransparency = 1
    ui.Shadow.Image = "rbxassetid://6015897843"
    ui.Shadow.ImageColor3 = Color3.new(0, 0, 0)
    ui.Shadow.ImageTransparency = 0.4
    ui.Shadow.ScaleType = Enum.ScaleType.Slice
    ui.Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    ui.Shadow.ZIndex = 0
    ui.Shadow.Parent = ui.Main

    return ui
end

local function BuildTopBar(Runtime, ui, config, theme)
    ui.TopBar = Instance.new("Frame")
    ui.TopBar.Name = "TopBar"
    ui.TopBar.Size = UDim2.new(1, 0, 0, theme.TopBarHeight)
    ui.TopBar.BackgroundColor3 = theme.Surface
    ui.TopBar.BackgroundTransparency = 0.16
    ui.TopBar.BorderSizePixel = 0
    ui.TopBar.Active = true
    ui.TopBar.ZIndex = 30
    ui.TopBar.Parent = ui.Main
    NewCorner(ui.TopBar, theme.CornerRadius)

    ui.TopGradient = Instance.new("UIGradient")
    ui.TopGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 19, 30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(24, 17, 39)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 31, 37)),
    })
    ui.TopGradient.Rotation = 8
    ui.TopGradient.Parent = ui.TopBar

    ui.TopDivider = Instance.new("Frame")
    ui.TopDivider.Size = UDim2.new(1, 0, 0, 1)
    ui.TopDivider.Position = UDim2.new(0, 0, 1, -1)
    ui.TopDivider.BackgroundColor3 = theme.SurfaceActive
    ui.TopDivider.BorderSizePixel = 0
    ui.TopDivider.ZIndex = 31
    ui.TopDivider.Parent = ui.TopBar

    ui.LogoIcon = Instance.new("ImageLabel")
    ui.LogoIcon.Size = UDim2.fromOffset(20, 20)
    ui.LogoIcon.Position = UDim2.fromOffset(16, (theme.TopBarHeight - 20) / 2)
    ui.LogoIcon.BackgroundTransparency = 1
    ui.LogoIcon.Image = ResolveIcon(config.Icon or "Bolt")
    ui.LogoIcon.ImageColor3 = theme.Cyan
    ui.LogoIcon.ScaleType = Enum.ScaleType.Fit
    ui.LogoIcon.ZIndex = 33
    ui.LogoIcon.Parent = ui.TopBar

    ui.TitleLabel = Instance.new("TextLabel")
    ui.TitleLabel.Name = "Title"
    ui.TitleLabel.Text = config.Title or "NEYY HUB"
    ui.TitleLabel.Font = Enum.Font.GothamBlack
    ui.TitleLabel.TextSize = config.TitleSize or 13
    ui.TitleLabel.TextColor3 = theme.Text
    ui.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ui.TitleLabel.Position = UDim2.fromOffset(44, 10)
    ui.TitleLabel.Size = UDim2.new(1, -150, 0, 16)
    ui.TitleLabel.BackgroundTransparency = 1
    ui.TitleLabel.ZIndex = 35
    ui.TitleLabel.Parent = ui.TopBar

    ui.GlitchCyan = ui.TitleLabel:Clone()
    ui.GlitchCyan.Name = "GlitchCyan"
    ui.GlitchCyan.TextColor3 = theme.Cyan
    ui.GlitchCyan.TextTransparency = 0.72
    ui.GlitchCyan.Position = ui.TitleLabel.Position + UDim2.fromOffset(-1, 0)
    ui.GlitchCyan.ZIndex = 33
    ui.GlitchCyan.Parent = ui.TopBar

    ui.GlitchPink = ui.TitleLabel:Clone()
    ui.GlitchPink.Name = "GlitchPink"
    ui.GlitchPink.TextColor3 = theme.Rose
    ui.GlitchPink.TextTransparency = 0.76
    ui.GlitchPink.Position = ui.TitleLabel.Position + UDim2.fromOffset(1, 0)
    ui.GlitchPink.ZIndex = 34
    ui.GlitchPink.Parent = ui.TopBar

    ui.SubTitleLabel = Instance.new("TextLabel")
    ui.SubTitleLabel.Name = "Subtitle"
    ui.SubTitleLabel.Text = config.Subtitle or "ACTIVE CLIENT // NEYY UI"
    ui.SubTitleLabel.Font = Enum.Font.GothamMedium
    ui.SubTitleLabel.TextSize = 9
    ui.SubTitleLabel.TextColor3 = theme.Cyan
    ui.SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ui.SubTitleLabel.Position = UDim2.fromOffset(44, 28)
    ui.SubTitleLabel.Size = UDim2.new(1, -150, 0, 14)
    ui.SubTitleLabel.BackgroundTransparency = 1
    ui.SubTitleLabel.ZIndex = 35
    ui.SubTitleLabel.Parent = ui.TopBar
end

local function BuildCredit(ui, theme)
    ui.CreditLabel = Instance.new("TextLabel")
    ui.CreditLabel.Name = "NeyyUICredit"
    ui.CreditLabel.Size = UDim2.new(1, -20, 0, 14)
    ui.CreditLabel.AnchorPoint = Vector2.new(0.5, 1)
    ui.CreditLabel.Position = UDim2.new(0.5, 0, 1, -4)
    ui.CreditLabel.BackgroundTransparency = 1
    ui.CreditLabel.Text = "NeyyUI  •  github.com/Reneyy-dev/NeyyUI"
    ui.CreditLabel.TextColor3 = theme.Muted
    ui.CreditLabel.TextTransparency = 0.35
    ui.CreditLabel.Font = Enum.Font.GothamMedium
    ui.CreditLabel.TextSize = 8
    ui.CreditLabel.TextXAlignment = Enum.TextXAlignment.Center
    ui.CreditLabel.ZIndex = 90
    ui.CreditLabel.Parent = ui.Main
    return ui.CreditLabel
end

local function BuildBody(ui, theme)
    ui.Body = Instance.new("Frame")
    ui.Body.Name = "Body"
    ui.Body.Size = UDim2.new(1, 0, 1, -theme.TopBarHeight)
    ui.Body.Position = UDim2.fromOffset(0, theme.TopBarHeight)
    ui.Body.BackgroundTransparency = 1
    ui.Body.Active = false
    ui.Body.Parent = ui.Main

    ui.Sidebar = Instance.new("Frame")
    ui.Sidebar.Name = "Sidebar"
    ui.Sidebar.Size = UDim2.new(0, theme.SidebarWidth, 1, -16)
    ui.Sidebar.Position = UDim2.fromOffset(10, 8)
    ui.Sidebar.BackgroundColor3 = theme.Surface
    ui.Sidebar.BackgroundTransparency = 0.34
    ui.Sidebar.BorderSizePixel = 0
    ui.Sidebar.ZIndex = 10
    ui.Sidebar.Parent = ui.Body
    NewCorner(ui.Sidebar, theme.SmallRadius)
    NewStroke(ui.Sidebar, theme.Cyan, 0.84, 1)

    ui.SidebarScroll = Instance.new("ScrollingFrame")
    ui.SidebarScroll.Name = "SidebarScroll"
    ui.SidebarScroll.Size = UDim2.new(1, 0, 1, 0)
    ui.SidebarScroll.BackgroundTransparency = 1
    ui.SidebarScroll.BorderSizePixel = 0
    ui.SidebarScroll.ScrollBarThickness = 0
    ui.SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ui.SidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ui.SidebarScroll.ZIndex = 11
    ui.SidebarScroll.Parent = ui.Sidebar

    ui.SideLayout = Instance.new("UIListLayout")
    ui.SideLayout.Padding = UDim.new(0, 5)
    ui.SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ui.SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ui.SideLayout.Parent = ui.SidebarScroll

    ui.SidePadding = Instance.new("UIPadding")
    ui.SidePadding.PaddingTop = UDim.new(0, 8)
    ui.SidePadding.PaddingLeft = UDim.new(0, 6)
    ui.SidePadding.PaddingRight = UDim.new(0, 6)
    ui.SidePadding.PaddingBottom = UDim.new(0, 8)
    ui.SidePadding.Parent = ui.SidebarScroll

    ui.ContentContainer = Instance.new("Frame")
    ui.ContentContainer.Name = "ContentContainer"
    ui.ContentContainer.Size = UDim2.new(1, -(theme.SidebarWidth + 28), 1, -16)
    ui.ContentContainer.Position = UDim2.fromOffset(theme.SidebarWidth + 18, 8)
    ui.ContentContainer.BackgroundColor3 = theme.Surface
    ui.ContentContainer.BackgroundTransparency = 0.42
    ui.ContentContainer.BorderSizePixel = 0
    ui.ContentContainer.ClipsDescendants = true
    ui.ContentContainer.ZIndex = 10
    ui.ContentContainer.Parent = ui.Body
    NewCorner(ui.ContentContainer, theme.SmallRadius)
    NewStroke(ui.ContentContainer, theme.Purple, 0.78, 1)
end

local function BuildToast(ui, theme)
    ui.Toast = Instance.new("Frame")
    ui.Toast.Name = "Toast"
    ui.Toast.Size = UDim2.new(1, -24, 0, 36)
    ui.Toast.AnchorPoint = Vector2.new(0.5, 1)
    ui.Toast.Position = UDim2.new(0.5, 0, 1, 50)
    ui.Toast.BackgroundColor3 = theme.Surface
    ui.Toast.BorderSizePixel = 0
    ui.Toast.ZIndex = 80
    ui.Toast.Parent = ui.ContentContainer
    NewCorner(ui.Toast, 8)

    ui.ToastStroke = NewStroke(ui.Toast, theme.Cyan, 0, 1)

    ui.ToastIcon = Instance.new("ImageLabel")
    ui.ToastIcon.Size = UDim2.fromOffset(16, 16)
    ui.ToastIcon.Position = UDim2.fromOffset(12, 10)
    ui.ToastIcon.BackgroundTransparency = 1
    ui.ToastIcon.Image = ICONS.Check
    ui.ToastIcon.ImageColor3 = theme.Cyan
    ui.ToastIcon.ScaleType = Enum.ScaleType.Fit
    ui.ToastIcon.ZIndex = 81
    ui.ToastIcon.Parent = ui.Toast

    ui.ToastMsg = Instance.new("TextLabel")
    ui.ToastMsg.Size = UDim2.new(1, -40, 1, 0)
    ui.ToastMsg.Position = UDim2.fromOffset(36, 0)
    ui.ToastMsg.BackgroundTransparency = 1
    ui.ToastMsg.Text = "Ready"
    ui.ToastMsg.TextColor3 = theme.Text
    ui.ToastMsg.Font = Enum.Font.GothamMedium
    ui.ToastMsg.TextSize = 10
    ui.ToastMsg.TextXAlignment = Enum.TextXAlignment.Left
    ui.ToastMsg.ZIndex = 81
    ui.ToastMsg.Parent = ui.Toast
end

local function BuildFloatingPill(ui, config, theme)
    ui.FloatingPill = Instance.new("Frame")
    ui.FloatingPill.Name = "FloatingPill"
    ui.FloatingPill.Size = UDim2.fromOffset(164, 42)
    ui.FloatingPill.AnchorPoint = Vector2.new(0.5, 0)
    ui.FloatingPill.Position = UDim2.new(0.5, 0, 0, 20)
    ui.FloatingPill.BackgroundColor3 = theme.Surface
    ui.FloatingPill.BackgroundTransparency = 0.08
    ui.FloatingPill.BorderSizePixel = 0
    ui.FloatingPill.Visible = false
    ui.FloatingPill.Active = false
    ui.FloatingPill.ZIndex = 100
    ui.FloatingPill.Parent = ui.ScreenGui
    NewCorner(ui.FloatingPill, 21)
    ui.PillStroke = NewStroke(ui.FloatingPill, theme.Cyan, 0.32, 1)

    ui.PillGradient = Instance.new("UIGradient")
    ui.PillGradient.Color = ColorSequence.new(theme.Cyan, theme.Purple)
    ui.PillGradient.Rotation = 18
    ui.PillGradient.Parent = ui.FloatingPill

    ui.PillDragSurface = Instance.new("TextButton")
    ui.PillDragSurface.Name = "DragSurface"
    ui.PillDragSurface.Size = UDim2.fromScale(1, 1)
    ui.PillDragSurface.BackgroundTransparency = 1
    ui.PillDragSurface.Text = ""
    ui.PillDragSurface.AutoButtonColor = false
    ui.PillDragSurface.ZIndex = 101
    ui.PillDragSurface.Parent = ui.FloatingPill

    ui.PillIcon = Instance.new("ImageLabel")
    ui.PillIcon.Size = UDim2.fromOffset(18, 18)
    ui.PillIcon.Position = UDim2.fromOffset(14, 12)
    ui.PillIcon.BackgroundTransparency = 1
    ui.PillIcon.Image = ResolveIcon(config.Icon or "Bolt")
    ui.PillIcon.ImageColor3 = theme.Cyan
    ui.PillIcon.ScaleType = Enum.ScaleType.Fit
    ui.PillIcon.ZIndex = 103
    ui.PillIcon.Parent = ui.FloatingPill

    ui.PillText = Instance.new("TextLabel")
    ui.PillText.Text = config.PillTitle or config.Title or "NEYY UI"
    ui.PillText.Font = Enum.Font.GothamBold
    ui.PillText.TextSize = 11
    ui.PillText.TextColor3 = theme.Text
    ui.PillText.Position = UDim2.fromOffset(38, 0)
    ui.PillText.Size = UDim2.new(1, -74, 1, 0)
    ui.PillText.BackgroundTransparency = 1
    ui.PillText.TextXAlignment = Enum.TextXAlignment.Left
    ui.PillText.TextTruncate = Enum.TextTruncate.AtEnd
    ui.PillText.ZIndex = 103
    ui.PillText.Parent = ui.FloatingPill

    ui.PillExpand = Instance.new("ImageButton")
    ui.PillExpand.Size = UDim2.fromOffset(24, 24)
    ui.PillExpand.Position = UDim2.new(1, -34, 0.5, -12)
    ui.PillExpand.BackgroundTransparency = 1
    ui.PillExpand.Image = ICONS.Expand
    ui.PillExpand.ImageColor3 = theme.Text
    ui.PillExpand.ScaleType = Enum.ScaleType.Fit
    ui.PillExpand.ZIndex = 105
    ui.PillExpand.Parent = ui.FloatingPill
end

local function MakeHeaderButton(Runtime, ui, theme, icon, xOffset, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(32, 32)
    btn.Position = UDim2.new(1, xOffset, 0.5, -16)
    btn.BackgroundColor3 = theme.SurfaceHover
    btn.BackgroundTransparency = 0.45
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 40
    btn.Parent = ui.TopBar
    NewCorner(btn, 8)

    local image = Instance.new("ImageLabel")
    image.Size = UDim2.fromOffset(16, 16)
    image.AnchorPoint = Vector2.new(0.5, 0.5)
    image.Position = UDim2.fromScale(0.5, 0.5)
    image.BackgroundTransparency = 1
    image.Image = ResolveIcon(icon)
    image.ImageColor3 = theme.Muted
    image.ScaleType = Enum.ScaleType.Fit
    image.ZIndex = 41
    image.Parent = btn

    Track(Runtime, btn.MouseEnter:Connect(function()
        if UserInputService.MouseEnabled then
            Tween(Runtime, btn, theme.TweenFast, {BackgroundColor3 = theme.SurfaceActive, BackgroundTransparency = 0.1})
            Tween(Runtime, image, theme.TweenFast, {ImageColor3 = theme.Text})
        end
    end))

    Track(Runtime, btn.MouseLeave:Connect(function()
        if UserInputService.MouseEnabled then
            Tween(Runtime, btn, theme.TweenFast, {BackgroundColor3 = theme.SurfaceHover, BackgroundTransparency = 0.45})
            Tween(Runtime, image, theme.TweenFast, {ImageColor3 = theme.Muted})
        end
    end))

    Track(Runtime, btn.Activated:Connect(function()
        if ui.ClickSound and ui.ClickSound.Parent then
            ui.ClickSound.TimePosition = 0
            ui.ClickSound:Play()
        end
        SafeCallback(Runtime, "Header", callback)
    end))

    return btn
end

local function EnableDrag(Runtime, handle, target, scaleProvider)
    local drag = {
        Active = false,
        Input = nil,
        Start = nil,
        Position = nil,
    }

    Track(Runtime, handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        drag.Active = true
        drag.Start = input.Position
        drag.Position = target.Position

        Track(Runtime, input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                drag.Active = false
            end
        end))
    end))

    Track(Runtime, handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            drag.Input = input
        end
    end))

    Track(Runtime, UserInputService.InputChanged:Connect(function(input)
        if not Runtime.Alive or not drag.Active or input ~= drag.Input or not drag.Start or not drag.Position then
            return
        end

        local delta = input.Position - drag.Start
        local scale = 1
        if type(scaleProvider) == "function" then
            local ok, value = pcall(scaleProvider)
            if ok and type(value) == "number" and value > 0 then
                scale = value
            end
        end

        target.Position = UDim2.new(
            drag.Position.X.Scale,
            drag.Position.X.Offset + delta.X / scale,
            drag.Position.Y.Scale,
            drag.Position.Y.Offset + delta.Y / scale
        )
    end))
end

local function BindResponsiveScale(Runtime, ui, theme, config)
    local cameraConnection = nil

    local function Update()
        local camera = Workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local fitX = (viewport.X - 28) / theme.WindowWidth
        local fitY = (viewport.Y - 28) / theme.WindowHeight
        local baseScale = tonumber(config.Scale) or theme.BaseScale
        local target = math.min(baseScale, fitX, fitY)
        ui.ResponsiveScale.Scale = math.clamp(target, theme.MinScale, baseScale)
    end

    local function BindCamera()
        SafeDisconnect(cameraConnection)
        cameraConnection = nil
        local camera = Workspace.CurrentCamera
        if camera then
            cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(Update)
            table.insert(Runtime.Connections, cameraConnection)
        end
        Update()
    end

    BindCamera()
    Track(Runtime, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if Runtime.Alive then
            task.defer(BindCamera)
        end
    end))
end

local function BuildBlur(Runtime, config, theme)
    if config.Blur == false then
        return
    end

    local old = Lighting:FindFirstChild("NeyyUIBlur")
    if old then
        pcall(function()
            old:Destroy()
        end)
    end

    local blur = Instance.new("BlurEffect")
    blur.Name = "NeyyUIBlur"
    blur.Size = 0
    blur.Parent = Lighting
    Runtime.Blur = blur
    Tween(Runtime, blur, theme.TweenNormal, {Size = tonumber(config.BlurStrength) or theme.BlurStrength})
end

local function BuildEffects(Runtime, ui, theme, config)
    ui.LiquidLayer = Instance.new("Frame")
    ui.LiquidLayer.Name = "LiquidLayer"
    ui.LiquidLayer.Size = UDim2.fromScale(1, 1)
    ui.LiquidLayer.BackgroundTransparency = 1
    ui.LiquidLayer.ClipsDescendants = true
    ui.LiquidLayer.Active = false
    ui.LiquidLayer.ZIndex = 2
    ui.LiquidLayer.Parent = ui.Body

    local liquidCount = math.clamp(tonumber(config.LiquidCount) or theme.LiquidCount, 0, 6)
    for index = 1, liquidCount do
        local blob = Instance.new("Frame")
        local width = math.random(170, 290)
        local height = math.random(120, 235)
        local baseTransparency = 0.84 + math.random() * 0.05

        blob.Name = "LiquidBlob" .. index
        blob.AnchorPoint = Vector2.new(0.5, 0.5)
        blob.Size = UDim2.fromOffset(width, height)
        blob.Position = UDim2.new(
            math.random(8, 92) / 100,
            0,
            math.random(10, 90) / 100,
            0
        )
        blob.BackgroundColor3 = index % 2 == 0 and theme.Purple or theme.Cyan
        blob.BackgroundTransparency = baseTransparency
        blob.BorderSizePixel = 0
        blob.Rotation = math.random(-18, 18)
        blob.Active = false
        blob.ZIndex = 2
        blob.Parent = ui.LiquidLayer
        NewCorner(blob, math.floor(math.min(width, height) / 2))

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.Cyan),
            ColorSequenceKeypoint.new(0.52, theme.Purple),
            ColorSequenceKeypoint.new(1, theme.Rose),
        })
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.10),
            NumberSequenceKeypoint.new(0.55, 0.28),
            NumberSequenceKeypoint.new(1, 0.62),
        })
        gradient.Rotation = math.random(0, 359)
        gradient.Parent = blob

        -- Secondary lobe breaks the perfect ellipse silhouette so it reads as liquid,
        -- while staying cheap enough for mobile executors.
        local lobe = Instance.new("Frame")
        lobe.Name = "Lobe"
        lobe.AnchorPoint = Vector2.new(0.5, 0.5)
        lobe.Size = UDim2.fromScale(0.58, 0.62)
        lobe.Position = UDim2.fromScale(index % 2 == 0 and 0.31 or 0.69, 0.56)
        lobe.BackgroundColor3 = index % 2 == 0 and theme.Cyan or theme.Purple
        lobe.BackgroundTransparency = math.clamp(baseTransparency + 0.04, 0, 0.94)
        lobe.BorderSizePixel = 0
        lobe.Active = false
        lobe.ZIndex = 2
        lobe.Parent = blob
        NewCorner(lobe, math.floor(math.min(width, height) * 0.28))

        local lobeGradient = Instance.new("UIGradient")
        lobeGradient.Color = ColorSequence.new(theme.Purple, theme.Cyan)
        lobeGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(1, 0.72),
        })
        lobeGradient.Rotation = math.random(0, 359)
        lobeGradient.Parent = lobe

        task.spawn(function()
            while Runtime.Alive and blob.Parent do
                local duration = math.random(8, 14)
                local targetWidth = math.max(145, width + math.random(-34, 42))
                local targetHeight = math.max(105, height + math.random(-28, 36))
                local targetTransparency = math.clamp(baseTransparency + math.random(-3, 3) / 100, 0.80, 0.92)

                local move = Tween(Runtime, blob, duration, {
                    Position = UDim2.new(
                        math.random(7, 93) / 100,
                        0,
                        math.random(8, 92) / 100,
                        0
                    ),
                    Size = UDim2.fromOffset(targetWidth, targetHeight),
                    Rotation = math.random(-26, 26),
                    BackgroundTransparency = targetTransparency,
                }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

                Tween(Runtime, gradient, duration, {
                    Rotation = gradient.Rotation + math.random(45, 110),
                }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

                Tween(Runtime, lobe, duration * 0.88, {
                    Position = UDim2.fromScale(
                        index % 2 == 0 and math.random(24, 40) / 100 or math.random(60, 76) / 100,
                        math.random(42, 66) / 100
                    ),
                    Size = UDim2.fromScale(
                        math.random(50, 68) / 100,
                        math.random(52, 72) / 100
                    ),
                    BackgroundTransparency = math.clamp(targetTransparency + 0.04, 0, 0.95),
                }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

                Tween(Runtime, lobeGradient, duration * 0.92, {
                    Rotation = lobeGradient.Rotation - math.random(35, 95),
                }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

                if move then
                    move.Completed:Wait()
                else
                    task.wait(0.5)
                end
            end
        end)
    end

    ui.ParticleLayer = Instance.new("Frame")
    ui.ParticleLayer.Name = "ParticleLayer"
    ui.ParticleLayer.Size = UDim2.fromScale(1, 1)
    ui.ParticleLayer.BackgroundTransparency = 1
    ui.ParticleLayer.ClipsDescendants = true
    ui.ParticleLayer.Active = false
    ui.ParticleLayer.ZIndex = 3
    ui.ParticleLayer.Parent = ui.Body

    local particleCount = math.clamp(tonumber(config.ParticleCount) or theme.ParticleCount, 0, 30)
    for index = 1, particleCount do
        local particle = Instance.new("Frame")
        local px = math.random(2, 4)
        particle.Name = "Particle" .. index
        particle.Size = UDim2.fromOffset(px, px)
        particle.Position = UDim2.new(math.random(2, 98) / 100, 0, math.random(10, 100) / 100, 0)
        particle.BackgroundColor3 = index % 4 == 0 and theme.Purple or theme.Cyan
        particle.BackgroundTransparency = 0.14 + math.random() * 0.20
        particle.BorderSizePixel = 0
        particle.Active = false
        particle.ZIndex = 3
        particle.Parent = ui.ParticleLayer
        NewCorner(particle, px)

        local particleGlow = NewStroke(particle, particle.BackgroundColor3, 0.72, 0.6)
        particleGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        task.spawn(function()
            while Runtime.Alive and particle.Parent do
                particle.Position = UDim2.new(math.random(2, 98) / 100, 0, 1.05, 0)
                particle.BackgroundTransparency = 0.16 + math.random() * 0.18
                local travel = Tween(Runtime, particle, math.random(5, 10), {
                    Position = UDim2.new(math.random(2, 98) / 100, 0, -0.08, 0),
                    BackgroundTransparency = 1,
                }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                if travel then
                    travel.Completed:Wait()
                else
                    task.wait(0.5)
                end
            end
        end)
    end

    task.spawn(function()
        local base = UDim2.fromOffset(44, 10)
        local tickCount = 0
        while Runtime.Alive and ui.TitleLabel.Parent do
            tickCount += 1
            local strong = tickCount % 11 == 0
            local range = strong and 3 or 1
            ui.GlitchCyan.TextTransparency = strong and 0.28 or 0.68
            ui.GlitchPink.TextTransparency = strong and 0.32 or 0.72
            ui.GlitchCyan.Position = base + UDim2.fromOffset(-math.random(1, range), math.random(-1, 1))
            ui.GlitchPink.Position = base + UDim2.fromOffset(math.random(1, range), math.random(-1, 1))
            ui.TitleLabel.Position = base + UDim2.fromOffset(math.random(-1, 1), strong and math.random(-1, 1) or 0)
            task.wait(strong and 0.055 or math.random(11, 20) / 100)
        end
    end)

    task.spawn(function()
        local direction = 1
        while Runtime.Alive and ui.MainGradient.Parent do
            direction = -direction
            local move = Tween(Runtime, ui.MainGradient, 5.2, {Offset = Vector2.new(0.22 * direction, 0)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            Tween(Runtime, ui.TopGradient, 4.6, {Offset = Vector2.new(-0.20 * direction, 0)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            if move then
                move.Completed:Wait()
            else
                task.wait(0.5)
            end
        end
    end)
end

local function SpawnClickBurst(Runtime, parent, accent, originScale)
    if not Runtime.Alive or not parent or not parent.Parent then
        return
    end

    originScale = originScale or Vector2.new(0.5, 0.5)
    local particleCount = 6

    for _ = 1, particleCount do
        local particle = Instance.new("Frame")
        local size = math.random(3, 5)
        particle.Size = UDim2.fromOffset(size, size)
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.Position = UDim2.fromScale(originScale.X, originScale.Y)
        particle.BackgroundColor3 = accent
        particle.BackgroundTransparency = 0.1
        particle.BorderSizePixel = 0
        particle.Active = false
        particle.ZIndex = (parent.ZIndex or 16) + 5
        particle.Parent = parent
        NewCorner(particle, size)

        -- Travel stays inside the button's own bounds (ClipsDescendants keeps it contained),
        -- so this reads as an internal "ripple" confirming the click rather than a stray VFX.
        local angle = math.random() * math.pi * 2
        local distanceX = math.random(14, 34)
        local distanceY = math.random(6, 14)
        local targetPos = UDim2.new(
            originScale.X, math.floor(math.cos(angle) * distanceX),
            originScale.Y, math.floor(math.sin(angle) * distanceY)
        )

        Tween(Runtime, particle, 0.36, {
            Position = targetPos,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(1, 1),
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        task.delay(0.4, function()
            if particle and particle.Parent then
                particle:Destroy()
            end
        end)
    end
end

local function PlayClick(ui)
    if ui.ClickSound and ui.ClickSound.Parent then
        pcall(function()
            ui.ClickSound.TimePosition = 0
            ui.ClickSound:Play()
        end)
    end
end

local function MakeTab(Runtime, ui, theme, window, state, config)
    config = type(config) == "table" and config or {Name = tostring(config)}
    local name = config.Name or config.Title or "Tab"

    local refs = {}
    refs.Button = Instance.new("TextButton")
    refs.Button.Name = name .. "Tab"
    refs.Button.Size = UDim2.new(1, 0, 0, 36)
    refs.Button.BackgroundColor3 = theme.Surface
    refs.Button.BackgroundTransparency = 0.70
    refs.Button.BorderSizePixel = 0
    refs.Button.Text = ""
    refs.Button.AutoButtonColor = false
    refs.Button.ZIndex = 12
    refs.Button.Parent = ui.SidebarScroll
    NewCorner(refs.Button, 7)

    refs.Indicator = Instance.new("Frame")
    refs.Indicator.Name = "Indicator"
    refs.Indicator.Size = UDim2.fromOffset(3, 18)
    refs.Indicator.Position = UDim2.fromOffset(2, 9)
    refs.Indicator.BackgroundColor3 = config.Accent or theme.Cyan
    refs.Indicator.BorderSizePixel = 0
    refs.Indicator.Visible = false
    refs.Indicator.ZIndex = 13
    refs.Indicator.Parent = refs.Button
    NewCorner(refs.Indicator, 2)

    refs.Icon = Instance.new("ImageLabel")
    refs.Icon.Size = UDim2.fromOffset(16, 16)
    refs.Icon.Position = UDim2.fromOffset(12, 10)
    refs.Icon.BackgroundTransparency = 1
    refs.Icon.Image = ResolveIcon(config.Icon or "Misc")
    refs.Icon.ImageColor3 = theme.Muted
    refs.Icon.ScaleType = Enum.ScaleType.Fit
    refs.Icon.ZIndex = 13
    refs.Icon.Parent = refs.Button

    refs.Title = Instance.new("TextLabel")
    refs.Title.Size = UDim2.new(1, -36, 1, 0)
    refs.Title.Position = UDim2.fromOffset(36, 0)
    refs.Title.BackgroundTransparency = 1
    refs.Title.Text = name
    refs.Title.TextColor3 = theme.Muted
    refs.Title.Font = Enum.Font.GothamBold
    refs.Title.TextSize = 10
    refs.Title.TextXAlignment = Enum.TextXAlignment.Left
    refs.Title.TextTruncate = Enum.TextTruncate.AtEnd
    refs.Title.ZIndex = 13
    refs.Title.Parent = refs.Button

    refs.Page = Instance.new("ScrollingFrame")
    refs.Page.Name = name .. "Page"
    refs.Page.Size = UDim2.new(1, 0, 1, 0)
    refs.Page.BackgroundTransparency = 1
    refs.Page.BorderSizePixel = 0
    refs.Page.ScrollBarThickness = 2
    refs.Page.ScrollBarImageColor3 = config.Accent or theme.Cyan
    refs.Page.ScrollBarImageTransparency = 0.4
    refs.Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    refs.Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    refs.Page.Visible = false
    refs.Page.ZIndex = 12
    refs.Page.Parent = ui.ContentContainer

    refs.PagePadding = Instance.new("UIPadding")
    refs.PagePadding.PaddingTop = UDim.new(0, 10)
    refs.PagePadding.PaddingLeft = UDim.new(0, 10)
    refs.PagePadding.PaddingRight = UDim.new(0, 10)
    refs.PagePadding.PaddingBottom = UDim.new(0, 50)
    refs.PagePadding.Parent = refs.Page

    refs.PageLayout = Instance.new("UIListLayout")
    refs.PageLayout.Padding = UDim.new(0, 8)
    refs.PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    refs.PageLayout.Parent = refs.Page

    local Tab = {
        Name = name,
        Refs = refs,
        Window = window,
    }

    function Tab:CreateSection(title)
        local sectionRefs = {}
        sectionRefs.Card = Instance.new("Frame")
        sectionRefs.Card.Name = tostring(title or "Section")
        sectionRefs.Card.Size = UDim2.new(1, 0, 0, 0)
        sectionRefs.Card.AutomaticSize = Enum.AutomaticSize.Y
        sectionRefs.Card.BackgroundColor3 = theme.Surface
        sectionRefs.Card.BackgroundTransparency = 0.24
        sectionRefs.Card.BorderSizePixel = 0
        sectionRefs.Card.ZIndex = 14
        sectionRefs.Card.Parent = refs.Page
        NewCorner(sectionRefs.Card, 8)
        NewStroke(sectionRefs.Card, theme.SurfaceHover, 0.15, 1)

        sectionRefs.Padding = Instance.new("UIPadding")
        sectionRefs.Padding.PaddingTop = UDim.new(0, 10)
        sectionRefs.Padding.PaddingBottom = UDim.new(0, 10)
        sectionRefs.Padding.PaddingLeft = UDim.new(0, 10)
        sectionRefs.Padding.PaddingRight = UDim.new(0, 10)
        sectionRefs.Padding.Parent = sectionRefs.Card

        sectionRefs.Layout = Instance.new("UIListLayout")
        sectionRefs.Layout.Padding = UDim.new(0, 6)
        sectionRefs.Layout.SortOrder = Enum.SortOrder.LayoutOrder
        sectionRefs.Layout.Parent = sectionRefs.Card

        if title then
            sectionRefs.Header = Instance.new("TextLabel")
            sectionRefs.Header.Size = UDim2.new(1, 0, 0, 18)
            sectionRefs.Header.BackgroundTransparency = 1
            sectionRefs.Header.Text = tostring(title)
            sectionRefs.Header.Font = Enum.Font.GothamBold
            sectionRefs.Header.TextSize = 9
            sectionRefs.Header.TextColor3 = config.Accent or theme.Cyan
            sectionRefs.Header.TextXAlignment = Enum.TextXAlignment.Left
            sectionRefs.Header.ZIndex = 15
            sectionRefs.Header.Parent = sectionRefs.Card
        end

        local Section = {
            Tab = Tab,
            Refs = sectionRefs,
        }

        function Section:CreateButton(options)
            options = type(options) == "table" and options or {Name = tostring(options)}
            local buttonRefs = {}
            buttonRefs.Button = Instance.new("TextButton")
            buttonRefs.Button.Size = UDim2.new(1, 0, 0, 34)
            buttonRefs.Button.BackgroundColor3 = theme.SurfaceHover
            buttonRefs.Button.BorderSizePixel = 0
            buttonRefs.Button.Text = ""
            buttonRefs.Button.AutoButtonColor = false
            buttonRefs.Button.ClipsDescendants = true
            buttonRefs.Button.ZIndex = 16
            buttonRefs.Button.Parent = sectionRefs.Card
            NewCorner(buttonRefs.Button, 7)

            buttonRefs.PunchScale = Instance.new("UIScale")
            buttonRefs.PunchScale.Scale = 1
            buttonRefs.PunchScale.Parent = buttonRefs.Button

            local accent = options.Color or options.Accent or theme.Cyan
            buttonRefs.Stroke = NewStroke(buttonRefs.Button, accent, 0.48, 1)

            local icon = options.Icon and ResolveIcon(options.Icon) or nil
            local offset = icon and 32 or 12
            if icon then
                buttonRefs.Icon = Instance.new("ImageLabel")
                buttonRefs.Icon.Size = UDim2.fromOffset(15, 15)
                buttonRefs.Icon.Position = UDim2.fromOffset(10, 9)
                buttonRefs.Icon.BackgroundTransparency = 1
                buttonRefs.Icon.Image = icon
                buttonRefs.Icon.ImageColor3 = accent
                buttonRefs.Icon.ScaleType = Enum.ScaleType.Fit
                buttonRefs.Icon.ZIndex = 17
                buttonRefs.Icon.Parent = buttonRefs.Button
            end

            buttonRefs.Label = Instance.new("TextLabel")
            buttonRefs.Label.Size = UDim2.new(1, -offset, 1, 0)
            buttonRefs.Label.Position = UDim2.fromOffset(offset, 0)
            buttonRefs.Label.BackgroundTransparency = 1
            buttonRefs.Label.Text = options.Name or options.Title or "Button"
            buttonRefs.Label.TextColor3 = theme.Text
            buttonRefs.Label.Font = Enum.Font.GothamMedium
            buttonRefs.Label.TextSize = 10
            buttonRefs.Label.TextXAlignment = Enum.TextXAlignment.Left
            buttonRefs.Label.TextTruncate = Enum.TextTruncate.AtEnd
            buttonRefs.Label.ZIndex = 17
            buttonRefs.Label.Parent = buttonRefs.Button

            local control = {Refs = buttonRefs, Disabled = false}

            function control:SetText(text)
                buttonRefs.Label.Text = tostring(text)
            end

            function control:SetDisabled(value)
                control.Disabled = value == true
                buttonRefs.Button.Active = not control.Disabled
                Tween(Runtime, buttonRefs.Button, theme.TweenFast, {
                    BackgroundTransparency = control.Disabled and 0.45 or 0,
                })
                buttonRefs.Label.TextColor3 = control.Disabled and theme.Muted or theme.Text
            end

            Track(Runtime, buttonRefs.Button.MouseEnter:Connect(function()
                if UserInputService.MouseEnabled and not control.Disabled then
                    Tween(Runtime, buttonRefs.Button, theme.TweenFast, {BackgroundColor3 = theme.SurfaceActive})
                    Tween(Runtime, buttonRefs.Stroke, theme.TweenFast, {Transparency = 0.08})
                end
            end))

            Track(Runtime, buttonRefs.Button.MouseLeave:Connect(function()
                if UserInputService.MouseEnabled then
                    Tween(Runtime, buttonRefs.Button, theme.TweenFast, {BackgroundColor3 = theme.SurfaceHover})
                    Tween(Runtime, buttonRefs.Stroke, theme.TweenFast, {Transparency = 0.48})
                end
            end))

            Track(Runtime, buttonRefs.Button.Activated:Connect(function()
                if control.Disabled then
                    return
                end
                PlayClick(ui)

                buttonRefs.PunchScale.Scale = 0.92
                Tween(Runtime, buttonRefs.PunchScale, 0.16, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                SpawnClickBurst(Runtime, buttonRefs.Button, accent)

                SafeCallback(Runtime, options.Name or "Button", options.Callback, control)
            end))

            return control
        end

        function Section:CreateToggle(options)
            options = type(options) == "table" and options or {Name = tostring(options)}
            local toggleRefs = {}
            toggleRefs.Container = Instance.new("Frame")
            toggleRefs.Container.Size = UDim2.new(1, 0, 0, 36)
            toggleRefs.Container.BackgroundColor3 = theme.SurfaceHover
            toggleRefs.Container.BorderSizePixel = 0
            toggleRefs.Container.ZIndex = 16
            toggleRefs.Container.Parent = sectionRefs.Card
            NewCorner(toggleRefs.Container, 7)

            toggleRefs.Label = Instance.new("TextLabel")
            toggleRefs.Label.Size = UDim2.new(1, -60, 1, 0)
            toggleRefs.Label.Position = UDim2.fromOffset(12, 0)
            toggleRefs.Label.BackgroundTransparency = 1
            toggleRefs.Label.Text = options.Name or options.Title or "Toggle"
            toggleRefs.Label.TextColor3 = theme.Text
            toggleRefs.Label.Font = Enum.Font.GothamMedium
            toggleRefs.Label.TextSize = 10
            toggleRefs.Label.TextXAlignment = Enum.TextXAlignment.Left
            toggleRefs.Label.TextTruncate = Enum.TextTruncate.AtEnd
            toggleRefs.Label.ZIndex = 17
            toggleRefs.Label.Parent = toggleRefs.Container

            toggleRefs.Track = Instance.new("TextButton")
            toggleRefs.Track.Size = UDim2.fromOffset(38, 20)
            toggleRefs.Track.Position = UDim2.new(1, -48, 0.5, -10)
            toggleRefs.Track.BorderSizePixel = 0
            toggleRefs.Track.Text = ""
            toggleRefs.Track.AutoButtonColor = false
            toggleRefs.Track.ZIndex = 18
            toggleRefs.Track.Parent = toggleRefs.Container
            NewCorner(toggleRefs.Track, 10)

            toggleRefs.Knob = Instance.new("Frame")
            toggleRefs.Knob.Size = UDim2.fromOffset(14, 14)
            toggleRefs.Knob.BorderSizePixel = 0
            toggleRefs.Knob.ZIndex = 19
            toggleRefs.Knob.Parent = toggleRefs.Track
            NewCorner(toggleRefs.Knob, 7)

            local control = {Refs = toggleRefs, Value = options.Default == true}

            local function Render(animated)
                local duration = animated and theme.TweenFast or 0
                local accent = options.Color or options.Accent or theme.Cyan
                Tween(Runtime, toggleRefs.Track, duration, {
                    BackgroundColor3 = control.Value and accent or theme.Surface,
                })
                Tween(Runtime, toggleRefs.Knob, duration, {
                    Position = control.Value and UDim2.new(1, -17, 0.5, -7) or UDim2.fromOffset(3, 3),
                    BackgroundColor3 = control.Value and Color3.fromRGB(10, 15, 25) or theme.Muted,
                })
            end

            function control:Set(value, silent)
                local nextValue = value == true
                if control.Value == nextValue then
                    Render(true)
                    return
                end
                control.Value = nextValue
                Render(true)
                if not silent then
                    SafeCallback(Runtime, options.Name or "Toggle", options.Callback, control.Value)
                end
            end

            function control:Get()
                return control.Value
            end

            Render(false)

            Track(Runtime, toggleRefs.Track.Activated:Connect(function()
                PlayClick(ui)
                control:Set(not control.Value, false)
            end))

            return control
        end

        function Section:CreateInput(options)
            options = type(options) == "table" and options or {Name = tostring(options)}
            local inputRefs = {}
            inputRefs.Holder = Instance.new("Frame")
            inputRefs.Holder.Size = UDim2.new(1, 0, 0, 34)
            inputRefs.Holder.BackgroundColor3 = theme.SurfaceHover
            inputRefs.Holder.BorderSizePixel = 0
            inputRefs.Holder.ZIndex = 16
            inputRefs.Holder.Parent = sectionRefs.Card
            NewCorner(inputRefs.Holder, 7)
            inputRefs.Stroke = NewStroke(inputRefs.Holder, theme.SurfaceActive, 0, 1)

            inputRefs.Box = Instance.new("TextBox")
            inputRefs.Box.Size = UDim2.new(1, -20, 1, 0)
            inputRefs.Box.Position = UDim2.fromOffset(10, 0)
            inputRefs.Box.BackgroundTransparency = 1
            inputRefs.Box.Text = tostring(options.Default or "")
            inputRefs.Box.PlaceholderText = options.Placeholder or options.Name or "Input value..."
            inputRefs.Box.TextColor3 = theme.Text
            inputRefs.Box.PlaceholderColor3 = theme.Muted
            inputRefs.Box.Font = Enum.Font.GothamMedium
            inputRefs.Box.TextSize = 10
            inputRefs.Box.TextXAlignment = Enum.TextXAlignment.Left
            inputRefs.Box.ClearTextOnFocus = options.ClearTextOnFocus == true
            inputRefs.Box.ZIndex = 17
            inputRefs.Box.Parent = inputRefs.Holder

            local control = {Refs = inputRefs}

            function control:Set(value, silent)
                inputRefs.Box.Text = tostring(value or "")
                if not silent then
                    SafeCallback(Runtime, options.Name or "Input", options.Callback, inputRefs.Box.Text)
                end
            end

            function control:Get()
                return inputRefs.Box.Text
            end

            Track(Runtime, inputRefs.Box.Focused:Connect(function()
                Tween(Runtime, inputRefs.Stroke, theme.TweenFast, {Color = options.Color or theme.Cyan})
            end))

            Track(Runtime, inputRefs.Box.FocusLost:Connect(function(enterPressed)
                Tween(Runtime, inputRefs.Stroke, theme.TweenFast, {Color = theme.SurfaceActive})
                SafeCallback(Runtime, options.Name or "Input", options.Callback, inputRefs.Box.Text, enterPressed)
            end))

            return control
        end

        function Section:CreateDropdown(options)
            options = type(options) == "table" and options or {}
            local dropdownRefs = {}
            dropdownRefs.Container = Instance.new("Frame")
            dropdownRefs.Container.Size = UDim2.new(1, 0, 0, 0)
            dropdownRefs.Container.AutomaticSize = Enum.AutomaticSize.Y
            dropdownRefs.Container.BackgroundTransparency = 1
            dropdownRefs.Container.ZIndex = 16
            dropdownRefs.Container.Parent = sectionRefs.Card

            dropdownRefs.Layout = Instance.new("UIListLayout")
            dropdownRefs.Layout.Padding = UDim.new(0, 5)
            dropdownRefs.Layout.SortOrder = Enum.SortOrder.LayoutOrder
            dropdownRefs.Layout.Parent = dropdownRefs.Container

            dropdownRefs.Header = Instance.new("TextButton")
            dropdownRefs.Header.Size = UDim2.new(1, 0, 0, 34)
            dropdownRefs.Header.BackgroundColor3 = theme.SurfaceHover
            dropdownRefs.Header.BorderSizePixel = 0
            dropdownRefs.Header.Text = ""
            dropdownRefs.Header.AutoButtonColor = false
            dropdownRefs.Header.ZIndex = 17
            dropdownRefs.Header.Parent = dropdownRefs.Container
            NewCorner(dropdownRefs.Header, 7)
            dropdownRefs.Stroke = NewStroke(dropdownRefs.Header, options.Color or theme.Purple, 0.52, 1)

            dropdownRefs.Label = Instance.new("TextLabel")
            dropdownRefs.Label.Size = UDim2.new(1, -42, 1, 0)
            dropdownRefs.Label.Position = UDim2.fromOffset(12, 0)
            dropdownRefs.Label.BackgroundTransparency = 1
            dropdownRefs.Label.TextColor3 = theme.Text
            dropdownRefs.Label.Font = Enum.Font.GothamMedium
            dropdownRefs.Label.TextSize = 10
            dropdownRefs.Label.TextXAlignment = Enum.TextXAlignment.Left
            dropdownRefs.Label.TextTruncate = Enum.TextTruncate.AtEnd
            dropdownRefs.Label.ZIndex = 18
            dropdownRefs.Label.Parent = dropdownRefs.Header

            dropdownRefs.Arrow = Instance.new("TextLabel")
            dropdownRefs.Arrow.Size = UDim2.fromOffset(24, 34)
            dropdownRefs.Arrow.Position = UDim2.new(1, -30, 0, 0)
            dropdownRefs.Arrow.BackgroundTransparency = 1
            dropdownRefs.Arrow.Text = "▼"
            dropdownRefs.Arrow.TextColor3 = theme.Muted
            dropdownRefs.Arrow.Font = Enum.Font.GothamBold
            dropdownRefs.Arrow.TextSize = 14
            dropdownRefs.Arrow.ZIndex = 18
            dropdownRefs.Arrow.Parent = dropdownRefs.Header

            dropdownRefs.Options = Instance.new("Frame")
            dropdownRefs.Options.Size = UDim2.new(1, 0, 0, 0)
            dropdownRefs.Options.AutomaticSize = Enum.AutomaticSize.Y
            dropdownRefs.Options.BackgroundTransparency = 1
            dropdownRefs.Options.Visible = false
            dropdownRefs.Options.ZIndex = 17
            dropdownRefs.Options.Parent = dropdownRefs.Container

            dropdownRefs.OptionsLayout = Instance.new("UIListLayout")
            dropdownRefs.OptionsLayout.Padding = UDim.new(0, 4)
            dropdownRefs.OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            dropdownRefs.OptionsLayout.Parent = dropdownRefs.Options

            local control = {
                Refs = dropdownRefs,
                Value = options.Default,
                Items = {},
                Open = false,
            }

            local function UpdateLabel()
                local prefix = options.Name or options.Title or "Select"
                dropdownRefs.Label.Text = prefix .. ": " .. tostring(control.Value or "—")
            end

            local function SetOpen(value)
                control.Open = value == true
                dropdownRefs.Options.Visible = control.Open
                dropdownRefs.Arrow.Text = control.Open and "▲" or "▼"
                Tween(Runtime, dropdownRefs.Stroke, theme.TweenFast, {
                    Transparency = control.Open and 0.12 or 0.52,
                })
            end

            local function ClearOptions()
                for _, child in ipairs(dropdownRefs.Options:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
            end

            local function BuildOptions(items)
                ClearOptions()
                control.Items = {}
                for _, item in ipairs(items or {}) do
                    table.insert(control.Items, item)
                    local optionButton = Instance.new("TextButton")
                    optionButton.Size = UDim2.new(1, 0, 0, 30)
                    optionButton.BackgroundColor3 = theme.Surface
                    optionButton.BackgroundTransparency = 0.16
                    optionButton.BorderSizePixel = 0
                    optionButton.Text = "  " .. tostring(item)
                    optionButton.TextColor3 = theme.Muted
                    optionButton.Font = Enum.Font.GothamMedium
                    optionButton.TextSize = 9
                    optionButton.TextXAlignment = Enum.TextXAlignment.Left
                    optionButton.AutoButtonColor = false
                    optionButton.ZIndex = 18
                    optionButton.Parent = dropdownRefs.Options
                    NewCorner(optionButton, 6)

                    Track(Runtime, optionButton.Activated:Connect(function()
                        PlayClick(ui)
                        control.Value = item
                        UpdateLabel()
                        SetOpen(false)
                        SafeCallback(Runtime, options.Name or "Dropdown", options.Callback, item)
                    end))
                end
            end

            function control:Set(value, silent)
                control.Value = value
                UpdateLabel()
                if not silent then
                    SafeCallback(Runtime, options.Name or "Dropdown", options.Callback, value)
                end
            end

            function control:Get()
                return control.Value
            end

            function control:Refresh(items, keepValue)
                BuildOptions(items or {})
                if not keepValue then
                    control.Value = options.Default or control.Items[1]
                elseif control.Value == nil then
                    control.Value = control.Items[1]
                end
                UpdateLabel()
            end

            BuildOptions(options.Options or options.Values or {})
            if control.Value == nil then
                control.Value = control.Items[1]
            end
            UpdateLabel()

            Track(Runtime, dropdownRefs.Header.Activated:Connect(function()
                PlayClick(ui)
                SetOpen(not control.Open)
            end))

            return control
        end

        function Section:CreateStat(options)
            options = type(options) == "table" and options or {Name = tostring(options)}
            local refsStat = {}
            refsStat.Row = Instance.new("Frame")
            refsStat.Row.Size = UDim2.new(1, 0, 0, 24)
            refsStat.Row.BackgroundTransparency = 1
            refsStat.Row.ZIndex = 16
            refsStat.Row.Parent = sectionRefs.Card

            refsStat.Label = Instance.new("TextLabel")
            refsStat.Label.Size = UDim2.new(0.55, 0, 1, 0)
            refsStat.Label.BackgroundTransparency = 1
            refsStat.Label.Text = options.Name or options.Title or "Stat"
            refsStat.Label.Font = Enum.Font.Gotham
            refsStat.Label.TextSize = 9
            refsStat.Label.TextColor3 = theme.Muted
            refsStat.Label.TextXAlignment = Enum.TextXAlignment.Left
            refsStat.Label.ZIndex = 17
            refsStat.Label.Parent = refsStat.Row

            refsStat.Value = Instance.new("TextLabel")
            refsStat.Value.Size = UDim2.new(0.45, 0, 1, 0)
            refsStat.Value.Position = UDim2.new(0.55, 0, 0, 0)
            refsStat.Value.BackgroundTransparency = 1
            refsStat.Value.Text = tostring(options.Value or options.Default or "—")
            refsStat.Value.Font = Enum.Font.GothamBold
            refsStat.Value.TextSize = 9
            refsStat.Value.TextColor3 = options.Color or theme.Text
            refsStat.Value.TextXAlignment = Enum.TextXAlignment.Right
            refsStat.Value.TextTruncate = Enum.TextTruncate.AtEnd
            refsStat.Value.ZIndex = 17
            refsStat.Value.Parent = refsStat.Row

            local control = {Refs = refsStat}
            function control:Set(value)
                refsStat.Value.Text = tostring(value)
            end
            function control:SetColor(color)
                refsStat.Value.TextColor3 = color
            end
            return control
        end

        function Section:CreateParagraph(options)
            options = type(options) == "table" and options or {Content = tostring(options)}
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 28)
            label.AutomaticSize = Enum.AutomaticSize.Y
            label.BackgroundTransparency = 1
            label.TextWrapped = true
            label.Text = tostring(options.Content or options.Text or options.Description or "")
            label.TextColor3 = options.Color or theme.Muted
            label.Font = Enum.Font.Gotham
            label.TextSize = options.TextSize or 9
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Top
            label.ZIndex = 15
            label.Parent = sectionRefs.Card

            local control = {Label = label}
            function control:Set(text)
                label.Text = tostring(text)
            end
            return control
        end

        function Section:CreateSlider(options)
            options = type(options) == "table" and options or {Name = tostring(options)}
            local min = tonumber(options.Min) or 0
            local max = tonumber(options.Max) or 100
            if max <= min then
                max = min + 1
            end
            local increment = tonumber(options.Increment) or 1
            local accent = options.Color or options.Accent or theme.Cyan

            local sliderRefs = {}
            sliderRefs.Container = Instance.new("Frame")
            sliderRefs.Container.Size = UDim2.new(1, 0, 0, 46)
            sliderRefs.Container.BackgroundColor3 = theme.SurfaceHover
            sliderRefs.Container.BorderSizePixel = 0
            sliderRefs.Container.ZIndex = 16
            sliderRefs.Container.Parent = sectionRefs.Card
            NewCorner(sliderRefs.Container, 7)

            sliderRefs.Label = Instance.new("TextLabel")
            sliderRefs.Label.Size = UDim2.new(1, -70, 0, 20)
            sliderRefs.Label.Position = UDim2.fromOffset(12, 4)
            sliderRefs.Label.BackgroundTransparency = 1
            sliderRefs.Label.Text = options.Name or options.Title or "Slider"
            sliderRefs.Label.TextColor3 = theme.Text
            sliderRefs.Label.Font = Enum.Font.GothamMedium
            sliderRefs.Label.TextSize = 10
            sliderRefs.Label.TextXAlignment = Enum.TextXAlignment.Left
            sliderRefs.Label.TextTruncate = Enum.TextTruncate.AtEnd
            sliderRefs.Label.ZIndex = 17
            sliderRefs.Label.Parent = sliderRefs.Container

            sliderRefs.ValueLabel = Instance.new("TextLabel")
            sliderRefs.ValueLabel.Size = UDim2.fromOffset(56, 20)
            sliderRefs.ValueLabel.Position = UDim2.new(1, -66, 0, 4)
            sliderRefs.ValueLabel.BackgroundTransparency = 1
            sliderRefs.ValueLabel.Text = tostring(options.Default or min)
            sliderRefs.ValueLabel.TextColor3 = accent
            sliderRefs.ValueLabel.Font = Enum.Font.GothamBold
            sliderRefs.ValueLabel.TextSize = 10
            sliderRefs.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            sliderRefs.ValueLabel.TextTruncate = Enum.TextTruncate.AtEnd
            sliderRefs.ValueLabel.ZIndex = 17
            sliderRefs.ValueLabel.Parent = sliderRefs.Container

            sliderRefs.Bar = Instance.new("Frame")
            sliderRefs.Bar.Size = UDim2.new(1, -24, 0, 6)
            sliderRefs.Bar.Position = UDim2.new(0, 12, 1, -14)
            sliderRefs.Bar.BackgroundColor3 = theme.Surface
            sliderRefs.Bar.BorderSizePixel = 0
            sliderRefs.Bar.ZIndex = 17
            sliderRefs.Bar.Parent = sliderRefs.Container
            NewCorner(sliderRefs.Bar, 3)

            sliderRefs.Fill = Instance.new("Frame")
            sliderRefs.Fill.Size = UDim2.new(0, 0, 1, 0)
            sliderRefs.Fill.BackgroundColor3 = accent
            sliderRefs.Fill.BorderSizePixel = 0
            sliderRefs.Fill.ZIndex = 18
            sliderRefs.Fill.Parent = sliderRefs.Bar
            NewCorner(sliderRefs.Fill, 3)

            sliderRefs.Knob = Instance.new("Frame")
            sliderRefs.Knob.Size = UDim2.fromOffset(12, 12)
            sliderRefs.Knob.AnchorPoint = Vector2.new(0.5, 0.5)
            sliderRefs.Knob.Position = UDim2.new(0, 0, 0.5, 0)
            sliderRefs.Knob.BackgroundColor3 = theme.Text
            sliderRefs.Knob.BorderSizePixel = 0
            sliderRefs.Knob.ZIndex = 19
            sliderRefs.Knob.Parent = sliderRefs.Bar
            NewCorner(sliderRefs.Knob, 6)
            NewStroke(sliderRefs.Knob, accent, 0, 2)

            sliderRefs.HitArea = Instance.new("TextButton")
            sliderRefs.HitArea.Size = UDim2.new(1, 0, 1, 14)
            sliderRefs.HitArea.Position = UDim2.new(0, 0, 0, -7)
            sliderRefs.HitArea.BackgroundTransparency = 1
            sliderRefs.HitArea.Text = ""
            sliderRefs.HitArea.AutoButtonColor = false
            sliderRefs.HitArea.ZIndex = 19
            sliderRefs.HitArea.Parent = sliderRefs.Bar

            local control = {Refs = sliderRefs, Value = tonumber(options.Default) or min}

            local function RoundToIncrement(value)
                if increment <= 0 then
                    return value
                end
                return math.floor((value - min) / increment + 0.5) * increment + min
            end

            local function Render(animated)
                local duration = animated and theme.TweenFast or 0
                local alpha = math.clamp((control.Value - min) / (max - min), 0, 1)
                Tween(Runtime, sliderRefs.Fill, duration, {Size = UDim2.new(alpha, 0, 1, 0)})
                Tween(Runtime, sliderRefs.Knob, duration, {Position = UDim2.new(alpha, 0, 0.5, 0)})
                sliderRefs.ValueLabel.Text = options.ValueFormat
                    and string.format(options.ValueFormat, control.Value)
                    or tostring(control.Value)
            end

            function control:Set(value, silent)
                value = math.clamp(RoundToIncrement(tonumber(value) or min), min, max)
                if control.Value == value then
                    Render(true)
                    return
                end
                control.Value = value
                Render(true)
                if not silent then
                    SafeCallback(Runtime, options.Name or "Slider", options.Callback, control.Value)
                end
            end

            function control:Get()
                return control.Value
            end

            Render(false)

            local dragging = false
            local function UpdateFromInput(inputX)
                local barPos = sliderRefs.Bar.AbsolutePosition.X
                local barSize = sliderRefs.Bar.AbsoluteSize.X
                if barSize <= 0 then
                    return
                end
                local alpha = math.clamp((inputX - barPos) / barSize, 0, 1)
                control:Set(min + alpha * (max - min))
            end

            Track(Runtime, sliderRefs.HitArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateFromInput(input.Position.X)
                end
            end))

            Track(Runtime, sliderRefs.HitArea.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))

            Track(Runtime, UserInputService.InputChanged:Connect(function(input)
                if not Runtime.Alive or not dragging then
                    return
                end
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    UpdateFromInput(input.Position.X)
                end
            end))

            return control
        end

        function Section:CreateColorPicker(options)
            options = type(options) == "table" and options or {Name = tostring(options)}
            local defaultColor = typeof(options.Default) == "Color3" and options.Default or Color3.fromRGB(45, 226, 255)
            local hsv = {}
            hsv.H, hsv.S, hsv.V = Color3.toHSV(defaultColor)

            local cpRefs = {}
            cpRefs.Container = Instance.new("Frame")
            cpRefs.Container.Size = UDim2.new(1, 0, 0, 0)
            cpRefs.Container.AutomaticSize = Enum.AutomaticSize.Y
            cpRefs.Container.BackgroundTransparency = 1
            cpRefs.Container.ZIndex = 16
            cpRefs.Container.Parent = sectionRefs.Card

            cpRefs.Layout = Instance.new("UIListLayout")
            cpRefs.Layout.Padding = UDim.new(0, 8)
            cpRefs.Layout.SortOrder = Enum.SortOrder.LayoutOrder
            cpRefs.Layout.Parent = cpRefs.Container

            cpRefs.Header = Instance.new("TextButton")
            cpRefs.Header.Size = UDim2.new(1, 0, 0, 34)
            cpRefs.Header.BackgroundColor3 = theme.SurfaceHover
            cpRefs.Header.BorderSizePixel = 0
            cpRefs.Header.Text = ""
            cpRefs.Header.AutoButtonColor = false
            cpRefs.Header.ZIndex = 17
            cpRefs.Header.Parent = cpRefs.Container
            NewCorner(cpRefs.Header, 7)
            cpRefs.HeaderStroke = NewStroke(cpRefs.Header, theme.SurfaceActive, 0, 1)

            cpRefs.Label = Instance.new("TextLabel")
            cpRefs.Label.Size = UDim2.new(1, -60, 1, 0)
            cpRefs.Label.Position = UDim2.fromOffset(12, 0)
            cpRefs.Label.BackgroundTransparency = 1
            cpRefs.Label.Text = options.Name or options.Title or "Color"
            cpRefs.Label.TextColor3 = theme.Text
            cpRefs.Label.Font = Enum.Font.GothamMedium
            cpRefs.Label.TextSize = 10
            cpRefs.Label.TextXAlignment = Enum.TextXAlignment.Left
            cpRefs.Label.TextTruncate = Enum.TextTruncate.AtEnd
            cpRefs.Label.ZIndex = 18
            cpRefs.Label.Parent = cpRefs.Header

            cpRefs.Swatch = Instance.new("Frame")
            cpRefs.Swatch.Size = UDim2.fromOffset(30, 18)
            cpRefs.Swatch.Position = UDim2.new(1, -42, 0.5, -9)
            cpRefs.Swatch.BackgroundColor3 = defaultColor
            cpRefs.Swatch.BorderSizePixel = 0
            cpRefs.Swatch.ZIndex = 18
            cpRefs.Swatch.Parent = cpRefs.Header
            NewCorner(cpRefs.Swatch, 5)
            NewStroke(cpRefs.Swatch, theme.Text, 0.7, 1)

            cpRefs.Panel = Instance.new("Frame")
            cpRefs.Panel.Size = UDim2.new(1, 0, 0, 0)
            cpRefs.Panel.AutomaticSize = Enum.AutomaticSize.Y
            cpRefs.Panel.BackgroundTransparency = 1
            cpRefs.Panel.Visible = false
            cpRefs.Panel.ZIndex = 17
            cpRefs.Panel.Parent = cpRefs.Container

            cpRefs.PanelLayout = Instance.new("UIListLayout")
            cpRefs.PanelLayout.Padding = UDim.new(0, 8)
            cpRefs.PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
            cpRefs.PanelLayout.Parent = cpRefs.Panel

            cpRefs.SVMap = Instance.new("Frame")
            cpRefs.SVMap.Size = UDim2.new(1, 0, 0, 110)
            cpRefs.SVMap.BackgroundColor3 = Color3.fromHSV(hsv.H, 1, 1)
            cpRefs.SVMap.BorderSizePixel = 0
            cpRefs.SVMap.ClipsDescendants = true
            cpRefs.SVMap.ZIndex = 18
            cpRefs.SVMap.Parent = cpRefs.Panel
            NewCorner(cpRefs.SVMap, 7)

            cpRefs.SVWhite = Instance.new("Frame")
            cpRefs.SVWhite.Size = UDim2.fromScale(1, 1)
            cpRefs.SVWhite.BackgroundColor3 = Color3.new(1, 1, 1)
            cpRefs.SVWhite.BorderSizePixel = 0
            cpRefs.SVWhite.ZIndex = 18
            cpRefs.SVWhite.Parent = cpRefs.SVMap
            local svWhiteGradient = Instance.new("UIGradient")
            svWhiteGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
            svWhiteGradient.Transparency = NumberSequence.new(0, 1)
            svWhiteGradient.Parent = cpRefs.SVWhite

            cpRefs.SVBlack = Instance.new("Frame")
            cpRefs.SVBlack.Size = UDim2.fromScale(1, 1)
            cpRefs.SVBlack.BackgroundColor3 = Color3.new(0, 0, 0)
            cpRefs.SVBlack.BorderSizePixel = 0
            cpRefs.SVBlack.ZIndex = 19
            cpRefs.SVBlack.Parent = cpRefs.SVMap
            local svBlackGradient = Instance.new("UIGradient")
            svBlackGradient.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
            svBlackGradient.Transparency = NumberSequence.new(1, 0)
            svBlackGradient.Rotation = 90
            svBlackGradient.Parent = cpRefs.SVBlack

            cpRefs.SVCursor = Instance.new("Frame")
            cpRefs.SVCursor.Size = UDim2.fromOffset(10, 10)
            cpRefs.SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            cpRefs.SVCursor.BackgroundTransparency = 1
            cpRefs.SVCursor.ZIndex = 20
            cpRefs.SVCursor.Parent = cpRefs.SVMap
            NewCorner(cpRefs.SVCursor, 5)
            NewStroke(cpRefs.SVCursor, Color3.new(1, 1, 1), 0, 2)

            cpRefs.SVHit = Instance.new("TextButton")
            cpRefs.SVHit.Size = UDim2.fromScale(1, 1)
            cpRefs.SVHit.BackgroundTransparency = 1
            cpRefs.SVHit.Text = ""
            cpRefs.SVHit.AutoButtonColor = false
            cpRefs.SVHit.ZIndex = 21
            cpRefs.SVHit.Parent = cpRefs.SVMap

            cpRefs.HueBar = Instance.new("Frame")
            cpRefs.HueBar.Size = UDim2.new(1, 0, 0, 16)
            cpRefs.HueBar.BorderSizePixel = 0
            cpRefs.HueBar.ZIndex = 18
            cpRefs.HueBar.Parent = cpRefs.Panel
            NewCorner(cpRefs.HueBar, 8)

            local hueGradient = Instance.new("UIGradient")
            hueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.000, Color3.fromHSV(0 / 6, 1, 1)),
                ColorSequenceKeypoint.new(0.167, Color3.fromHSV(1 / 6, 1, 1)),
                ColorSequenceKeypoint.new(0.333, Color3.fromHSV(2 / 6, 1, 1)),
                ColorSequenceKeypoint.new(0.500, Color3.fromHSV(3 / 6, 1, 1)),
                ColorSequenceKeypoint.new(0.667, Color3.fromHSV(4 / 6, 1, 1)),
                ColorSequenceKeypoint.new(0.833, Color3.fromHSV(5 / 6, 1, 1)),
                ColorSequenceKeypoint.new(1.000, Color3.fromHSV(6 / 6, 1, 1)),
            })
            hueGradient.Parent = cpRefs.HueBar

            cpRefs.HueCursor = Instance.new("Frame")
            cpRefs.HueCursor.Size = UDim2.fromOffset(4, 20)
            cpRefs.HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            cpRefs.HueCursor.Position = UDim2.new(hsv.H, 0, 0.5, 0)
            cpRefs.HueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
            cpRefs.HueCursor.BorderSizePixel = 0
            cpRefs.HueCursor.ZIndex = 19
            cpRefs.HueCursor.Parent = cpRefs.HueBar
            NewCorner(cpRefs.HueCursor, 2)

            cpRefs.HueHit = Instance.new("TextButton")
            cpRefs.HueHit.Size = UDim2.new(1, 0, 1, 14)
            cpRefs.HueHit.Position = UDim2.new(0, 0, 0, -7)
            cpRefs.HueHit.BackgroundTransparency = 1
            cpRefs.HueHit.Text = ""
            cpRefs.HueHit.AutoButtonColor = false
            cpRefs.HueHit.ZIndex = 19
            cpRefs.HueHit.Parent = cpRefs.HueBar

            local control = {Refs = cpRefs, Value = defaultColor}

            local function UpdateCursors()
                cpRefs.SVCursor.Position = UDim2.new(hsv.S, 0, 1 - hsv.V, 0)
                cpRefs.HueCursor.Position = UDim2.new(hsv.H, 0, 0.5, 0)
                cpRefs.SVMap.BackgroundColor3 = Color3.fromHSV(hsv.H, 1, 1)
            end

            local function ApplyColor(silent)
                control.Value = Color3.fromHSV(hsv.H, hsv.S, hsv.V)
                cpRefs.Swatch.BackgroundColor3 = control.Value
                if not silent then
                    SafeCallback(Runtime, options.Name or "ColorPicker", options.Callback, control.Value)
                end
            end

            function control:Set(color, silent)
                if typeof(color) ~= "Color3" then
                    return
                end
                hsv.H, hsv.S, hsv.V = Color3.toHSV(color)
                UpdateCursors()
                ApplyColor(silent)
            end

            function control:Get()
                return control.Value
            end

            UpdateCursors()
            ApplyColor(true)

            local svDragging = false
            local function UpdateSV(pos)
                local abs = cpRefs.SVMap.AbsolutePosition
                local size = cpRefs.SVMap.AbsoluteSize
                if size.X <= 0 or size.Y <= 0 then
                    return
                end
                hsv.S = math.clamp((pos.X - abs.X) / size.X, 0, 1)
                hsv.V = math.clamp(1 - (pos.Y - abs.Y) / size.Y, 0, 1)
                UpdateCursors()
                ApplyColor(false)
            end

            local hueDragging = false
            local function UpdateHue(x)
                local abs = cpRefs.HueBar.AbsolutePosition.X
                local size = cpRefs.HueBar.AbsoluteSize.X
                if size <= 0 then
                    return
                end
                hsv.H = math.clamp((x - abs) / size, 0, 1)
                UpdateCursors()
                ApplyColor(false)
            end

            Track(Runtime, cpRefs.SVHit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    svDragging = true
                    UpdateSV(input.Position)
                end
            end))

            Track(Runtime, cpRefs.SVHit.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    svDragging = false
                end
            end))

            Track(Runtime, cpRefs.HueHit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    hueDragging = true
                    UpdateHue(input.Position.X)
                end
            end))

            Track(Runtime, cpRefs.HueHit.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    hueDragging = false
                end
            end))

            Track(Runtime, UserInputService.InputChanged:Connect(function(input)
                if not Runtime.Alive then
                    return
                end
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if svDragging then
                        UpdateSV(input.Position)
                    elseif hueDragging then
                        UpdateHue(input.Position.X)
                    end
                end
            end))

            Track(Runtime, cpRefs.Header.Activated:Connect(function()
                PlayClick(ui)
                cpRefs.Panel.Visible = not cpRefs.Panel.Visible
            end))

            return control
        end

        function Section:CreateKeybind(options)
            options = type(options) == "table" and options or {Name = tostring(options)}
            local kbRefs = {}
            kbRefs.Container = Instance.new("Frame")
            kbRefs.Container.Size = UDim2.new(1, 0, 0, 36)
            kbRefs.Container.BackgroundColor3 = theme.SurfaceHover
            kbRefs.Container.BorderSizePixel = 0
            kbRefs.Container.ZIndex = 16
            kbRefs.Container.Parent = sectionRefs.Card
            NewCorner(kbRefs.Container, 7)

            kbRefs.Label = Instance.new("TextLabel")
            kbRefs.Label.Size = UDim2.new(1, -90, 1, 0)
            kbRefs.Label.Position = UDim2.fromOffset(12, 0)
            kbRefs.Label.BackgroundTransparency = 1
            kbRefs.Label.Text = options.Name or options.Title or "Keybind"
            kbRefs.Label.TextColor3 = theme.Text
            kbRefs.Label.Font = Enum.Font.GothamMedium
            kbRefs.Label.TextSize = 10
            kbRefs.Label.TextXAlignment = Enum.TextXAlignment.Left
            kbRefs.Label.TextTruncate = Enum.TextTruncate.AtEnd
            kbRefs.Label.ZIndex = 17
            kbRefs.Label.Parent = kbRefs.Container

            kbRefs.Button = Instance.new("TextButton")
            kbRefs.Button.Size = UDim2.fromOffset(76, 24)
            kbRefs.Button.Position = UDim2.new(1, -86, 0.5, -12)
            kbRefs.Button.BackgroundColor3 = theme.Surface
            kbRefs.Button.BorderSizePixel = 0
            kbRefs.Button.Text = ""
            kbRefs.Button.AutoButtonColor = false
            kbRefs.Button.ZIndex = 17
            kbRefs.Button.Parent = kbRefs.Container
            NewCorner(kbRefs.Button, 6)
            kbRefs.ButtonStroke = NewStroke(kbRefs.Button, options.Color or options.Accent or theme.Cyan, 0.5, 1)

            kbRefs.ValueLabel = Instance.new("TextLabel")
            kbRefs.ValueLabel.Size = UDim2.fromScale(1, 1)
            kbRefs.ValueLabel.BackgroundTransparency = 1
            kbRefs.ValueLabel.Font = Enum.Font.GothamBold
            kbRefs.ValueLabel.TextSize = 9
            kbRefs.ValueLabel.TextColor3 = theme.Text
            kbRefs.ValueLabel.TextTruncate = Enum.TextTruncate.AtEnd
            kbRefs.ValueLabel.ZIndex = 18
            kbRefs.ValueLabel.Parent = kbRefs.Button

            local control = {Refs = kbRefs, Value = options.Default, Listening = false}

            local function KeyName(key)
                if not key then
                    return "None"
                end
                return key.Name or tostring(key)
            end

            local function Render()
                kbRefs.ValueLabel.Text = control.Listening and "..." or KeyName(control.Value)
            end

            function control:Set(key, silent)
                control.Value = key
                Render()
                if not silent then
                    SafeCallback(Runtime, options.Name or "Keybind", options.Callback, control.Value)
                end
            end

            function control:Get()
                return control.Value
            end

            Render()

            Track(Runtime, kbRefs.Button.Activated:Connect(function()
                if control.Listening then
                    return
                end
                PlayClick(ui)
                control.Listening = true
                Render()
                Tween(Runtime, kbRefs.ButtonStroke, theme.TweenFast, {Transparency = 0.05})
            end))

            Track(Runtime, UserInputService.InputBegan:Connect(function(input)
                if not Runtime.Alive or not control.Listening then
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then
                    return
                end
                control.Listening = false
                Tween(Runtime, kbRefs.ButtonStroke, theme.TweenFast, {Transparency = 0.5})
                if input.KeyCode == Enum.KeyCode.Escape then
                    Render()
                    return
                end
                control:Set(input.KeyCode)
            end))

            if options.OnPress and options.Default ~= nil or options.OnPress then
                Track(Runtime, UserInputService.InputBegan:Connect(function(input, processed)
                    if not Runtime.Alive or control.Listening or processed then
                        return
                    end
                    if control.Value and input.KeyCode == control.Value then
                        SafeCallback(Runtime, (options.Name or "Keybind") .. "Press", options.OnPress)
                    end
                end))
            end

            return control
        end

        function Section:CreateDivider(options)
            options = type(options) == "table" and options or {}
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, options.Height or 9)
            holder.BackgroundTransparency = 1
            holder.ZIndex = 15
            holder.Parent = sectionRefs.Card

            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.AnchorPoint = Vector2.new(0, 0.5)
            line.Position = UDim2.new(0, 0, 0.5, 0)
            line.BackgroundColor3 = options.Color or theme.SurfaceActive
            line.BackgroundTransparency = options.Transparency or 0.25
            line.BorderSizePixel = 0
            line.ZIndex = 16
            line.Parent = holder
            return {Holder = holder, Line = line}
        end

        return Section
    end

    Track(Runtime, refs.Button.MouseEnter:Connect(function()
        if UserInputService.MouseEnabled and state.CurrentTab ~= Tab then
            Tween(Runtime, refs.Button, theme.TweenFast, {BackgroundTransparency = 0.45})
        end
    end))

    Track(Runtime, refs.Button.MouseLeave:Connect(function()
        if UserInputService.MouseEnabled and state.CurrentTab ~= Tab then
            Tween(Runtime, refs.Button, theme.TweenFast, {BackgroundTransparency = 0.70})
        end
    end))

    Track(Runtime, refs.Button.Activated:Connect(function()
        PlayClick(ui)
        window:SelectTab(Tab)
    end))

    return Tab
end

function NeyyUI:CreateWindow(config)
    config = type(config) == "table" and config or {}

    local theme = ShallowCopy(DEFAULT_THEME)
    if type(config.Theme) == "table" then
        for key, value in pairs(config.Theme) do
            theme[key] = value
        end
    end

    theme.WindowWidth = tonumber(config.Width) or theme.WindowWidth
    theme.WindowHeight = tonumber(config.Height) or theme.WindowHeight
    theme.BaseScale = tonumber(config.Scale) or theme.BaseScale

    local runtimeKey = config.RuntimeKey or DEFAULT_RUNTIME_KEY
    local Runtime = BuildRuntime(runtimeKey)
    local ui = BuildScreen(Runtime, config, theme)
    local state = {
        Tabs = {},
        CurrentTab = nil,
        Minimized = false,
        TransitionBusy = false,
        ToastToken = 0,
    }

    BuildTopBar(Runtime, ui, config, theme)
    BuildFloatingPill(ui, config, theme)
    BuildBody(ui, theme)
    BuildCredit(ui, theme)
    BuildToast(ui, theme)
    BuildBlur(Runtime, config, theme)
    BuildEffects(Runtime, ui, theme, config)
    BindResponsiveScale(Runtime, ui, theme, config)

    EnableDrag(Runtime, ui.TopBar, ui.Main, function()
        return ui.ResponsiveScale.Scale
    end)
    EnableDrag(Runtime, ui.PillDragSurface, ui.FloatingPill, function()
        return 1
    end)

    local Window = {
        Runtime = Runtime,
        Refs = ui,
        Theme = theme,
        Icons = ICONS,
    }

    function Window:Notify(options)
        if not Runtime.Alive then
            return
        end

        if type(options) ~= "table" then
            options = {Content = tostring(options)}
        end

        state.ToastToken += 1
        local token = state.ToastToken
        local tone = options.Type or options.Tone
        local color = options.Color
        local icon = options.Icon

        if color == nil then
            if tone == "Success" then
                color = theme.Emerald
                icon = icon or ICONS.Check
            elseif tone == "Error" then
                color = theme.Rose
                icon = icon or ICONS.Cross
            elseif tone == "Warning" then
                color = theme.Amber
                icon = icon or ICONS.Bolt
            else
                color = theme.Cyan
                icon = icon or ICONS.Check
            end
        end

        ui.ToastMsg.Text = tostring(options.Content or options.Text or options.Title or "Notification")
        ui.ToastStroke.Color = color
        ui.ToastIcon.ImageColor3 = color
        ui.ToastIcon.Image = ResolveIcon(icon)

        Tween(Runtime, ui.Toast, theme.TweenFast, {Position = UDim2.new(0.5, 0, 1, -12)})
        task.delay(tonumber(options.Duration) or 2.2, function()
            if Runtime.Alive and token == state.ToastToken and ui.Toast.Parent then
                Tween(Runtime, ui.Toast, theme.TweenFast, {Position = UDim2.new(0.5, 0, 1, 50)})
            end
        end)
    end

    function Window:SelectTab(tab)
        if not Runtime.Alive or not tab or state.CurrentTab == tab then
            return
        end

        for _, item in ipairs(state.Tabs) do
            item.Refs.Page.Visible = false
            Tween(Runtime, item.Refs.Button, theme.TweenFast, {
                BackgroundColor3 = theme.Surface,
                BackgroundTransparency = 0.70,
            })
            Tween(Runtime, item.Refs.Icon, theme.TweenFast, {ImageColor3 = theme.Muted})
            item.Refs.Title.TextColor3 = theme.Muted
            item.Refs.Indicator.Visible = false
        end

        state.CurrentTab = tab
        tab.Refs.Page.Position = UDim2.fromOffset(16, 0)
        tab.Refs.Page.Visible = true
        Tween(Runtime, tab.Refs.Page, theme.TweenNormal, {Position = UDim2.fromOffset(0, 0)})
        Tween(Runtime, tab.Refs.Button, theme.TweenNormal, {
            BackgroundColor3 = theme.SurfaceActive,
            BackgroundTransparency = 0.18,
        })
        Tween(Runtime, tab.Refs.Icon, theme.TweenNormal, {ImageColor3 = theme.Cyan})
        tab.Refs.Title.TextColor3 = theme.Text
        tab.Refs.Indicator.Visible = true
    end

    function Window:CreateTab(tabConfig)
        local tab = MakeTab(Runtime, ui, theme, Window, state, tabConfig)
        table.insert(state.Tabs, tab)
        if #state.Tabs == 1 then
            Window:SelectTab(tab)
        end
        return tab
    end

    function Window:SetTitle(text)
        ui.TitleLabel.Text = tostring(text)
        ui.GlitchCyan.Text = ui.TitleLabel.Text
        ui.GlitchPink.Text = ui.TitleLabel.Text
        ui.PillText.Text = ui.TitleLabel.Text
    end

    function Window:SetSubtitle(text)
        ui.SubTitleLabel.Text = tostring(text)
    end

    local function SetBlur(active)
        if Runtime.Blur and Runtime.Blur.Parent then
            Tween(Runtime, Runtime.Blur, theme.TweenNormal, {
                Size = active and (tonumber(config.BlurStrength) or theme.BlurStrength) or 0,
            })
        end
    end

    function Window:Minimize()
        if not Runtime.Alive or state.Minimized or state.TransitionBusy then
            return
        end

        state.TransitionBusy = true
        state.Minimized = true
        SetBlur(false)

        -- Hide the large window immediately. This is deliberate: invisible descendants
        -- cannot steal mobile touch/camera input while the minimized pill is visible.
        ui.Main.Visible = false
        ui.FloatingPill.Visible = true
        ui.FloatingPill.Position = UDim2.new(0.5, 0, 0, -60)
        Tween(Runtime, ui.FloatingPill, theme.TweenSpring, {
            Position = UDim2.new(0.5, 0, 0, 20),
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        task.delay(theme.TweenFast, function()
            if Runtime.Alive then
                state.TransitionBusy = false
            end
        end)
    end

    function Window:Restore()
        if not Runtime.Alive or not state.Minimized or state.TransitionBusy then
            return
        end

        state.TransitionBusy = true
        state.Minimized = false
        ui.FloatingPill.Visible = false
        ui.Main.Visible = true
        SetBlur(true)

        ui.ResponsiveScale.Scale = math.max(theme.MinScale, ui.ResponsiveScale.Scale * 0.96)
        Tween(Runtime, ui.ResponsiveScale, theme.TweenSpring, {
            Scale = math.min(tonumber(config.Scale) or theme.BaseScale, ui.ResponsiveScale.Scale / 0.96),
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        task.delay(theme.TweenFast, function()
            if Runtime.Alive then
                state.TransitionBusy = false
            end
        end)
    end

    function Window:Destroy()
        Runtime.Cleanup("window_destroy")
    end

    function Window:IsMinimized()
        return state.Minimized
    end

    ui.MinimizeButton = MakeHeaderButton(Runtime, ui, theme, "Minimize", -78, function()
        Window:Minimize()
    end)

    ui.CloseButton = MakeHeaderButton(Runtime, ui, theme, "Cross", -42, function()
        SafeCallback(Runtime, "Close", config.OnClose)
        Window:Destroy()
    end)

    Track(Runtime, ui.PillExpand.Activated:Connect(function()
        PlayClick(ui)
        Window:Restore()
    end))

    Track(Runtime, ui.ScreenGui.Destroying:Connect(function()
        Runtime.Cleanup("gui_destroying")
    end))

    NeyyUI._LastWindow = Window

    if config.NotifyOnLoad ~= false then
        task.defer(function()
            if Runtime.Alive then
                Window:Notify({
                    Content = config.LoadMessage or "NeyyUI loaded",
                    Type = "Success",
                    Duration = 1.8,
                })
            end
        end)
    end

    return Window
end

function NeyyUI:Notify(options)
    if NeyyUI._LastWindow and NeyyUI._LastWindow.Runtime and NeyyUI._LastWindow.Runtime.Alive then
        return NeyyUI._LastWindow:Notify(options)
    end
end

function NeyyUI:Destroy()
    if NeyyUI._LastWindow then
        pcall(function()
            NeyyUI._LastWindow:Destroy()
        end)
        NeyyUI._LastWindow = nil
    end
end

return NeyyUI
