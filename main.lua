RAGNAROK_VERSION = "3.2.0-EXECUTOR"
RAGNAROK_ALIVE = true
RAGNAROK_START = os.clock()
if type(getgenv) == "function" then
    EXECUTOR_ENV = getgenv()
    if type(EXECUTOR_ENV.RagnarokShutdown) == "function" then
        pcall(EXECUTOR_ENV.RagnarokShutdown)
    end
    EXECUTOR_ENV.RagnarokVersion = RAGNAROK_VERSION
end
RAGNAROK_ALIVE = true
UIS = game:GetService("UserInputService")
HttpService = game:GetService("HttpService")
Players = game:GetService("Players")
CoreGui = game:GetService("CoreGui")
RunService = game:GetService("RunService")
TweenService = game:GetService("TweenService")
GuiService = game:GetService("GuiService")
ContextActionService = game:GetService("ContextActionService")
Camera = workspace.CurrentCamera
LocalPlayer = Players.LocalPlayer

function Protect(Instance)
    if type(gethui) == "function" then
        local success = pcall(function()
            Instance.Parent = gethui()
        end)
        if success then
            return true
        end
    end
    if syn and type(syn.protect_gui) == "function" then
        pcall(function()
            syn.protect_gui(Instance)
        end)
    end
    local success = pcall(function()
        Instance.Parent = CoreGui
    end)
    return success
end

for _, v in ipairs(CoreGui:GetChildren()) do
    if v.Name == "RagnarokHub" or v.Name == "RagnarokNotify" then
        v:Destroy()
    end
end

Config = {
    HitboxScale = 6,
    HitboxEnabled = true,
    DirectionalJump = true,
    AirMoveEnabled = false,
    AirMoveSpeed = 15,
    AntiAFK = false,
    StretchedRes = false,
    IconPos = {1, -100, 1, -100},
    Binds = {},
    HitboxTransparency = 0.7,
    HitboxColor = "Cyan",
    HitboxRefreshRate = 0.08,
    NormalFOV = 70,
    StretchedFOV = 110,
    AutoRotateEnabled = false,
    ShowNotifications = true,
    ToggleKey = "RightShift",
    ShutdownKey = "None",
    EnableStatChangers = false,
    DiveSpeed = 1,
    SpikePower = 1,
    TiltPower = 1,
    SpeedMult = 1,
    SetPower = 1,
    ServePower = 1,
    JumpPowerMult = 1,
    BumpPower = 1,
    BlockPower = 1,
}

function SafeExecutorCall(callback, ...)
    if type(callback) ~= "function" then
        return false, nil
    end
    return pcall(callback, ...)
end
function SaveConfig()
    if type(writefile) ~= "function" then
        return false
    end
    local success = pcall(function()
        writefile("RagnarokConfig.json", HttpService:JSONEncode(Config))
    end)
    return success
end
function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" or not isfile("RagnarokConfig.json") then
        return false
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile("RagnarokConfig.json"))
    end)
    if not success or type(data) ~= "table" then
        return false
    end
    for k, v in pairs(data) do
        if Config[k] ~= nil and type(v) == type(Config[k]) then
            Config[k] = v
        end
    end
    return true
end


LoadConfig()
StatAttrNames = {
    DiveSpeed = "GameDiveSpeedMultiplier",
    SpikePower = "GameSpikePowerMultiplier",
    TiltPower = "GameTiltPowerMultiplier",
    SpeedMult = "GameSpeedMultiplier",
    SetPower = "GameSetPowerMultiplier",
    ServePower = "GameServePowerMultiplier",
    JumpPowerMult = "GameJumpPowerMultiplier",
    BumpPower = "GameBumpPowerMultiplier",
    BlockPower = "GameBlockPowerMultiplier",
}
StatConnections = {}
StatsBaseline = {
    CapturedCharacter = nil,
    WalkSpeed = nil,
    JumpPower = nil,
    JumpHeight = nil,
}
function DisconnectStatConnections()
    for _, connection in pairs(StatConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    StatConnections = {}
end
function CaptureStatsBaseline()
    local character = LocalPlayer and LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    if StatsBaseline.CapturedCharacter ~= character then
        StatsBaseline.CapturedCharacter = character
        StatsBaseline.WalkSpeed = humanoid.WalkSpeed
        StatsBaseline.JumpPower = humanoid.JumpPower
        StatsBaseline.JumpHeight = humanoid.JumpHeight
    end
end
function ApplyStatValue(configKey, value)
    if not Config.EnableStatChangers then
        return false
    end
    local attribute = StatAttrNames[configKey]
    local numericValue = tonumber(value)
    if not attribute or not numericValue then
        return false
    end
    pcall(function()
        LocalPlayer:SetAttribute(attribute, numericValue)
    end)
    local character = LocalPlayer.Character
    if character then
        pcall(function()
            character:SetAttribute(attribute, numericValue)
        end)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function()
                humanoid:SetAttribute(attribute, numericValue)
            end)
        end
    end
    return true
end
function ApplyAllStats()
    CaptureStatsBaseline()
    if not Config.EnableStatChangers then
        ResetStats()
        return false
    end
    for configKey, attribute in pairs(StatAttrNames) do
        local value = tonumber(Config[configKey]) or 1
        if value ~= 1 then
            ApplyStatValue(configKey, value)
        end
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if Config.JumpPowerMult and Config.JumpPowerMult ~= 1 then
            pcall(function()
                humanoid.UseJumpPower = true
                humanoid.JumpPower = StatsBaseline.JumpPower * Config.JumpPowerMult
                humanoid.JumpHeight = StatsBaseline.JumpHeight * Config.JumpPowerMult
            end)
        end
        if Config.SpeedMult and Config.SpeedMult ~= 1 then
            pcall(function()
                humanoid.WalkSpeed = StatsBaseline.WalkSpeed * Config.SpeedMult
            end)
        end
    end
    return true
end
function ResetStats()
    DisconnectStatConnections()
    for _, attribute in pairs(StatAttrNames) do
        pcall(function()
            LocalPlayer:SetAttribute(attribute, 1)
        end)
        local character = LocalPlayer.Character
        if character then
            pcall(function()
                character:SetAttribute(attribute, 1)
            end)
        end
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = StatsBaseline.WalkSpeed or 16
            humanoid.JumpPower = StatsBaseline.JumpPower or 50
            humanoid.JumpHeight = StatsBaseline.JumpHeight or 7.2
        end)
    end
    return true
end
function HookStatEnforcement()
    DisconnectStatConnections()
    if not Config.EnableStatChangers then
        return false
    end
    for configKey, attribute in pairs(StatAttrNames) do
        local expected = tonumber(Config[configKey]) or 1
        if expected ~= 1 then
            local connection = LocalPlayer:GetAttributeChangedSignal(attribute):Connect(function()
                if not RAGNAROK_ALIVE or not Config.EnableStatChangers then
                    return
                end
                local current = LocalPlayer:GetAttribute(attribute)
                if current ~= expected then
                    pcall(function()
                        LocalPlayer:SetAttribute(attribute, expected)
                    end)
                end
            end)
            table.insert(StatConnections, connection)
        end
    end
    return true
end
function SetStatsEnabled(enabled)
    Config.EnableStatChangers = enabled == true
    if Config.EnableStatChangers then
        ApplyAllStats()
        HookStatEnforcement()
    else
        ResetStats()
    end
    SaveConfig()
    return Config.EnableStatChangers
end
ControlRegistry = {}
InputConnections = {}

NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "RagnarokNotify"
NotifyGui.DisplayOrder = 100
Protect(NotifyGui)

NotifyList = Instance.new("Frame")
NotifyList.Size = UDim2.new(0, 280, 1, 0)
NotifyList.Position = UDim2.new(0, 20, 0, 20)
NotifyList.BackgroundTransparency = 1
NotifyList.Parent = NotifyGui

notifyQueue = {}
activeNotifs = 0

function ProcessQueue()
    if not RAGNAROK_ALIVE or not NotifyGui.Parent then
        notifyQueue = {}
        return
    end
    if #notifyQueue > 0 and activeNotifs < 5 then
        local data = table.remove(notifyQueue, 1)
        activeNotifs = activeNotifs + 1

        local nFrame = Instance.new("Frame")
        nFrame.Size = UDim2.new(1, 0, 0, 45)
        nFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
        nFrame.Position = UDim2.new(-1.2, 0, 0, (activeNotifs - 1) * 50)
        nFrame.Parent = NotifyList
        Instance.new("UICorner", nFrame).CornerRadius = UDim.new(0, 6)
        local ns = Instance.new("UIStroke", nFrame)
        ns.Color = Color3.fromRGB(45, 45, 50)
        ns.Thickness = 1.5

        local nText = Instance.new("TextLabel")
        nText.Size = UDim2.new(1, -20, 1, 0)
        nText.Position = UDim2.new(0, 10, 0, 0)
        nText.BackgroundTransparency = 1
        nText.Font = Enum.Font.GothamMedium
        nText.RichText = true
        nText.Text = data.msg
        nText.TextColor3 = Color3.fromRGB(230, 230, 230)
        nText.TextSize = 14
        nText.TextXAlignment = Enum.TextXAlignment.Left
        nText.Parent = nFrame

        TweenService:Create(nFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, nFrame.Position.Y.Offset)}):Play()

        task.delay(2.5, function()
            TweenService:Create(nFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(-1.2, 0, 0, nFrame.Position.Y.Offset)}):Play()
            task.wait(0.4)
            nFrame:Destroy()
            activeNotifs = activeNotifs - 1
            ProcessQueue()
        end)
    end
end

