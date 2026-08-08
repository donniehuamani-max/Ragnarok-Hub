local RAGNAROK_VERSION = "1.0"

if getgenv then
    if getgenv().RagnarokShutdown then
        pcall(getgenv().RagnarokShutdown)
    end
    getgenv().RagnarokVersion = RAGNAROK_VERSION
end

local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RAGNAROK_ALIVE = true
local autoRotateConnection = nil
local Icon

local function Protect(inst)
    if gethui then
        inst.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(inst)
        inst.Parent = CoreGui
    else
        inst.Parent = CoreGui
    end
end

for _, v in ipairs(CoreGui:GetChildren()) do
    if v.Name == "RagnarokHub" or v.Name == "RagnarokNotify" then
        v:Destroy()
    end
end

local Config = {
    HitboxScale = 6,
    HitboxEnabled = true,
    DirectionalJump = true,
    AirMoveEnabled = false,
    AirMoveSpeed = 15,
    AntiAFK = false,
    StretchedRes = false,
    IconPos = {1, -100, 1, -100},
    Binds = {},
    ToggleUIKey = "RightShift",
    HideIcon = false,
    DiveSpeed = 1,
    SpikePower = 1,
    TiltPower = 1,
    SpeedMult = 1,
    SetPower = 1,
    ServePower = 1,
    JumpPowerMult = 1,
    BumpPower = 1,
    BlockPower = 1,
    AutoRotateEnabled = false,
    PowerfulServeEnabled = false,
}

local function SaveConfig()
    if writefile then
        pcall(function()
            writefile("RagnarokConfig.json", HttpService:JSONEncode(Config))
        end)
    end
end

local function LoadConfig()
    if isfile and isfile("RagnarokConfig.json") then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile("RagnarokConfig.json")) end)
        if success and type(data) == "table" then
            for k, v in pairs(data) do
                Config[k] = v
            end
        end
    end
end

LoadConfig()

local NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "RagnarokNotify"
NotifyGui.ResetOnSpawn = false
NotifyGui.DisplayOrder = 100
Protect(NotifyGui)

local NotifyList = Instance.new("Frame")
NotifyList.Size = UDim2.new(0, 280, 1, 0)
NotifyList.Position = UDim2.new(0, 20, 0, 20)
NotifyList.BackgroundTransparency = 1
NotifyList.Parent = NotifyGui

local notifyQueue = {}
local activeNotifs = 0

local function ProcessQueue()
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
            if not RAGNAROK_ALIVE then return end
            TweenService:Create(nFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(-1.2, 0, 0, nFrame.Position.Y.Offset)}):Play()
            task.wait(0.4)
            nFrame:Destroy()
            activeNotifs = activeNotifs - 1
            ProcessQueue()
        end)
    end
end

local function Notify(name, state)
    local statusText = state and '<font color="#00FF7F">Activated</font>' or '<font color="#FF4500">Deactivated</font>'
    table.insert(notifyQueue, {msg = name .. ": " .. statusText})
    ProcessQueue()
end

local Ragnarok = Instance.new("ScreenGui")
Ragnarok.Name = "RagnarokHub"
Ragnarok.ResetOnSpawn = false
Ragnarok.DisplayOrder = 10
Protect(Ragnarok)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = Ragnarok
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Main.Position = UDim2.new(0.5, -210, 0.5, -250)
Main.Size = UDim2.new(0, 420, 0, 500)
Main.Visible = false
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(0, 191, 255)
MainStroke.Thickness = 2
MainStroke.Transparency = 0.6

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "RAGNAROK HUB v" .. RAGNAROK_VERSION
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 191, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 191, 255))
})
TitleGradient.Parent = Title