function Notify(name, state)
    if Config and Config.ShowNotifications == false then
        return
    end
    local statusText = state and '<font color="#00FF7F">Activated</font>' or '<font color="#FF4500">Deactivated</font>'
    table.insert(notifyQueue, {msg = name .. ": " .. statusText})
    ProcessQueue()
end

Ragnarok = Instance.new("ScreenGui")
Ragnarok.Name = "RagnarokHub"
Ragnarok.ResetOnSpawn = false
Ragnarok.DisplayOrder = 10
Ragnarok.IgnoreGuiInset = true
Ragnarok.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Protect(Ragnarok)

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = Ragnarok
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Size = UDim2.new(0, 400, 0, 520)
Main.AutomaticSize = Enum.AutomaticSize.None
Main.Visible = false
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(0, 191, 255)
MainStroke.Thickness = 2
MainStroke.Transparency = 0.6

Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "RAGNAROK HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 191, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 191, 255))
})
TitleGradient.Parent = Title

task.spawn(function()
    while RAGNAROK_ALIVE and TitleGradient.Parent do
        local t = TweenService:Create(TitleGradient, TweenInfo.new(3, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
        t:Play()
        t.Completed:Wait()
        TitleGradient.Offset = Vector2.new(-1, 0)
    end
end)

function CreateHeaderBtn(text, xOffset, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 30, 0, 30)
    b.Position = UDim2.new(1, xOffset, 0.5, -15)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 16
    b.Parent = Header
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.Activated:Connect(callback)
    return b
end

function GetVisualColor()
    if Config.HitboxColor == "Violet" then
        return Color3.fromRGB(167, 139, 250)
    end
    if Config.HitboxColor == "Green" then
        return Color3.fromRGB(52, 211, 153)
    end
    if Config.HitboxColor == "Amber" then
        return Color3.fromRGB(251, 191, 36)
    end
    return Color3.fromRGB(0, 191, 255)
end
function ClearHitboxes()
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local visual = model:FindFirstChild("RagnarokHitbox")
            if visual then
                visual:Destroy()
            end
            local legacy = model:FindFirstChild("Ball.001")
            if legacy and legacy:GetAttribute("RagnarokOwned") then
                legacy:Destroy()
            end
        end
    end
end

CloseBtn = CreateHeaderBtn("X", -40, function()
    local Prompt = Ragnarok:FindFirstChild("TerminationMenu")
    if Prompt then Prompt.Visible = true end
end)

MinBtn = CreateHeaderBtn("M", -80, function()
    Main.Visible = false
    Ragnarok:FindFirstChild("Icon").Visible = true
end)

TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 50)
TabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
TabContainer.Parent = Main

TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Parent = TabContainer

Pages = Instance.new("Frame")
Pages.Size = UDim2.new(1, 0, 1, -85)
Pages.Position = UDim2.new(0, 0, 0, 85)
Pages.BackgroundTransparency = 1
Pages.ClipsDescendants = true
Pages.Parent = Main

PageFrames = {}
function CreatePage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.Visible = false
    Page.Active = true
    Page.ScrollingEnabled = true
    Page.ScrollingDirection = Enum.ScrollingDirection.Y
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Color3.fromRGB(0, 191, 255)
    Page.ScrollBarImageTransparency = 0.2
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Parent = Pages

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Page

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingLeft = UDim.new(0, 15)
    PagePadding.PaddingRight = UDim.new(0, 7)
    PagePadding.PaddingTop = UDim.new(0, 2)
    PagePadding.PaddingBottom = UDim.new(0, 20)
    PagePadding.Parent = Page

    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0.25, 0, 1, 0)
    TabBtn.BackgroundTransparency = 1
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.Text = name:upper()
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.TextSize = 12
    TabBtn.TextScaled = true
    local TabConstraint = Instance.new("UITextSizeConstraint")
    TabConstraint.MinTextSize = 8
    TabConstraint.MaxTextSize = 13
    TabConstraint.Parent = TabBtn
    TabBtn.Parent = TabContainer

    TabBtn.Activated:Connect(function()
        for _, p in pairs(PageFrames) do p.Page.Visible = false p.Btn.TextColor3 = Color3.fromRGB(150, 150, 150) end
        Page.Visible = true
        TabBtn.TextColor3 = Color3.fromRGB(0, 191, 255)
    end)

    PageFrames[name] = {Page = Page, Btn = TabBtn}
    return Page
end

MainPage = CreatePage("Main")
MiscPage = CreatePage("Misc")
PageFrames["Main"].Page.Visible = true
PageFrames["Main"].Btn.TextColor3 = Color3.fromRGB(0, 191, 255)
LayoutState = {
    Width = 0,
    Height = 0,
}
function GetScreenResolution()
    if GuiService and type(GuiService.GetScreenResolution) == "function" then
        local success, resolution = pcall(function()
            return GuiService:GetScreenResolution()
        end)
        if success and typeof(resolution) == "Vector2" then
            return resolution
        end
    end
    local fallbackCamera = workspace.CurrentCamera
    return fallbackCamera and fallbackCamera.ViewportSize or Vector2.new(800, 600)
end
function ApplyResponsiveLayout()
    local viewport = GetScreenResolution()
    local width = math.clamp(viewport.X - 12, 240, 400)
    local height = math.clamp(viewport.Y - 48, 220, 520)
    if LayoutState.Width == width and LayoutState.Height == height then
        return
    end
    LayoutState.Width = width
    LayoutState.Height = height
    Main.Size = UDim2.new(0, width, 0, height)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
end
function GetActiveScrollPage()
    for _, pageData in pairs(PageFrames) do
        if pageData.Page.Visible then
            return pageData.Page
        end
    end
    return nil
end
function ScrollActivePage(delta)
    local page = GetActiveScrollPage()
    if not page then
        return
    end
    local maximum = math.max(0, page.AbsoluteCanvasSize.Y - page.AbsoluteWindowSize.Y)
    page.CanvasPosition = Vector2.new(0, math.clamp(page.CanvasPosition.Y + delta, 0, maximum))
end
ApplyResponsiveLayout()
function IsPointInsideGui(guiObject, position)
    if not guiObject or not guiObject.Visible or not guiObject.Parent then
        return false
    end
    local absolutePosition = guiObject.AbsolutePosition
    local absoluteSize = guiObject.AbsoluteSize
    return position.X >= absolutePosition.X and position.X <= absolutePosition.X + absoluteSize.X and position.Y >= absolutePosition.Y and position.Y <= absolutePosition.Y + absoluteSize.Y
end
function HandleWheelAction(_, inputState, inputObject)
    if inputState ~= Enum.UserInputState.Begin or not RAGNAROK_ALIVE then
        return Enum.ContextActionResult.Pass
    end
    if not Main.Visible or not IsPointInsideGui(Main, inputObject.Position) then
        return Enum.ContextActionResult.Pass
    end
    ScrollActivePage(-inputObject.Position.Z * 54)
    return Enum.ContextActionResult.Sink
end
if ContextActionService and type(ContextActionService.BindActionAtPriority) == "function" then
    ContextActionService:BindActionAtPriority("RagnarokHubWheelGuard", HandleWheelAction, false, 3000, Enum.UserInputType.MouseWheel)
end
function CreateCategory(parent, name, iconId)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -30, 0, 35)
    f.BackgroundTransparency = 1
    f.Parent = parent

    local i = Instance.new("ImageLabel")
    i.Size = UDim2.new(0, 20, 0, 20)
    i.Position = UDim2.new(0, 5, 0.5, -10)
    i.BackgroundTransparency = 1
    i.Image = "rbxassetid://" .. iconId
    i.ImageColor3 = Color3.fromRGB(0, 191, 255)
    i.Parent = f

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -45, 1, 0)
    t.Position = UDim2.new(0, 35, 0, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.Text = name:upper()
    t.TextColor3 = Color3.fromRGB(130, 130, 140)
    t.TextSize = 13
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = f

    local l = Instance.new("Frame")
    l.Size = UDim2.new(1, -t.TextBounds.X - 55, 0, 1)
    l.Position = UDim2.new(0, t.TextBounds.X + 50, 0.5, 0)
    l.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    l.BorderSizePixel = 0
    l.Parent = f
end

Icon = Instance.new("TextButton")
Icon.Name = "Icon"
Icon.Parent = Ragnarok
Icon.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Icon.Position = UDim2.new(Config.IconPos[1], Config.IconPos[2], Config.IconPos[3], Config.IconPos[4])
Icon.Size = UDim2.new(0, 50, 0, 50)
Icon.Font = Enum.Font.GothamBlack
Icon.Text = "R"
Icon.TextColor3 = Color3.fromRGB(0, 191, 255)
Icon.TextSize = 24
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1, 0)
is = Instance.new("UIStroke", Icon)
is.Color = Color3.fromRGB(0, 191, 255)
is.Thickness = 2
is.Transparency = 0.4

function MakeDraggable(obj, target, isIcon)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if isIcon then
                        Config.IconPos = {target.Position.X.Scale, target.Position.X.Offset, target.Position.Y.Scale, target.Position.Y.Offset}
                        SaveConfig()
                    end
                end
            end)
        end
    end)
    obj.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local viewport = GetScreenResolution()
            local width = target.AbsoluteSize.X
            local height = target.AbsoluteSize.Y
            local nextX = math.clamp(startPos.X.Offset + delta.X, -viewport.X / 2 + width / 2, viewport.X / 2 - width / 2)
            local nextY = math.clamp(startPos.Y.Offset + delta.Y, -viewport.Y / 2 + height / 2, viewport.Y / 2 - height / 2)
            target.Position = UDim2.new(0.5, nextX, 0.5, nextY)
        end
    end)
end

MakeDraggable(Header, Main, false)
MakeDraggable(Icon, Icon, true)

Icon.Activated:Connect(function()
    Main.Visible = true
    Main.BackgroundTransparency = 1
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
    Icon.Visible = false
end)

TerminationMenu = Instance.new("Frame")
TerminationMenu.Name = "TerminationMenu"
TerminationMenu.Size = UDim2.new(0, 340, 0, 300)
TerminationMenu.Position = UDim2.new(0.5, -170, 0.5, -150)
TerminationMenu.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
TerminationMenu.Visible = false
TerminationMenu.ZIndex = 5000
TerminationMenu.Parent = Ragnarok
Instance.new("UICorner", TerminationMenu).CornerRadius = UDim.new(0, 12)
ts = Instance.new("UIStroke", TerminationMenu)
ts.Color = Color3.fromRGB(0, 191, 255)
ts.Thickness = 2

THeader = Instance.new("Frame")
THeader.Size = UDim2.new(1, 0, 0, 50)
THeader.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
THeader.Parent = TerminationMenu
THeader.ZIndex = 5001
Instance.new("UICorner", THeader).CornerRadius = UDim.new(0, 12)

TTitle = Instance.new("TextLabel")
TTitle.Size = UDim2.new(1, 0, 1, 0)
TTitle.BackgroundTransparency = 1
TTitle.Font = Enum.Font.GothamBold
TTitle.Text = "SYSTEM TERMINATION"
TTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TTitle.TextSize = 16
TTitle.ZIndex = 5002
TTitle.Parent = THeader

TContent = Instance.new("TextLabel")
TContent.Size = UDim2.new(1, -40, 0, 40)
TContent.Position = UDim2.new(0, 20, 0, 60)
TContent.BackgroundTransparency = 1
TContent.Font = Enum.Font.GothamMedium
TContent.Text = "Select an action to proceed with the script status management."
TContent.TextColor3 = Color3.fromRGB(180, 180, 180)
TContent.TextSize = 12
TContent.TextWrapped = true
TContent.ZIndex = 5001
TContent.Parent = TerminationMenu

function CreateTBtn(text, pos, color, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -40, 0, 42)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.TextColor3 = color
    b.TextSize = 13
    b.ZIndex = 5002
    b.Parent = TerminationMenu
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local bs = Instance.new("UIStroke", b)
    bs.Color = color
    bs.Thickness = 1.5
    bs.Transparency = 0.6
    b.Activated:Connect(callback)
    b.MouseEnter:Connect(function() TweenService:Create(bs, TweenInfo.new(0.2), {Transparency = 0}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(bs, TweenInfo.new(0.2), {Transparency = 0.6}):Play() end)
end

CreateTBtn("SHUTDOWN SCRIPT", UDim2.new(0, 20, 0, 110), Color3.fromRGB(255, 70, 70), function()
    FullShutdown("menu")
end)

CreateTBtn("MINIMIZE TO ICON", UDim2.new(0, 20, 0, 160), Color3.fromRGB(0, 191, 255), function()
    TerminationMenu.Visible = false
    Main.Visible = false
    Icon.Visible = true
end)

CreateTBtn("STEALTH MODE", UDim2.new(0, 20, 0, 210), Color3.fromRGB(200, 200, 200), function()
    FullShutdown("stealth")
end)

TCancel = Instance.new("TextButton")
TCancel.Size = UDim2.new(0, 100, 0, 30)
TCancel.Position = UDim2.new(0.5, -50, 1, -35)
TCancel.BackgroundTransparency = 1
TCancel.Font = Enum.Font.GothamBold
TCancel.Text = "DISMISS"
TCancel.TextColor3 = Color3.fromRGB(100, 100, 100)
TCancel.TextSize = 12
TCancel.ZIndex = 5002
TCancel.Parent = TerminationMenu
TCancel.Activated:Connect(function() TerminationMenu.Visible = false end)

function CreateToggle(parent, name, configKey, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -30, 0, 42)
    f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -130, 1, 0)
    t.Position = UDim2.new(0, 15, 0, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamMedium
    t.Text = name
    t.TextColor3 = Color3.fromRGB(220, 220, 220)
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 36, 0, 18)
    b.Position = UDim2.new(1, -50, 0.5, -9)
    b.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 191, 255) or Color3.fromRGB(40, 40, 45)
    b.Text = ""
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 14, 0, 14)
    ind.Position = Config[configKey] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    ind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ind.Parent = b
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

    local bind = Instance.new("TextButton")
    bind.Size = UDim2.new(0, 60, 0, 22)
    bind.Position = UDim2.new(1, -115, 0.5, -11)
    bind.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    bind.Font = Enum.Font.GothamBold
    bind.Text = Config.Binds[configKey] or "NONE"
    bind.TextColor3 = Color3.fromRGB(0, 191, 255)
    bind.TextSize = 11
    bind.Parent = f
    Instance.new("UICorner", bind).CornerRadius = UDim.new(0, 4)

    local function Toggle()
        if not RAGNAROK_ALIVE then
            return
        end
        Config[configKey] = not Config[configKey]
        if configKey == "HitboxEnabled" and not Config[configKey] then ClearHitboxes() end
        if ControlRegistry[configKey] then
            ControlRegistry[configKey]()
        end
        Notify(name, Config[configKey])
        SaveConfig()
        if type(callback) == "function" then
            callback(Config[configKey])
        end
    end
    ControlRegistry[configKey] = function()
        local enabled = Config[configKey] == true
        b.BackgroundColor3 = enabled and Color3.fromRGB(0, 191, 255) or Color3.fromRGB(40, 40, 45)
        ind.Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    end

    b.Activated:Connect(Toggle)

    local binding = false
    bind.Activated:Connect(function()
        binding = true
        bind.Text = "..."
        local connection
        connection = UIS.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard then
                local k = i.KeyCode.Name
                if k == "Backspace" then
                    Config.Binds[configKey] = nil
                    bind.Text = "NONE"
                else
                    Config.Binds[configKey] = k
                    bind.Text = k
                end
                binding = false
                SaveConfig()
                connection:Disconnect()
            end
        end)
    end)

    UIS.InputBegan:Connect(function(i, g)
        if not g and not binding and Config.Binds[configKey] and i.KeyCode.Name == Config.Binds[configKey] then
            Toggle()
        end
    end)
end