task.spawn(function()
    while RAGNAROK_ALIVE do
        local t = TweenService:Create(TitleGradient, TweenInfo.new(3, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
        t:Play()
        t.Completed:Wait()
        TitleGradient.Offset = Vector2.new(-1, 0)
    end
end)

local function CreateHeaderBtn(text, xOffset, callback)
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
    b.MouseButton1Click:Connect(callback)
    return b
end

local function ClearHitboxes()
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local ball = model:FindFirstChild("Ball.001")
            if ball then ball:Destroy() end
        end
    end
end

local function stopAutoRotateMonitor()
    if autoRotateConnection then
        autoRotateConnection:Disconnect()
        autoRotateConnection = nil
    end
end

local function startAutoRotateMonitor()
    if autoRotateConnection then return end
    autoRotateConnection = RunService.Heartbeat:Connect(function()
        if not RAGNAROK_ALIVE then
            stopAutoRotateMonitor()
            return
        end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.AutoRotate == false then
                hum.AutoRotate = true
            end
        end
    end)
end

local CloseBtn = CreateHeaderBtn("X", -40, function()
    local Prompt = Ragnarok:FindFirstChild("TerminationMenu")
    if Prompt then Prompt.Visible = true end
end)

local MinBtn = CreateHeaderBtn("M", -80, function()
    Main.Visible = false
    if Icon and not Config.HideIcon then
        Icon.Visible = true
    end
end)

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 50)
TabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
TabContainer.Parent = Main

local TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Parent = TabContainer

local Pages = Instance.new("Frame")
Pages.Size = UDim2.new(1, 0, 1, -85)
Pages.Position = UDim2.new(0, 0, 0, 85)
Pages.BackgroundTransparency = 1
Pages.Parent = Main

local PageFrames = {}

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Color3.fromRGB(0, 191, 255)
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.Parent = Pages

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Page

    local pad = Instance.new("UIPadding", Page)
    pad.PaddingLeft = UDim.new(0, 15)
    pad.PaddingRight = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 20)
    pad.PaddingTop = UDim.new(0, 5)

    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0.25, 0, 1, 0)
    TabBtn.BackgroundTransparency = 1
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.Text = name:upper()
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.TextSize = 11
    TabBtn.Parent = TabContainer

    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(PageFrames) do
            p.Page.Visible = false
            p.Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        Page.Visible = true
        TabBtn.TextColor3 = Color3.fromRGB(0, 191, 255)
    end)

    PageFrames[name] = {Page = Page, Btn = TabBtn}
    return Page
end

local MainPage = CreatePage("Main")
local MiscPage = CreatePage("Misc")
local ExperimentalsPage = CreatePage("Experimentals")
local ConfigPage = CreatePage("Config")
PageFrames["Main"].Page.Visible = true
PageFrames["Main"].Btn.TextColor3 = Color3.fromRGB(0, 191, 255)

local function CreateCategory(parent, name, iconId)
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
local iconStroke = Instance.new("UIStroke", Icon)
iconStroke.Color = Color3.fromRGB(0, 191, 255)
iconStroke.Thickness = 2
iconStroke.Transparency = 0.4

if Config.HideIcon then
    Icon.Visible = false
end

local function MakeDraggable(obj, target, isIcon)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

MakeDraggable(Header, Main, false)
MakeDraggable(Icon, Icon, true)

Icon.MouseButton1Click:Connect(function()
    Main.Visible = true
    Main.BackgroundTransparency = 1
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
    Icon.Visible = false
end)

local TerminationMenu = Instance.new("Frame")
TerminationMenu.Name = "TerminationMenu"
TerminationMenu.Size = UDim2.new(0, 340, 0, 300)
TerminationMenu.Position = UDim2.new(0.5, -170, 0.5, -150)
TerminationMenu.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
TerminationMenu.Visible = false
TerminationMenu.ZIndex = 5000
TerminationMenu.Parent = Ragnarok
Instance.new("UICorner", TerminationMenu).CornerRadius = UDim.new(0, 12)
local termStroke = Instance.new("UIStroke", TerminationMenu)
termStroke.Color = Color3.fromRGB(0, 191, 255)
termStroke.Thickness = 2

local THeader = Instance.new("Frame")
THeader.Size = UDim2.new(1, 0, 0, 50)
THeader.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
THeader.Parent = TerminationMenu
THeader.ZIndex = 5001
Instance.new("UICorner", THeader).CornerRadius = UDim.new(0, 12)

local TTitle = Instance.new("TextLabel")
TTitle.Size = UDim2.new(1, 0, 1, 0)
TTitle.BackgroundTransparency = 1
TTitle.Font = Enum.Font.GothamBold
TTitle.Text = "SYSTEM TERMINATION"
TTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TTitle.TextSize = 16
TTitle.ZIndex = 5002
TTitle.Parent = THeader

local TContent = Instance.new("TextLabel")
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