function CreateSlider(parent, name, min, max, configKey, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -30, 0, 55)
    f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -80, 0, 25)
    t.Position = UDim2.new(0, 15, 0, 5)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.Text = name
    t.TextColor3 = Color3.fromRGB(220, 220, 220)
    t.TextSize = 13
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = f

    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0, 70, 0, 25)
    v.Position = UDim2.new(1, -85, 0, 5)
    v.BackgroundTransparency = 1
    v.Font = Enum.Font.GothamBold
    v.Text = string.format("%.1f", Config[configKey])
    v.TextColor3 = Color3.fromRGB(0, 191, 255)
    v.TextSize = 13
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -30, 0, 8)
    bar.Position = UDim2.new(0, 15, 0, 38)
    bar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    bar.Parent = f
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Config[configKey] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 191, 255)
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function Update(input)
        local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = tonumber(string.format("%.1f", min + (max - min) * pos))
        fill.Size = UDim2.new(pos, 0, 1, 0)
        v.Text = tostring(val)
        Config[configKey] = val
        SaveConfig()
        if type(callback) == "function" then
            callback(val)
        end
    end

    ControlRegistry[configKey] = function()
        local current = tonumber(Config[configKey]) or min
        local alpha = math.clamp((current - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        v.Text = string.format("%.1f", current)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Update(i)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            Update(i)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

CreateCategory(MainPage, "Game", "7733993211")
CreateToggle(MainPage, "Hitbox Enabled", "HitboxEnabled")
CreateSlider(MainPage, "Hitbox Scale", 1.0, 20.5, "HitboxScale")

CreateCategory(MainPage, "Movement", "7743871002")
CreateToggle(MainPage, "Directional Jump", "DirectionalJump")
CreateToggle(MainPage, "Air Move", "AirMoveEnabled")
CreateSlider(MainPage, "Air Move Speed", 10, 100, "AirMoveSpeed")
CreateToggle(MainPage, "Auto Rotate", "AutoRotateEnabled")

CreateCategory(MiscPage, "Player", "7733715400")
CreateToggle(MiscPage, "Anti AFK", "AntiAFK")

CreateCategory(MiscPage, "Visuals", "7733978098")
CreateToggle(MiscPage, "Stretched Res", "StretchedRes")
CreateToggle(MiscPage, "Notifications", "ShowNotifications")
CreateSlider(MiscPage, "Hitbox Transparency", 0.1, 0.9, "HitboxTransparency")
CreateSlider(MiscPage, "Normal FOV", 50, 120, "NormalFOV")
CreateSlider(MiscPage, "Stretched FOV", 70, 130, "StretchedFOV")

LastHitboxUpdate = 0
function CreateHitboxes(scale)
    local now = os.clock()
    if now - LastHitboxUpdate < math.max(0.03, tonumber(Config.HitboxRefreshRate) or 0.08) then
        return
    end
    LastHitboxUpdate = now
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local reference = nil
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "RagnarokHitbox" then
                    reference = part
                    break
                end
            end
            if reference then
                local visual = model:FindFirstChild("RagnarokHitbox")
                if not visual then
                    visual = Instance.new("Part")
                    visual.Name = "RagnarokHitbox"
                    visual.Shape = Enum.PartType.Ball
                    visual.Anchored = true
                    visual.CanCollide = false
                    visual.CanTouch = false
                    visual.CanQuery = false
                    visual.CastShadow = false
                    visual.Material = Enum.Material.ForceField
                    visual.Parent = model
                end
                visual.Size = Vector3.new(scale, scale, scale)
                visual.CFrame = reference.CFrame
                visual.Transparency = math.clamp(tonumber(Config.HitboxTransparency) or 0.7, 0.1, 0.95)
                visual.Color = GetVisualColor()
            end
        end
    end
end

JumpConnection = UIS.JumpRequest:Connect(function()
    if not RAGNAROK_ALIVE then
        return
    end
    local char = LocalPlayer.Character
    if Config.DirectionalJump and char then
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            task.defer(function()
                task.wait(0.03)
                local dir = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
                if dir.Magnitude > 0 then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dir.Unit)
                    hum.AutoRotate = false
                end
            end)
        end
    end
end)

antiAfkActive = false

function GetCameraSafe()
    Camera = workspace.CurrentCamera or Camera
    return Camera
end
function GetCharacterSafe()
    return LocalPlayer and LocalPlayer.Character or nil
end
function GetHumanoidSafe(character)
    local target = character or GetCharacterSafe()
    if not target then
        return nil
    end
    return target:FindFirstChildOfClass("Humanoid") or target:FindFirstChild("Humanoid")
end
function GetRootSafe(character)
    local target = character or GetCharacterSafe()
    return target and target:FindFirstChild("HumanoidRootPart") or nil
end
function ApplyCameraSettings()
    local camera = GetCameraSafe()
    if camera then
        camera.FieldOfView = Config.StretchedRes and Config.StretchedFOV or Config.NormalFOV
    end
end
function RefreshAllControls()
    for _, refresh in pairs(ControlRegistry) do
        if type(refresh) == "function" then
            pcall(refresh)
        end
    end
    ApplyCameraSettings()
end
function RestoreDefaults()
    local preservedPosition = Config.IconPos
    Config = {
        HitboxScale = 6,
        HitboxEnabled = true,
        DirectionalJump = true,
        AirMoveEnabled = false,
        AirMoveSpeed = 15,
        AntiAFK = false,
        StretchedRes = false,
        IconPos = preservedPosition or {1, -100, 1, -100},
        Binds = {},
        HitboxTransparency = 0.7,
        HitboxColor = "Cyan",
        HitboxRefreshRate = 0.08,
        NormalFOV = 70,
        StretchedFOV = 110,
        AutoRotateEnabled = false,
        ShowNotifications = true,
        ToggleKey = "RightShift",
        ShutdownKey = "None",
        EnableStatChangers = false,
        DiveSpeed = 1,
        SpikePower = 1,
        TiltPower = 1,
        SpeedMult = 1,
        SetPower = 1,
        ServePower = 1,
        JumpPowerMult = 1,
        BumpPower = 1,
        BlockPower = 1,
    }
    ClearHitboxes()
    RefreshAllControls()
    SaveConfig()
end
function FullShutdown(reason)
    if not RAGNAROK_ALIVE then
        return
    end
    if Config.EnableStatChangers then
        ResetStats()
    end
    RAGNAROK_ALIVE = false
    ShutdownReason = reason or "manual"
    ClearHitboxes()
    local camera = GetCameraSafe()
    if camera then
        camera.FieldOfView = Config.NormalFOV or 70
    end
    Config.HitboxEnabled = false
    Config.AntiAFK = false
    Config.AirMoveEnabled = false
    Config.DirectionalJump = false
    local humanoid = GetHumanoidSafe()
    if humanoid then
        humanoid.AutoRotate = true
    end
    if Ragnarok and Ragnarok.Parent then
        Ragnarok:Destroy()
    end
    if NotifyGui and NotifyGui.Parent then
        NotifyGui:Destroy()
    end
    if JumpConnection then
        pcall(function()
            JumpConnection:Disconnect()
        end)
        JumpConnection = nil
    end
    if ContextActionService and type(ContextActionService.UnbindAction) == "function" then
        pcall(function()
            ContextActionService:UnbindAction("RagnarokHubWheelGuard")
        end)
    end
    DisconnectRuntimeConnections()
    if type(getgenv) == "function" then
        local environment = getgenv()
        if environment.RagnarokShutdown then
            environment.RagnarokShutdown = nil
        end
    end
end
function ToggleMain()
    if not RAGNAROK_ALIVE then
        return
    end
    Main.Visible = not Main.Visible
    Icon.Visible = not Main.Visible
    if Main.Visible then
        Main.BackgroundTransparency = 1
        TweenService:Create(Main, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
    end
end
function SetBinding(configKey, displayButton)
    displayButton.Text = "..."
    local bindingConnection
    bindingConnection = UIS.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        local keyName = input.KeyCode.Name
        if keyName == "Backspace" or keyName == "Escape" then
            Config[configKey] = "None"
        else
            Config[configKey] = keyName
        end
        displayButton.Text = tostring(Config[configKey] or "None")
        SaveConfig()
        if bindingConnection then
            bindingConnection:Disconnect()
        end
    end)
end
function CreateActionButton(parent, text, color, callback, order)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -30, 0, 42)
    button.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = color
    button.TextSize = 12
    button.LayoutOrder = order or 1
    button.Parent = parent
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", button)
    stroke.Color = color
    stroke.Thickness = 1.2
    stroke.Transparency = 0.55
    button.Activated:Connect(callback)
    button.MouseEnter:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.16), {Transparency = 0}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.16), {Transparency = 0.55}):Play()
    end)
    return button
end
function CreateInfoRow(parent, label, value, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    row.LayoutOrder = order or 1
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local left = Instance.new("TextLabel")
    left.Size = UDim2.new(0.58, 0, 1, 0)
    left.Position = UDim2.new(0, 14, 0, 0)
    left.BackgroundTransparency = 1
    left.Font = Enum.Font.GothamMedium
    left.Text = label
    left.TextColor3 = Color3.fromRGB(180, 180, 190)
    left.TextSize = 12
    left.TextXAlignment = Enum.TextXAlignment.Left
    left.Parent = row
    local right = Instance.new("TextLabel")
    right.Size = UDim2.new(0.38, -14, 1, 0)
    right.Position = UDim2.new(0.62, 0, 0, 0)
    right.BackgroundTransparency = 1
    right.Font = Enum.Font.GothamBold
    right.Text = tostring(value)
    right.TextColor3 = Color3.fromRGB(0, 191, 255)
    right.TextSize = 11
    right.TextXAlignment = Enum.TextXAlignment.Right
    right.Parent = row
    return row, right
end
function CreateKeybindRow(parent, label, configKey, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    row.LayoutOrder = order or 1
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -120, 1, 0)
    text.Position = UDim2.new(0, 14, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamMedium
    text.Text = label
    text.TextColor3 = Color3.fromRGB(220, 220, 220)
    text.TextSize = 12
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = row
    local key = Instance.new("TextButton")
    key.Size = UDim2.new(0, 82, 0, 26)
    key.Position = UDim2.new(1, -96, 0.5, -13)
    key.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    key.Font = Enum.Font.GothamBold
    key.Text = tostring(Config[configKey] or "None")
    key.TextColor3 = Color3.fromRGB(0, 191, 255)
    key.TextSize = 10
    key.Parent = row
    Instance.new("UICorner", key).CornerRadius = UDim.new(0, 5)
    key.Activated:Connect(function()
        SetBinding(configKey, key)
    end)
    return row
end
function CreateStatusHeader(parent, title, subtitle, order)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -30, 0, 42)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = order or 1
    holder.Parent = parent
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title:upper()
    titleLabel.TextColor3 = Color3.fromRGB(0, 191, 255)
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = holder
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, 0, 0, 17)
    subtitleLabel.Position = UDim2.new(0, 0, 0, 22)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.GothamMedium
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
    subtitleLabel.TextSize = 10
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.Parent = holder
    return holder
end
function CreateOptionButton(parent, label, options, configKey, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -30, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    row.LayoutOrder = order or 1
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -125, 1, 0)
    text.Position = UDim2.new(0, 14, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamMedium
    text.Text = label
    text.TextColor3 = Color3.fromRGB(220, 220, 220)
    text.TextSize = 12
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = row
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 90, 0, 26)
    button.Position = UDim2.new(1, -104, 0.5, -13)
    button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.fromRGB(0, 191, 255)
    button.TextSize = 10
    button.Text = tostring(Config[configKey])
    button.Parent = row
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)
    local index = 1
    for i, option in ipairs(options) do
        if option == Config[configKey] then
            index = i
            break
        end
    end
    button.Activated:Connect(function()
        index = index % #options + 1
        Config[configKey] = options[index]
        button.Text = tostring(Config[configKey])
        SaveConfig()
        if configKey == "HitboxColor" then
            ClearHitboxes()
        end
    end)
    return row
end
function CountBallModels()
    local count = 0
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            count = count + 1
        end
    end
    return count
end
function CountVisuals()
    local count = 0
    for _, model in ipairs(workspace:GetChildren()) do
        local visual = model:IsA("Model") and model:FindFirstChild("RagnarokHitbox")
        if visual then
            count = count + 1
        end
    end
    return count
end
function GetRuntimeSnapshot()
    return {
        Version = RAGNAROK_VERSION,
        Alive = RAGNAROK_ALIVE,
        Uptime = os.clock() - RAGNAROK_START,
        BallModels = CountBallModels(),
        Visuals = CountVisuals(),
        MainVisible = Main and Main.Visible or false,
        HitboxEnabled = Config.HitboxEnabled,
        AirMoveEnabled = Config.AirMoveEnabled,
        AntiAFK = Config.AntiAFK,
        StatChangers = Config.EnableStatChangers,
        ScreenWidth = GetScreenResolution().X,
        ScreenHeight = GetScreenResolution().Y,
    }
end
AdvancedPage = CreatePage("Advanced")
ConfigPage = CreatePage("Config")
CreateCategory(AdvancedPage, "Runtime", "7733715400")
CreateStatusHeader(AdvancedPage, "Executor runtime", "External execution state and local controller status.", 1)
runtimeRow, runtimeValue = CreateInfoRow(AdvancedPage, "Version", RAGNAROK_VERSION, 2)
aliveRow, aliveValue = CreateInfoRow(AdvancedPage, "Status", "ACTIVE", 3)
ballsRow, ballsValue = CreateInfoRow(AdvancedPage, "Ball models", "0", 4)
visualsRow, visualsValue = CreateInfoRow(AdvancedPage, "Visual hitboxes", "0", 5)
uptimeRow, uptimeValue = CreateInfoRow(AdvancedPage, "Session", "0s", 6)
CreateCategory(AdvancedPage, "Visual profile", "7733978098")
CreateOptionButton(AdvancedPage, "Hitbox color", {"Cyan", "Violet", "Green", "Amber"}, "HitboxColor", 7)
CreateSlider(AdvancedPage, "Hitbox refresh", 0.03, 0.4, "HitboxRefreshRate")
CreateActionButton(AdvancedPage, "CLEAR VISUAL HITBOXES", Color3.fromRGB(255, 170, 70), function()
    ClearHitboxes()
    Notify("Hitboxes", true)
end, 9)
CreateCategory(AdvancedPage, "Stat Changers", "7733715400")
CreateToggle(AdvancedPage, "Enable Stat Changers", "EnableStatChangers", function(enabled)
    SetStatsEnabled(enabled)
end)
CreateSlider(AdvancedPage, "Dive Speed", 0, 5, "DiveSpeed", function(value)
    ApplyStatValue("DiveSpeed", value)
    HookStatEnforcement()
end)
CreateSlider(AdvancedPage, "Spike Power", 0, 500, "SpikePower", function(value)
    ApplyStatValue("SpikePower", value)
    HookStatEnforcement()
end)
CreateSlider(AdvancedPage, "Tilt Power", 0, 500, "TiltPower", function(value)
    ApplyStatValue("TiltPower", value)
    HookStatEnforcement()
end)
CreateSlider(AdvancedPage, "Speed", 0, 1.5, "SpeedMult", function(value)
    ApplyStatValue("SpeedMult", value)
    ApplyAllStats()
    HookStatEnforcement()
end)
CreateSlider(AdvancedPage, "Set Power", 0, 500, "SetPower", function(value)
    ApplyStatValue("SetPower", value)
    HookStatEnforcement()
end)
CreateSlider(AdvancedPage, "Serve Power", 0, 500, "ServePower", function(value)
    ApplyStatValue("ServePower", value)
    HookStatEnforcement()
end)
CreateSlider(AdvancedPage, "Jump Power", 0, 5, "JumpPowerMult", function(value)
    ApplyStatValue("JumpPowerMult", value)
    ApplyAllStats()
    HookStatEnforcement()
end)
CreateSlider(AdvancedPage, "Bump Power", 0, 500, "BumpPower", function(value)
    ApplyStatValue("BumpPower", value)
    HookStatEnforcement()
end)
CreateSlider(AdvancedPage, "Block Power", 0, 500, "BlockPower", function(value)
    ApplyStatValue("BlockPower", value)
    HookStatEnforcement()
end)
CreateActionButton(AdvancedPage, "RESET STAT ATTRIBUTES", Color3.fromRGB(255, 170, 70), function()
    ResetStats()
    RefreshAllControls()
    Notify("Stats", true)
end, 20)
CreateCategory(ConfigPage, "Profile", "7733993211")
CreateStatusHeader(ConfigPage, "Configuration", "Executor file persistence and hotkey routing.", 1)
CreateActionButton(ConfigPage, "SAVE CONFIGURATION", Color3.fromRGB(0, 191, 255), function()
    if SaveConfig() then
        Notify("Configuration", true)
    end
end, 2)
CreateActionButton(ConfigPage, "LOAD CONFIGURATION", Color3.fromRGB(0, 191, 255), function()
    if LoadConfig() then
        RefreshAllControls()
        Notify("Configuration", true)
    end
end, 3)
CreateActionButton(ConfigPage, "RESTORE DEFAULTS", Color3.fromRGB(255, 170, 70), function()
    RestoreDefaults()
    Notify("Defaults", true)
end, 4)
CreateKeybindRow(ConfigPage, "Toggle interface", "ToggleKey", 5)
CreateKeybindRow(ConfigPage, "Shutdown runtime", "ShutdownKey", 6)
CreateOptionButton(ConfigPage, "Hitbox color", {"Cyan", "Violet", "Green", "Amber"}, "HitboxColor", 7)
CreateStatusHeader(ConfigPage, "Compatibility", "Detected executor capabilities.", 8)
CreateInfoRow(ConfigPage, "getgenv", type(getgenv) == "function" and "READY" or "MISSING", 9)
CreateInfoRow(ConfigPage, "gethui", type(gethui) == "function" and "READY" or "FALLBACK", 10)
CreateInfoRow(ConfigPage, "writefile", type(writefile) == "function" and "READY" or "MEMORY", 11)
CreateInfoRow(ConfigPage, "loadstring", type(loadstring) == "function" and "READY" or "UNUSED", 12)
function SetPage(name)
    if not RAGNAROK_ALIVE then
        return false
    end
    local selected = PageFrames[name]
    if not selected then
        return false
    end
    for pageName, pageData in pairs(PageFrames) do
        local active = pageName == name
        pageData.Page.Visible = active
        pageData.Btn.TextColor3 = active and Color3.fromRGB(0, 191, 255) or Color3.fromRGB(150, 150, 150)
    end
    return true
end
function RefreshRuntimeRows()
    if not RAGNAROK_ALIVE then
        return
    end
    if not runtimeValue or not aliveValue then
        return
    end
    local snapshot = GetRuntimeSnapshot()
    aliveValue.Text = snapshot.Alive and "ACTIVE" or "STOPPED"
    aliveValue.TextColor3 = snapshot.Alive and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(255, 70, 70)
    ballsValue.Text = tostring(snapshot.BallModels)
    visualsValue.Text = tostring(snapshot.Visuals)
    uptimeValue.Text = string.format("%ds", math.floor(snapshot.Uptime))
    if Config.ShowNotifications == false then
        activeNotifs = 0
    end
end
function RegisterGlobalInput()
    if GlobalInputConnection then
        GlobalInputConnection:Disconnect()
    end
    GlobalInputConnection = UIS.InputBegan:Connect(function(input, processed)
        if not RAGNAROK_ALIVE or processed then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        local keyName = input.KeyCode.Name
        if Config.ToggleKey and keyName == Config.ToggleKey then
            ToggleMain()
            return
        end
        if input.KeyCode == Enum.KeyCode.PageDown or input.KeyCode == Enum.KeyCode.Down then
            ScrollActivePage(240)
            return
        end
        if input.KeyCode == Enum.KeyCode.PageUp or input.KeyCode == Enum.KeyCode.Up then
            ScrollActivePage(-240)
            return
        end
        if input.KeyCode == Enum.KeyCode.Home then
            local page = GetActiveScrollPage()
            if page then
                page.CanvasPosition = Vector2.new(0, 0)
            end
            return
        end
        if input.KeyCode == Enum.KeyCode.End then
            local page = GetActiveScrollPage()
            if page then
                page.CanvasPosition = Vector2.new(0, math.max(0, page.AbsoluteCanvasSize.Y - page.AbsoluteWindowSize.Y))
            end
            return
        end
        if Config.ShutdownKey and Config.ShutdownKey ~= "None" and keyName == Config.ShutdownKey then
            FullShutdown("hotkey")
        end
    end)
end
function RegisterCharacterLifecycle()
    if CharacterConnection then
        CharacterConnection:Disconnect()
    end
    CharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        if not RAGNAROK_ALIVE then
            return
        end
        task.delay(0.25, function()
            if not RAGNAROK_ALIVE or not character.Parent then
                return
            end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            CaptureStatsBaseline()
            if humanoid and Config.AutoRotateEnabled then
                humanoid.AutoRotate = true
            end
            if Config.EnableStatChangers then
                ApplyAllStats()
                HookStatEnforcement()
            end
            ApplyCameraSettings()
        end)
    end)
end
function RegisterCameraLifecycle()
    if CameraConnection then
        CameraConnection:Disconnect()
    end
    CameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera = workspace.CurrentCamera or Camera
        ApplyCameraSettings()
    end)
end
function RegisterHeartbeat()
    if RuntimeConnection then
        RuntimeConnection:Disconnect()
    end
    RuntimeConnection = RunService.Heartbeat:Connect(function()
        if not RAGNAROK_ALIVE then
            return
        end
        RefreshRuntimeRows()
        if Config.AntiAFK and not antiAfkActive then
            local root = GetRootSafe()
            if root then
                antiAfkActive = true
                task.spawn(function()
                    local origin = root.CFrame
                    task.wait(60)
                    if RAGNAROK_ALIVE and Config.AntiAFK and root and root.Parent then
                        root.CFrame = origin + Vector3.new(0, 0.15, 0)
                        task.wait(0.1)
                        if root and root.Parent then
                            root.CFrame = origin
                        end
                    end
                    antiAfkActive = false
                end)
            end
        end
    end)
end
function RegisterRenderLifecycle()
    if RenderConnection then
        RenderConnection:Disconnect()
    end
    RenderConnection = RunService.RenderStepped:Connect(function()
        if not RAGNAROK_ALIVE then
            return
        end
        Camera = workspace.CurrentCamera or Camera
        if Config.HitboxEnabled then
            CreateHitboxes(Config.HitboxScale)
        else
            ClearHitboxes()
        end
        ApplyCameraSettings()
        local character = GetCharacterSafe()
        local humanoid = GetHumanoidSafe(character)
        local root = GetRootSafe(character)
        if Config.AutoRotateEnabled and humanoid then
            humanoid.AutoRotate = true
        end
        if Config.AirMoveEnabled and humanoid and root then
            local state = humanoid:GetState()
            if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
                local move = humanoid.MoveDirection
                if move.Magnitude > 0 then
                    local velocity = root.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity = Vector3.new(move.X * Config.AirMoveSpeed, velocity.Y, move.Z * Config.AirMoveSpeed)
                end
            end
        end
    end)