local function ResetAttributes()
    pcall(function()
        LocalPlayer:SetAttribute("GameDiveSpeedMultiplier", 1)
        LocalPlayer:SetAttribute("GameSpikePowerMultiplier", 1)
        LocalPlayer:SetAttribute("GameTiltPowerMultiplier", 1)
        LocalPlayer:SetAttribute("GameSpeedMultiplier", 1)
        LocalPlayer:SetAttribute("GameSetPowerMultiplier", 1)
        LocalPlayer:SetAttribute("GameServePowerMultiplier", 1)
        LocalPlayer:SetAttribute("GameJumpPowerMultiplier", 1)
        LocalPlayer:SetAttribute("GameBumpPowerMultiplier", 1)
        LocalPlayer:SetAttribute("GameBlockPowerMultiplier", 1)
    end)
end

local function FullShutdown()
    RAGNAROK_ALIVE = false
    pcall(ClearHitboxes)
    pcall(function() Camera.FieldOfView = 70 end)
    pcall(stopAutoRotateMonitor)
    ResetAttributes()
    pcall(function() Ragnarok:Destroy() end)
    pcall(function() NotifyGui:Destroy() end)
end

local function CreateTBtn(text, pos, color, callback)
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
    b.MouseButton1Click:Connect(callback)
    b.MouseEnter:Connect(function() TweenService:Create(bs, TweenInfo.new(0.2), {Transparency = 0}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(bs, TweenInfo.new(0.2), {Transparency = 0.6}):Play() end)
end

CreateTBtn("SHUTDOWN SCRIPT", UDim2.new(0, 20, 0, 110), Color3.fromRGB(255, 70, 70), function()
    FullShutdown()
end)

CreateTBtn("MINIMIZE TO ICON", UDim2.new(0, 20, 0, 160), Color3.fromRGB(0, 191, 255), function()
    TerminationMenu.Visible = false
    Main.Visible = false
    if not Config.HideIcon then
        Icon.Visible = true
    end
end)

CreateTBtn("STEALTH MODE", UDim2.new(0, 20, 0, 210), Color3.fromRGB(200, 200, 200), function()
    FullShutdown()
end)

local TCancel = Instance.new("TextButton")
TCancel.Size = UDim2.new(0, 100, 0, 30)
TCancel.Position = UDim2.new(0.5, -50, 1, -35)
TCancel.BackgroundTransparency = 1
TCancel.Font = Enum.Font.GothamBold
TCancel.Text = "DISMISS"
TCancel.TextColor3 = Color3.fromRGB(100, 100, 100)
TCancel.TextSize = 12
TCancel.ZIndex = 5002
TCancel.Parent = TerminationMenu
TCancel.MouseButton1Click:Connect(function() TerminationMenu.Visible = false end)

local function CreateToggle(parent, name, configKey, callback)
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
        Config[configKey] = not Config[configKey]
        if configKey == "HitboxEnabled" and not Config[configKey] then ClearHitboxes() end
        TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 191, 255) or Color3.fromRGB(40, 40, 45)}):Play()
        TweenService:Create(ind, TweenInfo.new(0.2), {Position = Config[configKey] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
        Notify(name, Config[configKey])
        SaveConfig()
        if callback then callback(Config[configKey]) end
    end
    b.MouseButton1Click:Connect(Toggle)
    local binding = false
    bind.MouseButton1Click:Connect(function()
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

local function CreateSlider(parent, name, min, max, configKey, callback)
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
    fill.Size = UDim2.new(math.clamp((Config[configKey] - min) / (max - min), 0, 1), 0, 1, 0)
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
        if callback then callback(val) end
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true Update(i) end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

local function CreateKeybind(parent, name, configKey)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -30, 0, 42)
    f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -100, 1, 0)
    t.Position = UDim2.new(0, 15, 0, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamMedium
    t.Text = name
    t.TextColor3 = Color3.fromRGB(220, 220, 220)
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = f
    local bind = Instance.new("TextButton")
    bind.Size = UDim2.new(0, 80, 0, 26)
    bind.Position = UDim2.new(1, -95, 0.5, -13)
    bind.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    bind.Font = Enum.Font.GothamBold
    bind.Text = Config[configKey] or "NONE"
    bind.TextColor3 = Color3.fromRGB(0, 191, 255)
    bind.TextSize = 11
    bind.Parent = f
    Instance.new("UICorner", bind).CornerRadius = UDim.new(0, 4)
    local bs = Instance.new("UIStroke", bind)
    bs.Color = Color3.fromRGB(0, 191, 255)
    bs.Thickness = 1
    bs.Transparency = 0.6
    bind.MouseButton1Click:Connect(function()
        bind.Text = "..."
        local connection
        connection = UIS.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard then
                local k = i.KeyCode.Name
                if k == "Backspace" then
                    Config[configKey] = nil
                    bind.Text = "NONE"
                else
                    Config[configKey] = k
                    bind.Text = k
                end
                SaveConfig()
                connection:Disconnect()
            end
        end)
    end)
end

CreateCategory(MainPage, "Game", "7733993211")
CreateToggle(MainPage, "Hitbox Enabled", "HitboxEnabled")
CreateSlider(MainPage, "Hitbox Scale", 1.0, 20.5, "HitboxScale")

CreateCategory(MainPage, "Movement", "7743871002")
CreateToggle(MainPage, "Directional Jump", "DirectionalJump")
CreateToggle(MainPage, "Air Move", "AirMoveEnabled")
CreateSlider(MainPage, "Air Move Speed", 10, 100, "AirMoveSpeed")

CreateCategory(MiscPage, "Player", "7733715400")
CreateToggle(MiscPage, "Anti AFK", "AntiAFK")

CreateCategory(MiscPage, "Visuals", "7733978098")
CreateToggle(MiscPage, "Stretched Res", "StretchedRes")

CreateCategory(ExperimentalsPage, "Stat Changers", "7733715400")

CreateSlider(ExperimentalsPage, "Dive Speed", 0, 5, "DiveSpeed", function(val)
    pcall(function() LocalPlayer:SetAttribute("GameDiveSpeedMultiplier", val) end)
end)

CreateSlider(ExperimentalsPage, "Spike Power", 0, 500, "SpikePower", function(val)
    pcall(function() LocalPlayer:SetAttribute("GameSpikePowerMultiplier", val) end)
end)

CreateSlider(ExperimentalsPage, "Tilt Power", 0, 500, "TiltPower", function(val)
    pcall(function() LocalPlayer:SetAttribute("GameTiltPowerMultiplier", val) end)
end)

CreateSlider(ExperimentalsPage, "Speed", 0, 1.5, "SpeedMult", function(val)
    pcall(function() LocalPlayer:SetAttribute("GameSpeedMultiplier", val) end)
end)

CreateSlider(ExperimentalsPage, "Set Power", 0, 500, "SetPower", function(val)
    pcall(function() LocalPlayer:SetAttribute("GameSetPowerMultiplier", val) end)
end)

CreateSlider(ExperimentalsPage, "Serve Power", 0, 500, "ServePower", function(val)
    pcall(function() LocalPlayer:SetAttribute("GameServePowerMultiplier", val) end)
end)

CreateSlider(ExperimentalsPage, "Jump Power", 0, 5, "JumpPowerMult", function(val)
    pcall(function() LocalPlayer:SetAttribute("GameJumpPowerMultiplier", val) end)
end)

CreateSlider(ExperimentalsPage, "Bump Power", 0, 500, "BumpPower", function(val)
    pcall(function() LocalPlayer:SetAttribute("GameBumpPowerMultiplier", val) end)
end)

CreateSlider(ExperimentalsPage, "Block Power", 0, 500, "BlockPower", function(val)
    pcall(function() LocalPlayer:SetAttribute("GameBlockPowerMultiplier", val) end)
end)

CreateCategory(ExperimentalsPage, "Abilities", "7733978098")

CreateToggle(ExperimentalsPage, "Enable Rotate In The Air", "AutoRotateEnabled", function(state)
    if state then
        startAutoRotateMonitor()
    else
        stopAutoRotateMonitor()
    end
end)

CreateToggle(ExperimentalsPage, "Powerful Serve (Z)", "PowerfulServeEnabled")

CreateCategory(ConfigPage, "Keybinds", "7733993211")
CreateKeybind(ConfigPage, "Toggle UI", "ToggleUIKey")

CreateCategory(ConfigPage, "Interface", "7733978098")
CreateToggle(ConfigPage, "Hide Icon", "HideIcon", function(state)
    if state then
        Icon.Visible = false
    elseif not Main.Visible then
        Icon.Visible = true
    end
end)

local function CreateHitboxes(scale)
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local ball = model:FindFirstChild("Ball.001")
            if not ball then
                local ref = nil
                for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then ref = p break end end
                if ref then
                    ball = Instance.new("Part", model)
                    ball.Name = "Ball.001"
                    ball.Shape = Enum.PartType.Ball
                    ball.Size = Vector3.new(2, 2, 2) * scale
                    ball.CFrame = ref.CFrame
                    ball.Anchored = true
                    ball.CanCollide = false
                    ball.Transparency = 0.7
                    ball.Material = Enum.Material.ForceField
                    ball.Color = Color3.fromRGB(0, 191, 255)
                end
            else
                ball.Size = Vector3.new(2, 2, 2) * scale
            end
        end
    end
end

UIS.JumpRequest:Connect(function()
    if not RAGNAROK_ALIVE then return end
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

local antiAfkActive = false
RunService.Heartbeat:Connect(function()
    if not RAGNAROK_ALIVE then return end
    local char = LocalPlayer.Character
    if Config.AntiAFK and char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and not antiAfkActive then
            antiAfkActive = true
            task.spawn(function()
                local origin = hrp.Position
                while Config.AntiAFK and RAGNAROK_ALIVE do
                    task.wait(60)
                    if hrp then
                        hrp.Position = origin + Vector3.new(0, 0.1, 0)
                        task.wait(0.1)
                        hrp.Position = origin
                    end
                end
                antiAfkActive = false
            end)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not RAGNAROK_ALIVE then return end
    if Config.HitboxEnabled then
        CreateHitboxes(Config.HitboxScale)
    else
        ClearHitboxes()
    end
    Camera.FieldOfView = Config.StretchedRes and 110 or 70
    local char = LocalPlayer.Character
    if Config.AirMoveEnabled and char then
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
                local move = hum.MoveDirection
                if move.Magnitude > 0 then
                    hrp.Velocity = Vector3.new(move.X * Config.AirMoveSpeed, hrp.Velocity.Y, move.Z * Config.AirMoveSpeed)
                end
            end
        end
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if not RAGNAROK_ALIVE then return end
    if not gpe and input.KeyCode == Enum.KeyCode.Z and Config.PowerfulServeEnabled then
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local knit = rs.Packages._Index["sleitnick_knit@1.7.0"].knit
            local gs = knit.Services.GameService
            gs.RF.Serve:InvokeServer(Vector3.new(0, 0, 0), math.huge)
        end)
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if not RAGNAROK_ALIVE then return end
    if gpe then return end
    if Config.ToggleUIKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Config.ToggleUIKey then
        if Main.Visible then
            Main.Visible = false
            if not Config.HideIcon then
                Icon.Visible = true
            end
        else
            Main.Visible = true
            Main.BackgroundTransparency = 0
            Icon.Visible = false
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if not RAGNAROK_ALIVE then return end
    if Config.AutoRotateEnabled then
        stopAutoRotateMonitor()
        startAutoRotateMonitor()
    end
end)

pcall(function()
    if Config.DiveSpeed ~= 1 then LocalPlayer:SetAttribute("GameDiveSpeedMultiplier", Config.DiveSpeed) end
    if Config.SpikePower ~= 1 then LocalPlayer:SetAttribute("GameSpikePowerMultiplier", Config.SpikePower) end
    if Config.TiltPower ~= 1 then LocalPlayer:SetAttribute("GameTiltPowerMultiplier", Config.TiltPower) end
    if Config.SpeedMult ~= 1 then LocalPlayer:SetAttribute("GameSpeedMultiplier", Config.SpeedMult) end
    if Config.SetPower ~= 1 then LocalPlayer:SetAttribute("GameSetPowerMultiplier", Config.SetPower) end
    if Config.ServePower ~= 1 then LocalPlayer:SetAttribute("GameServePowerMultiplier", Config.ServePower) end
    if Config.JumpPowerMult ~= 1 then LocalPlayer:SetAttribute("GameJumpPowerMultiplier", Config.JumpPowerMult) end
    if Config.BumpPower ~= 1 then LocalPlayer:SetAttribute("GameBumpPowerMultiplier", Config.BumpPower) end
    if Config.BlockPower ~= 1 then LocalPlayer:SetAttribute("GameBlockPowerMultiplier", Config.BlockPower) end
end)

if Config.AutoRotateEnabled then
    startAutoRotateMonitor()
end

if getgenv then
    getgenv().RagnarokShutdown = FullShutdown
end