end
function InstallExecutorRuntime()
    RegisterGlobalInput()
    RegisterCharacterLifecycle()
    RegisterCameraLifecycle()
    RegisterHeartbeat()
    RegisterRenderLifecycle()
    RefreshAllControls()
    ApplyCameraSettings()
    if type(getgenv) == "function" then
        getgenv().RagnarokShutdown = FullShutdown
        getgenv().RagnarokAPI = {
            Version = RAGNAROK_VERSION,
            Config = Config,
            Toggle = ToggleMain,
            SetPage = SetPage,
            Save = SaveConfig,
            Load = LoadConfig,
            Reset = RestoreDefaults,
            Snapshot = GetRuntimeSnapshot,
            Shutdown = FullShutdown,
        }
    end
end
InstallExecutorRuntime()
RuntimeServices = {
    Alive = true,
    StartedAt = RAGNAROK_START,
    LastRender = 0,
    LastHeartbeat = 0,
    LastDiagnostics = 0,
    LastConfigSave = 0,
    LastVisualScan = 0,
    RenderCount = 0,
    HeartbeatCount = 0,
    ErrorCount = 0,
    Log = {},
    LogLimit = 120,
    Connections = {},
    Capability = {},
    FeatureState = {},
}
function AddRuntimeLog(kind, message, detail)
    local entry = {
        Time = os.clock() - RAGNAROK_START,
        Kind = tostring(kind or "info"),
        Message = tostring(message or ""),
        Detail = detail and tostring(detail) or "",
    }
    table.insert(RuntimeServices.Log, entry)
    while #RuntimeServices.Log > RuntimeServices.LogLimit do
        table.remove(RuntimeServices.Log, 1)
    end
    if kind == "error" then
        RuntimeServices.ErrorCount = RuntimeServices.ErrorCount + 1
    end
    return entry
end
function ClearRuntimeLog()
    RuntimeServices.Log = {}
    RuntimeServices.ErrorCount = 0
end
function GetRuntimeLog()
    local result = {}
    for index, entry in ipairs(RuntimeServices.Log) do
        result[index] = {
            Time = entry.Time,
            Kind = entry.Kind,
            Message = entry.Message,
            Detail = entry.Detail,
        }
    end
    return result
end
function RegisterRuntimeConnection(name, connection)
    if RuntimeServices.Connections[name] then
        pcall(function()
            RuntimeServices.Connections[name]:Disconnect()
        end)
    end
    RuntimeServices.Connections[name] = connection
    return connection
end
function DisconnectRuntimeConnection(name)
    local connection = RuntimeServices.Connections[name]
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
        RuntimeServices.Connections[name] = nil
    end
end
function DisconnectRuntimeConnections()
    for name in pairs(RuntimeServices.Connections) do
        DisconnectRuntimeConnection(name)
    end
end
function DetectExecutorCapabilities()
    RuntimeServices.Capability = {
        getgenv = type(getgenv) == "function",
        gethui = type(gethui) == "function",
        protect_gui = syn and type(syn.protect_gui) == "function" or false,
        writefile = type(writefile) == "function",
        readfile = type(readfile) == "function",
        isfile = type(isfile) == "function",
        makefolder = type(makefolder) == "function",
        loadstring = type(loadstring) == "function",
        request = type(request) == "function",
        hookmetamethod = type(hookmetamethod) == "function",
        queue_on_teleport = type(queue_on_teleport) == "function",
    }
    return RuntimeServices.Capability
end
function HasCapability(name)
    return RuntimeServices.Capability[name] == true
end
function ValidateNumber(value, minimum, maximum, fallback)
    local number = tonumber(value)
    if not number then
        return fallback
    end
    return math.clamp(number, minimum, maximum)
end
function ValidateBoolean(value, fallback)
    if type(value) == "boolean" then
        return value
    end
    return fallback
end
function ValidateString(value, fallback)
    if type(value) == "string" and #value > 0 then
        return value
    end
    return fallback
end
function NormalizeExecutorConfig()
    Config.HitboxScale = ValidateNumber(Config.HitboxScale, 1, 24, 6)
    Config.HitboxTransparency = ValidateNumber(Config.HitboxTransparency, 0.1, 0.95, 0.7)
    Config.HitboxRefreshRate = ValidateNumber(Config.HitboxRefreshRate, 0.03, 0.4, 0.08)
    Config.AirMoveSpeed = ValidateNumber(Config.AirMoveSpeed, 1, 120, 15)
    Config.NormalFOV = ValidateNumber(Config.NormalFOV, 50, 120, 70)
    Config.StretchedFOV = ValidateNumber(Config.StretchedFOV, 70, 130, 110)
    Config.HitboxEnabled = ValidateBoolean(Config.HitboxEnabled, true)
    Config.DirectionalJump = ValidateBoolean(Config.DirectionalJump, true)
    Config.AirMoveEnabled = ValidateBoolean(Config.AirMoveEnabled, false)
    Config.AntiAFK = ValidateBoolean(Config.AntiAFK, false)
    Config.StretchedRes = ValidateBoolean(Config.StretchedRes, false)
    Config.AutoRotateEnabled = ValidateBoolean(Config.AutoRotateEnabled, false)
    Config.ShowNotifications = ValidateBoolean(Config.ShowNotifications, true)
    Config.HitboxColor = ValidateString(Config.HitboxColor, "Cyan")
    Config.ToggleKey = ValidateString(Config.ToggleKey, "RightShift")
    Config.ShutdownKey = ValidateString(Config.ShutdownKey, "None")
    Config.EnableStatChangers = ValidateBoolean(Config.EnableStatChangers, false)
    Config.DiveSpeed = ValidateNumber(Config.DiveSpeed, 0, 5, 1)
    Config.SpikePower = ValidateNumber(Config.SpikePower, 0, 500, 1)
    Config.TiltPower = ValidateNumber(Config.TiltPower, 0, 500, 1)
    Config.SpeedMult = ValidateNumber(Config.SpeedMult, 0, 1.5, 1)
    Config.SetPower = ValidateNumber(Config.SetPower, 0, 500, 1)
    Config.ServePower = ValidateNumber(Config.ServePower, 0, 500, 1)
    Config.JumpPowerMult = ValidateNumber(Config.JumpPowerMult, 0, 5, 1)
    Config.BumpPower = ValidateNumber(Config.BumpPower, 0, 500, 1)
    Config.BlockPower = ValidateNumber(Config.BlockPower, 0, 500, 1)
    if type(Config.Binds) ~= "table" then
        Config.Binds = {}
    end
    if type(Config.IconPos) ~= "table" or #Config.IconPos < 4 then
        Config.IconPos = {1, -100, 1, -100}
    end
end
function SetConfigValue(key, value, save)
    local current = Config[key]
    if current == nil then
        return false
    end
    Config[key] = value
    NormalizeExecutorConfig()
    RefreshAllControls()
    if key == "HitboxEnabled" and not Config.HitboxEnabled then
        ClearHitboxes()
    end
    if key == "HitboxColor" then
        ClearHitboxes()
    end
    if key == "StretchedRes" or key == "NormalFOV" or key == "StretchedFOV" then
        ApplyCameraSettings()
    end
    if save ~= false then
        SaveConfig()
    end
    AddRuntimeLog("state", key .. " changed")
    return true
end
function GetConfigSnapshot()
    local snapshot = {}
    for key, value in pairs(Config) do
        if type(value) == "table" then
            snapshot[key] = {}
            for nestedKey, nestedValue in pairs(value) do
                snapshot[key][nestedKey] = nestedValue
            end
        else
            snapshot[key] = value
        end
    end
    return snapshot
end
function GetFeatureState(name)
    return RuntimeServices.FeatureState[name] == true
end
function SetFeatureState(name, active)
    RuntimeServices.FeatureState[name] = active == true
end
function GetFeatureStates()
    local states = {}
    for name, active in pairs(RuntimeServices.FeatureState) do
        states[name] = active
    end
    return states
end
function ResolveBallReference(model)
    if not model or not model:IsA("Model") then
        return nil
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "RagnarokHitbox" then
            return descendant
        end
    end
    return nil
end
function GetBallModels()
    local result = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child.Name:match("^CLIENT_BALL_%d+$") then
            table.insert(result, child)
        end
    end
    return result
end
function RemoveVisualFromModel(model)
    local visual = model and model:FindFirstChild("RagnarokHitbox")
    if visual then
        visual:Destroy()
        return true
    end
    return false
end
function ApplyVisualToModel(model)
    local reference = ResolveBallReference(model)
    if not reference then
        return false
    end
    local visual = model:FindFirstChild("RagnarokHitbox")
    if not visual then
        visual = Instance.new("Part")
        visual.Name = "RagnarokHitbox"
        visual.Shape = Enum.PartType.Ball
        visual.Anchored = true
        visual.CanCollide = false
        visual.CanTouch = false
        visual.CanQuery = false
        visual.CastShadow = false
        visual.Material = Enum.Material.ForceField
        visual.Parent = model
    end
    visual.Size = Vector3.new(Config.HitboxScale, Config.HitboxScale, Config.HitboxScale)
    visual.CFrame = reference.CFrame
    visual.Transparency = Config.HitboxTransparency
    visual.Color = GetVisualColor()
    return true
end
function RefreshVisualService(force)
    if not Config.HitboxEnabled then
        return ClearHitboxes()
    end
    local now = os.clock()
    if not force and now - RuntimeServices.LastVisualScan < Config.HitboxRefreshRate then
        return
    end
    RuntimeServices.LastVisualScan = now
    local count = 0
    for _, model in ipairs(GetBallModels()) do
        if ApplyVisualToModel(model) then
            count = count + 1
        end
    end
    SetFeatureState("hitbox", count > 0 or Config.HitboxEnabled)
    return count
end
function RefreshMovementService()
    local character = GetCharacterSafe()
    local humanoid = GetHumanoidSafe(character)
    local root = GetRootSafe(character)
    if not humanoid or not root then
        return false
    end
    if Config.AutoRotateEnabled then
        humanoid.AutoRotate = true
    end
    if Config.DirectionalJump then
        SetFeatureState("directional", true)
    else
        SetFeatureState("directional", false)
    end
    if Config.AirMoveEnabled then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
            local direction = humanoid.MoveDirection
            if direction.Magnitude > 0 then
                local velocity = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(direction.X * Config.AirMoveSpeed, velocity.Y, direction.Z * Config.AirMoveSpeed)
            end
        end
        SetFeatureState("airmove", true)
    else
        SetFeatureState("airmove", false)
    end
    return true
end
function RefreshCameraService()
    local camera = GetCameraSafe()
    if not camera then
        return false
    end
    camera.FieldOfView = Config.StretchedRes and Config.StretchedFOV or Config.NormalFOV
    SetFeatureState("camera", true)
    return true
end
function StopAntiAfkService()
    Config.AntiAFK = false
    antiAfkActive = false
    SetFeatureState("antiafk", false)
end
function StartAntiAfkService()
    if not Config.AntiAFK then
        StopAntiAfkService()
        return
    end
    SetFeatureState("antiafk", true)
end
function RefreshExecutorServices()
    NormalizeExecutorConfig()
    RefreshVisualService(false)
    RefreshMovementService()
    RefreshCameraService()
    if Config.AntiAFK then
        StartAntiAfkService()
    else
        StopAntiAfkService()
    end
    if Config.EnableStatChangers then
        ApplyAllStats()
        HookStatEnforcement()
        SetFeatureState("stats", true)
    else
        SetFeatureState("stats", false)
    end
end
function RuntimeDiagnostic()
    DetectExecutorCapabilities()
    NormalizeExecutorConfig()
    local snapshot = GetRuntimeSnapshot()
    snapshot.Capabilities = {}
    for key, value in pairs(RuntimeServices.Capability) do
        snapshot.Capabilities[key] = value
    end
    snapshot.Features = GetFeatureStates()
    snapshot.Errors = RuntimeServices.ErrorCount
    snapshot.LogSize = #RuntimeServices.Log
    return snapshot
end
function UpdateRuntimeRowsExtended()
    if not RAGNAROK_ALIVE then
        return
    end
    local snapshot = RuntimeDiagnostic()
    if runtimeValue then runtimeValue.Text = snapshot.Version end
    if aliveValue then aliveValue.Text = snapshot.Alive and "ACTIVE" or "STOPPED" end
    if ballsValue then ballsValue.Text = tostring(snapshot.BallModels) end
    if visualsValue then visualsValue.Text = tostring(snapshot.Visuals) end
    if uptimeValue then uptimeValue.Text = string.format("%ds", math.floor(snapshot.Uptime)) end
end
function ScheduleExecutorMaintenance()
    if MaintenanceTask then
        return
    end
    MaintenanceTask = task.spawn(function()
        while RAGNAROK_ALIVE do
            task.wait(1)
            if not RAGNAROK_ALIVE then
                break
            end
            RuntimeServices.HeartbeatCount = RuntimeServices.HeartbeatCount + 1
            RuntimeServices.LastHeartbeat = os.clock()
            ApplyResponsiveLayout()
            RefreshExecutorServices()
            UpdateRuntimeRowsExtended()
            if RuntimeServices.LastConfigSave == 0 then
                RuntimeServices.LastConfigSave = os.clock()
            elseif os.clock() - RuntimeServices.LastConfigSave > 20 then
                SaveConfig()
                RuntimeServices.LastConfigSave = os.clock()
            end
        end
    end)
end
function CancelExecutorMaintenance()
    MaintenanceTask = nil
end
function InstallRuntimeSafety()
    DetectExecutorCapabilities()
    NormalizeExecutorConfig()
    AddRuntimeLog("system", "executor runtime initialized")
    ScheduleExecutorMaintenance()
end
InstallRuntimeSafety()
ExecutorProfiles = {
    default = {
        HitboxScale = 6,
        HitboxEnabled = true,
        DirectionalJump = true,
        AirMoveEnabled = false,
        AirMoveSpeed = 15,
        AntiAFK = false,
        StretchedRes = false,
        HitboxTransparency = 0.7,
        HitboxColor = "Cyan",
        NormalFOV = 70,
        StretchedFOV = 110,
        AutoRotateEnabled = false,
        ShowNotifications = true,
    },
    movement = {
        HitboxScale = 6,
        HitboxEnabled = true,
        DirectionalJump = true,
        AirMoveEnabled = true,
        AirMoveSpeed = 35,
        AntiAFK = true,
        StretchedRes = false,
        HitboxTransparency = 0.7,
        HitboxColor = "Cyan",
        NormalFOV = 70,
        StretchedFOV = 110,
        AutoRotateEnabled = true,
        ShowNotifications = true,
    },
    clean = {
        HitboxScale = 6,
        HitboxEnabled = false,
        DirectionalJump = false,
        AirMoveEnabled = false,
        AirMoveSpeed = 15,
        AntiAFK = false,
        StretchedRes = false,
        HitboxTransparency = 0.7,
        HitboxColor = "Cyan",
        NormalFOV = 70,
        StretchedFOV = 110,
        AutoRotateEnabled = false,
        ShowNotifications = true,
    },
}
function SaveProfile(name)
    local profile = ExecutorProfiles[name]
    if not profile then
        return false
    end
    for key, value in pairs(profile) do
        Config[key] = value
    end
    NormalizeExecutorConfig()
    RefreshAllControls()
    ApplyCameraSettings()
    ClearHitboxes()
    SaveConfig()
    AddRuntimeLog("profile", name .. " loaded")
    return true
end
function CaptureProfile(name)
    if not ExecutorProfiles[name] then
        ExecutorProfiles[name] = {}
    end
    for key, value in pairs(Config) do
        if type(value) ~= "table" and key ~= "ToggleKey" and key ~= "ShutdownKey" then
            ExecutorProfiles[name][key] = value
        end
    end
    AddRuntimeLog("profile", name .. " captured")
    return true
end
function DeleteProfile(name)
    if name == "default" or not ExecutorProfiles[name] then
        return false
    end
    ExecutorProfiles[name] = nil
    AddRuntimeLog("profile", name .. " deleted")
    return true
end
function ListProfiles()
    local names = {}
    for name in pairs(ExecutorProfiles) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end
function ExportRuntimeSnapshot()
    if type(writefile) ~= "function" then
        return false
    end
    local payload = {
        Version = RAGNAROK_VERSION,
        Created = os.time(),
        Config = GetConfigSnapshot(),
        Runtime = RuntimeDiagnostic(),
        Log = GetRuntimeLog(),
    }
    local success = pcall(function()
        writefile("RagnarokRuntimeSnapshot.json", HttpService:JSONEncode(payload))
    end)
    if success then
        AddRuntimeLog("snapshot", "runtime snapshot exported")
    end
    return success
end
function ImportRuntimeSnapshot()
    if type(isfile) ~= "function" or type(readfile) ~= "function" or not isfile("RagnarokRuntimeSnapshot.json") then
        return false
    end
    local success, decoded = pcall(function()
        return HttpService:JSONDecode(readfile("RagnarokRuntimeSnapshot.json"))
    end)
    if not success or type(decoded) ~= "table" or type(decoded.Config) ~= "table" then
        return false
    end
    for key, value in pairs(decoded.Config) do
        if Config[key] ~= nil and type(value) == type(Config[key]) then
            Config[key] = value
        end
    end
    NormalizeExecutorConfig()
    RefreshAllControls()
    ApplyCameraSettings()
    AddRuntimeLog("snapshot", "runtime snapshot imported")
    return true
end
function RunExecutorSelfTest()
    local checks = {}
    checks.Services = type(game) == "userdata" or type(game) == "table"
    checks.Players = Players ~= nil and LocalPlayer ~= nil
    checks.Input = UIS ~= nil and type(UIS.InputBegan.Connect) == "function"
    checks.Render = RunService ~= nil and type(RunService.RenderStepped.Connect) == "function"
    checks.Gui = Ragnarok ~= nil and Ragnarok.Parent ~= nil
    checks.Controls = ControlRegistry ~= nil and next(ControlRegistry) ~= nil
    checks.Persistence = type(writefile) == "function" and type(readfile) == "function"
    checks.Executor = type(getgenv) == "function" or type(gethui) == "function"
    checks.Config = Config ~= nil and type(Config.HitboxScale) == "number"
    checks.Cleanup = type(ClearHitboxes) == "function" and type(FullShutdown) == "function"
    local passed = 0
    local total = 0
    for _, result in pairs(checks) do
        total = total + 1
        if result then
            passed = passed + 1
        end
    end
    checks.Passed = passed
    checks.Total = total
    checks.Success = passed == total
    AddRuntimeLog(checks.Success and "selftest" or "warning", string.format("self test %d/%d", passed, total))
    return checks
end
function GetCapabilitySummary()
    local summary = {}
    for name, available in pairs(RuntimeServices.Capability) do
        summary[name] = available and "READY" or "MISSING"
    end
    return summary
end
function FormatRuntimeLine(label, value)
    return string.format("%-18s %s", tostring(label), tostring(value))
end
function FormatRuntimeReport()
    local snapshot = RuntimeDiagnostic()
    local lines = {
        FormatRuntimeLine("VERSION", snapshot.Version),
        FormatRuntimeLine("STATUS", snapshot.Alive and "ACTIVE" or "STOPPED"),
        FormatRuntimeLine("UPTIME", math.floor(snapshot.Uptime) .. "s"),
        FormatRuntimeLine("BALL MODELS", snapshot.BallModels),
        FormatRuntimeLine("VISUALS", snapshot.Visuals),
        FormatRuntimeLine("ERRORS", snapshot.Errors),
        FormatRuntimeLine("LOG SIZE", snapshot.LogSize),
    }
    for name, state in pairs(snapshot.Features or {}) do
        table.insert(lines, FormatRuntimeLine(name:upper(), state and "ON" or "OFF"))
    end
    return table.concat(lines, "\n")
end
function ShowRuntimeReport()
    local report = FormatRuntimeReport()
    if setclipboard then
        pcall(function()
            setclipboard(report)
        end)
    end
    AddRuntimeLog("report", "runtime report generated")
    return report
end
function RefreshCompatibilityRows()
    local summary = GetCapabilitySummary()
    if not ConfigPage then
        return
    end
    for _, child in ipairs(ConfigPage:GetChildren()) do
        if child:IsA("Frame") then
            local text = child:FindFirstChildOfClass("TextLabel")
            if text and summary[text.Text] then
                text.Text = text.Text
            end
        end
    end
end
function CreateLogPanel(parent, order)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, -30, 0, 160)
    panel.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    panel.LayoutOrder = order or 1
    panel.Parent = parent
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 24)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "RUNTIME LOG"
    title.TextColor3 = Color3.fromRGB(0, 191, 255)
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel
    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -20, 1, -42)
    body.Position = UDim2.new(0, 10, 0, 34)
    body.BackgroundTransparency = 1
    body.Font = Enum.Font.Code
    body.Text = "NO EVENTS"
    body.TextColor3 = Color3.fromRGB(160, 160, 170)
    body.TextSize = 10
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = panel
    return panel, body
end
LogPanel, LogBody = CreateLogPanel(AdvancedPage, 11)
function RefreshLogPanel()
    if not LogBody then
        return
    end
    local lines = {}
    local start = math.max(1, #RuntimeServices.Log - 7)
    for index = #RuntimeServices.Log, start, -1 do
        local entry = RuntimeServices.Log[index]
        table.insert(lines, string.format("[%s] %s", entry.Kind:upper(), entry.Message))
    end
    LogBody.Text = #lines > 0 and table.concat(lines, "\n") or "NO EVENTS"
end
CreateActionButton(AdvancedPage, "RUN EXECUTOR SELF TEST", Color3.fromRGB(0, 191, 255), function()
    local result = RunExecutorSelfTest()
    Notify("Self test", result.Success)
    RefreshLogPanel()
end, 12)
CreateActionButton(AdvancedPage, "EXPORT RUNTIME SNAPSHOT", Color3.fromRGB(0, 191, 255), function()
    Notify("Snapshot", ExportRuntimeSnapshot())
    RefreshLogPanel()
end, 13)
CreateActionButton(AdvancedPage, "COPY RUNTIME REPORT", Color3.fromRGB(200, 200, 210), function()
    ShowRuntimeReport()
    Notify("Report", true)
    RefreshLogPanel()
end, 14)
CreateActionButton(ConfigPage, "CAPTURE MOVEMENT PROFILE", Color3.fromRGB(0, 191, 255), function()
    CaptureProfile("movement")
    Notify("Profile", true)
end, 13)
CreateActionButton(ConfigPage, "LOAD MOVEMENT PROFILE", Color3.fromRGB(0, 191, 255), function()
    SaveProfile("movement")
    Notify("Profile", true)
end, 14)
CreateActionButton(ConfigPage, "LOAD CLEAN PROFILE", Color3.fromRGB(200, 200, 210), function()
    SaveProfile("clean")
    Notify("Profile", true)
end, 15)
function RefreshExtendedServices()
    if not RAGNAROK_ALIVE then
        return
    end
    RuntimeServices.RenderCount = RuntimeServices.RenderCount + 1
    RefreshVisualService(false)
    RefreshMovementService()
    RefreshCameraService()
    RefreshRuntimeRows()
    RefreshLogPanel()
end
function ProtectExecutorGui(instance)
    if not instance then
        return false
    end
    if type(gethui) == "function" then
        local success = pcall(function()
            instance.Parent = gethui()
        end)
        if success then
            return true
        end
    end
    if syn and type(syn.protect_gui) == "function" then
        pcall(function()
            syn.protect_gui(instance)
        end)
    end
    local success = pcall(function()
        instance.Parent = CoreGui
    end)
    return success
end
function EnsureExecutorGuiParent()
    if Ragnarok and Ragnarok.Parent then
        return true
    end
    return ProtectExecutorGui(Ragnarok)
end
function ReopenExecutorInterface()
    if not RAGNAROK_ALIVE then
        return false
    end
    EnsureExecutorGuiParent()
    Main.Visible = true
    Icon.Visible = false
    return true
end
function MinimizeExecutorInterface()
    if not RAGNAROK_ALIVE then
        return false
    end
    Main.Visible = false
    Icon.Visible = true
    return true
end
function RefreshInterfaceState()
    if not RAGNAROK_ALIVE then
        return
    end
    if Main.Visible then
        Icon.Visible = false
    else
        Icon.Visible = true
    end
    if Config.HideIcon then
        Icon.Visible = false
    end
end
function CheckExecutorState()
    local ready = RAGNAROK_ALIVE and Ragnarok and Ragnarok.Parent and Main and Main.Parent
    SetFeatureState("ui", ready == true)
    SetFeatureState("runtime", RAGNAROK_ALIVE == true)
    return ready == true
end
InstallExecutorRuntime()
RefreshExtendedServices()
AddRuntimeLog("system", "v1 compact interface restored")
RefreshLogPanel()
function GetExecutorEnvironment()
    local capabilities = DetectExecutorCapabilities()
    local result = {}
    for key, value in pairs(capabilities) do
        result[key] = value
    end
    result.Version = RAGNAROK_VERSION
    result.Alive = RAGNAROK_ALIVE
    result.GuiParented = Ragnarok and Ragnarok.Parent ~= nil or false
    result.MainVisible = Main and Main.Visible or false
    result.ConnectionCount = 0
    for _ in pairs(RuntimeServices.Connections) do
        result.ConnectionCount = result.ConnectionCount + 1
    end
    return result
end
function SetNotificationState(enabled)
    Config.ShowNotifications = enabled == true
    if not Config.ShowNotifications then
        notifyQueue = {}
    end
    SaveConfig()
    return Config.ShowNotifications
end
function SetInterfaceVisibility(visible)
    if visible then
        return ReopenExecutorInterface()
    end
    return MinimizeExecutorInterface()
end
function IsRuntimeReady()
    return CheckExecutorState()
end
function ShutdownAndRestore()
    FullShutdown("api")
    return true
end
function BuildExecutorAPI()
    return {
        Version = RAGNAROK_VERSION,
        Config = Config,
        Toggle = ToggleMain,
        Show = function() return SetInterfaceVisibility(true) end,
        Hide = function() return SetInterfaceVisibility(false) end,
        SetPage = SetPage,
        SetValue = SetConfigValue,
        GetConfig = GetConfigSnapshot,
        GetState = GetRuntimeSnapshot,
        GetStats = function()
            return {
                Enabled = Config.EnableStatChangers,
                DiveSpeed = Config.DiveSpeed,
                SpikePower = Config.SpikePower,
                TiltPower = Config.TiltPower,
                SpeedMult = Config.SpeedMult,
                SetPower = Config.SetPower,
                ServePower = Config.ServePower,
                JumpPowerMult = Config.JumpPowerMult,
                BumpPower = Config.BumpPower,
                BlockPower = Config.BlockPower,
            }
        end,
        SetStatsEnabled = SetStatsEnabled,
        ApplyAllStats = ApplyAllStats,
        ResetStats = ResetStats,
        GetRuntime = RuntimeDiagnostic,
        GetEnvironment = GetExecutorEnvironment,
        GetLogs = GetRuntimeLog,
        ClearLogs = ClearRuntimeLog,
        SelfTest = RunExecutorSelfTest,
        Save = SaveConfig,
        Load = function()
            local result = LoadConfig()
            RefreshAllControls()
            return result
        end,
        Reset = RestoreDefaults,
        Export = ExportRuntimeSnapshot,
        Import = ImportRuntimeSnapshot,
        SaveProfile = SaveProfile,
        LoadProfile = SaveProfile,
        CaptureProfile = CaptureProfile,
        ListProfiles = ListProfiles,
        Notify = Notify,
        Shutdown = ShutdownAndRestore,
        Ready = IsRuntimeReady,
    }
end
function InstallFinalAPI()
    local api = BuildExecutorAPI()
    if type(getgenv) == "function" then
        getgenv().RagnarokAPI = api
        getgenv().RagnarokShutdown = FullShutdown
    end
    return api
end
function FinalExecutorRefresh()
    if not RAGNAROK_ALIVE then
        return false
    end
    NormalizeExecutorConfig()
    RefreshAllControls()
    RefreshExecutorServices()
    RefreshExtendedServices()
    RefreshInterfaceState()
    return true
end
FinalExecutorRefresh()
FinalAPI = InstallFinalAPI()
