local RAGNAROK_VERSION = "2.0.0"
local RAGNAROK_BUILD = "2026.08"
local RAGNAROK_ALIVE = true
local RAGNAROK_START = os.clock()

if getgenv then
    local environment = getgenv()
    if type(environment.RagnarokShutdown) == "function" then
        pcall(environment.RagnarokShutdown)
    end
    environment.RagnarokVersion = RAGNAROK_VERSION
end

local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local StatsService = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Connections = {}
local Buckets = {}
local Controllers = {}
local PageRegistry = {}
local PageButtons = {}
local ControlRegistry = {}
local HitboxRegistry = {}
local Baseline = {
    PlayerAttributes = {},
    CharacterAttributes = {},
    Character = nil,
    WalkSpeed = nil,
    JumpPower = nil,
    JumpHeight = nil,
    FieldOfView = 70,
}
local Runtime = {
    ActivePage = "dashboard",
    SearchQuery = "",
    NotificationQueue = {},
    ActiveNotifications = 0,
    PendingBinding = nil,
    Dragging = false,
    LastHitboxScan = 0,
    LastStatsApply = 0,
    LastMetricUpdate = 0,
    LastFovUpdate = 0,
    FrameRate = 60,
    AntiAfkRunning = false,
    ShutdownReason = nil,
    DashboardRefresh = nil,
    StatusLabel = nil,
    FooterLabel = nil,
    MetricLabels = {},
    FeatureLabels = {},
}

local function SafeCall(callback, ...)
    if type(callback) ~= "function" then
        return false, nil
    end
    return pcall(callback, ...)
end

local function SafeDestroy(instance)
    if instance and instance.Parent then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function Track(connection, bucket)
    if connection then
        table.insert(Connections, connection)
        if bucket then
            Buckets[bucket] = Buckets[bucket] or {}
            table.insert(Buckets[bucket], connection)
        end
    end
    return connection
end

local function Disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function DisconnectBucket(bucket)
    local list = Buckets[bucket]
    if not list then
        return
    end
    for _, connection in ipairs(list) do
        Disconnect(connection)
    end
    Buckets[bucket] = {}
end

local function DisconnectAll()
    for _, connection in ipairs(Connections) do
        Disconnect(connection)
    end
    Connections = {}
    Buckets = {}
end

local function Protect(instance)
    if gethui then
        local success = pcall(function()
            instance.Parent = gethui()
        end)
        if success then
            return instance
        end
    end
    if syn and syn.protect_gui then
        pcall(function()
            syn.protect_gui(instance)
        end)
    end
    instance.Parent = CoreGui
    return instance
end

local function RemovePreviousInstances()
    local containers = {CoreGui}
    if gethui then
        local success, result = pcall(gethui)
        if success and result then
            table.insert(containers, result)
        end
    end
    for _, container in ipairs(containers) do
        for _, child in ipairs(container:GetChildren()) do
            if child.Name == "RagnarokHub" or child.Name == "RagnarokNotify" or child.Name == "RagnarokIcon" then
                SafeDestroy(child)
            end
        end
    end
end

RemovePreviousInstances()

local ConfigDefaults = {
    ConfigVersion = 2,
    HitboxEnabled = true,
    HitboxScale = 6,
    HitboxTransparency = 0.72,
    HitboxColor = "Cyan",
    DirectionalJump = true,
    AirMoveEnabled = false,
    AirMoveSpeed = 15,
    AirMoveVertical = false,
    AntiAFK = false,
    StretchedRes = false,
    StretchedFOV = 110,
    NormalFOV = 70,
    AutoRotateEnabled = false,
    PowerfulServeEnabled = false,
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
    Notifications = true,
    NotificationDuration = 3,
    HideIcon = false,
    CompactMode = false,
    PerformanceMode = false,
    ShowMetrics = true,
    SaveOnChange = true,
    ToggleUIKey = "RightShift",
    ResetKey = "None",
    ServeKey = "Z",
    WindowPosition = {0.5, 0, 0.5, 0},
    IconPos = {1, -90, 1, -90},
    Binds = {},
}

local Config = {}
for key, value in pairs(ConfigDefaults) do
    if type(value) == "table" then
        Config[key] = {}
        for nestedKey, nestedValue in pairs(value) do
            Config[key][nestedKey] = nestedValue
        end
    else
        Config[key] = value
    end
end

local ConfigSchema = {
    HitboxEnabled = {kind = "boolean"},
    HitboxScale = {kind = "number", min = 1, max = 24},
    HitboxTransparency = {kind = "number", min = 0.1, max = 0.95},
    DirectionalJump = {kind = "boolean"},
    AirMoveEnabled = {kind = "boolean"},
    AirMoveSpeed = {kind = "number", min = 1, max = 120},
    AirMoveVertical = {kind = "boolean"},
    AntiAFK = {kind = "boolean"},
    StretchedRes = {kind = "boolean"},
    StretchedFOV = {kind = "number", min = 70, max = 130},
    NormalFOV = {kind = "number", min = 50, max = 120},
    AutoRotateEnabled = {kind = "boolean"},
    PowerfulServeEnabled = {kind = "boolean"},
    EnableStatChangers = {kind = "boolean"},
    DiveSpeed = {kind = "number", min = 0, max = 5},
    SpikePower = {kind = "number", min = 0, max = 500},
    TiltPower = {kind = "number", min = 0, max = 500},
    SpeedMult = {kind = "number", min = 0.25, max = 2},
    SetPower = {kind = "number", min = 0, max = 500},
    ServePower = {kind = "number", min = 0, max = 500},
    JumpPowerMult = {kind = "number", min = 0, max = 5},
    BumpPower = {kind = "number", min = 0, max = 500},
    BlockPower = {kind = "number", min = 0, max = 500},
    Notifications = {kind = "boolean"},
    NotificationDuration = {kind = "number", min = 1, max = 8},
    HideIcon = {kind = "boolean"},
    CompactMode = {kind = "boolean"},
    PerformanceMode = {kind = "boolean"},
    ShowMetrics = {kind = "boolean"},
    SaveOnChange = {kind = "boolean"},
    ToggleUIKey = {kind = "string"},
    ResetKey = {kind = "string"},
    ServeKey = {kind = "string"},
    HitboxColor = {kind = "string"},
}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = DeepCopy(nestedValue)
    end
    return copy
end

local function ClampNumber(value, minimum, maximum)
    local number = tonumber(value)
    if not number then
        return nil
    end
    return math.clamp(number, minimum, maximum)
end

local function NormalizeValue(key, value)
    local schema = ConfigSchema[key]
    if not schema then
        return nil
    end
    if schema.kind == "boolean" then
        return value == true
    end
    if schema.kind == "number" then
        local result = ClampNumber(value, schema.min, schema.max)
        return result
    end
    if schema.kind == "string" then
        if type(value) ~= "string" then
            return nil
        end
        return value
    end
    return nil
end

local function NormalizeConfig(data)
    if type(data) ~= "table" then
        return
    end
    for key, defaultValue in pairs(ConfigDefaults) do
        local value = data[key]
        if key == "Binds" then
            if type(value) == "table" then
                Config.Binds = {}
                for bindKey, bindValue in pairs(value) do
                    if type(bindKey) == "string" and type(bindValue) == "string" then
                        Config.Binds[bindKey] = bindValue
                    end
                end
            end
        elseif key == "IconPos" or key == "WindowPosition" then
            if type(value) == "table" then
                local position = {}
                for index = 1, 4 do
                    position[index] = tonumber(value[index]) or defaultValue[index]
                end
                Config[key] = position
            end
        else
            local normalized = NormalizeValue(key, value)
            if normalized ~= nil then
                Config[key] = normalized
            end
        end
    end
    Config.ConfigVersion = 2
end

local function GetConfigPath()
    return "RagnarokHub/v2/config.json"
end

local function EnsureConfigFolder()
    if not makefolder then
        return
    end
    if isfolder and not isfolder("RagnarokHub") then
        pcall(function()
            makefolder("RagnarokHub")
        end)
    end
    if isfolder and not isfolder("RagnarokHub/v2") then
        pcall(function()
            makefolder("RagnarokHub/v2")
        end)
    end
end

local function SaveConfig(silent)
    EnsureConfigFolder()
    if not writefile then
        return false
    end
    local payload = {
        ConfigVersion = 2,
        SavedAt = os.time(),
        Values = DeepCopy(Config),
    }
    local success = pcall(function()
        writefile(GetConfigPath(), HttpService:JSONEncode(payload))
    end)
    if success and not silent then
        return true
    end
    return success
end

local function LoadConfig(silent)
    if not isfile or not readfile or not isfile(GetConfigPath()) then
        return false
    end
    local success, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(GetConfigPath()))
    end)
    if not success or type(decoded) ~= "table" then
        return false
    end
    local values = decoded.Values or decoded
    NormalizeConfig(values)
    return true
end

local function ResetConfig(silent)
    for key, value in pairs(ConfigDefaults) do
        Config[key] = DeepCopy(value)
    end
    if not silent then
        SaveConfig(true)
    end
end

LoadConfig(true)

local Palette = {
    Background = Color3.fromRGB(7, 9, 13),
    Surface = Color3.fromRGB(12, 15, 21),
    SurfaceRaised = Color3.fromRGB(17, 21, 28),
    SurfaceHover = Color3.fromRGB(23, 29, 38),
    Border = Color3.fromRGB(38, 47, 60),
    BorderStrong = Color3.fromRGB(61, 77, 96),
    Text = Color3.fromRGB(239, 244, 249),
    TextMuted = Color3.fromRGB(148, 161, 177),
    TextDim = Color3.fromRGB(91, 105, 122),
    Accent = Color3.fromRGB(34, 211, 238),
    AccentStrong = Color3.fromRGB(8, 145, 178),
    AccentSoft = Color3.fromRGB(18, 57, 71),
    Success = Color3.fromRGB(52, 211, 153),
    Warning = Color3.fromRGB(251, 191, 36),
    Danger = Color3.fromRGB(248, 113, 113),
    Violet = Color3.fromRGB(167, 139, 250),
    White = Color3.fromRGB(255, 255, 255),
}

local function AccentColor()
    if Config.HitboxColor == "Violet" then
        return Palette.Violet
    end
    if Config.HitboxColor == "Green" then
        return Palette.Success
    end
    if Config.HitboxColor == "Amber" then
        return Palette.Warning
    end
    return Palette.Accent
end

local function CreateInstance(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        pcall(function()
            instance[property] = value
        end)
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function AddCorner(parent, radius)
    return CreateInstance("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

local function AddStroke(parent, color, thickness, transparency)
    return CreateInstance("UIStroke", {
        Color = color or Palette.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function AddPadding(parent, left, right, top, bottom)
    return CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function AddList(parent, padding, horizontal)
    return CreateInstance("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, parent)
end

local function AddGradient(parent, first, second, rotation)
    return CreateInstance("UIGradient", {
        Color = ColorSequence.new(first, second),
        Rotation = rotation or 0,
    }, parent)
end

local function Tween(instance, duration, properties, style, direction)
    if not instance then
        return nil
    end
    local animation = TweenService:Create(instance, TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    ), properties)
    animation:Play()
    return animation
end

local function SetText(instance, text)
    if instance then
        instance.Text = tostring(text or "")
    end
end

local function FormatNumber(value, decimals)
    local number = tonumber(value) or 0
    return string.format("%." .. tostring(decimals or 0) .. "f", number)
end

local function FormatPercent(value)
    return string.format("%d%%", math.floor((tonumber(value) or 0) * 100 + 0.5))
end

local function IsAlive()
    return RAGNAROK_ALIVE
end

local function GetCharacter()
    return LocalPlayer and LocalPlayer.Character or nil
end

local function GetHumanoid(character)
    local target = character or GetCharacter()
    return target and target:FindFirstChildOfClass("Humanoid") or nil
end

local function GetRoot(character)
    local target = character or GetCharacter()
    return target and target:FindFirstChild("HumanoidRootPart") or nil
end

local function GetCamera()
    return workspace.CurrentCamera
end

local function GetPlayerPing()
    local success, value = pcall(function()
        return LocalPlayer:GetNetworkPing() * 1000
    end)
    if success then
        return math.floor(value + 0.5)
    end
    return 0
end

local function GetMemoryUsage()
    local success, value = pcall(function()
        return StatsService:GetTotalMemoryUsageMb()
    end)
    if success then
        return math.floor(value + 0.5)
    end
    return 0
end

local function GetFps()
    return math.floor((Runtime.FrameRate or 0) + 0.5)
end

local function RegisterController(name, startCallback, stopCallback, refreshCallback)
    Controllers[name] = {
        Active = false,
        Start = startCallback,
        Stop = stopCallback,
        Refresh = refreshCallback,
    }
end

local function SetController(name, enabled)
    local controller = Controllers[name]
    if not controller then
        return false
    end
    local target = enabled == true
    if controller.Active == target then
        if controller.Refresh then
            SafeCall(controller.Refresh, target)
        end
        return true
    end
    controller.Active = target
    if target then
        SafeCall(controller.Start)
    else
        SafeCall(controller.Stop)
    end
    return true
end

local function IsControllerActive(name)
    local controller = Controllers[name]
    return controller and controller.Active == true or false
end

local function CountActiveControllers()
    local count = 0
    for _, controller in pairs(Controllers) do
        if controller.Active then
            count = count + 1
        end
    end
    return count
end

local function StatusColor(active)
    return active and Palette.Success or Palette.TextDim
end

local function CreateScreenGui(name, displayOrder)
    local gui = CreateInstance("ScreenGui", {
        Name = name,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = displayOrder or 10,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    Protect(gui)
    return gui
end

local NotifyGui = CreateScreenGui("RagnarokNotify", 1000)
local Ragnarok = CreateScreenGui("RagnarokHub", 100)
local NotificationLayer = CreateInstance("Frame", {
    Name = "NotificationLayer",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -24, 0, 24),
    Size = UDim2.new(0, 360, 0, 420),
    BackgroundTransparency = 1,
}, NotifyGui)
local NotificationLayout = AddList(NotificationLayer, 10, false)
NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

local function ProcessNotificationQueue()
    if not RAGNAROK_ALIVE or not Config.Notifications then
        Runtime.NotificationQueue = {}
        return
    end
    while #Runtime.NotificationQueue > 0 and Runtime.ActiveNotifications < 5 do
        local data = table.remove(Runtime.NotificationQueue, 1)
        Runtime.ActiveNotifications = Runtime.ActiveNotifications + 1
        local card = CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 72),
            BackgroundColor3 = Palette.SurfaceRaised,
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
        }, NotificationLayer)
        AddCorner(card, 10)
        local stroke = AddStroke(card, data.color or Palette.Accent, 1, 0.35)
        local rail = CreateInstance("Frame", {
            Size = UDim2.new(0, 3, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundColor3 = data.color or Palette.Accent,
            BorderSizePixel = 0,
        }, card)
        AddCorner(rail, 2)
        local title = CreateInstance("TextLabel", {
            Size = UDim2.new(1, -42, 0, 22),
            Position = UDim2.new(0, 24, 0, 12),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = data.title,
            TextColor3 = Palette.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        local body = CreateInstance("TextLabel", {
            Size = UDim2.new(1, -42, 0, 24),
            Position = UDim2.new(0, 24, 0, 36),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = data.body,
            TextColor3 = Palette.TextMuted,
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        card.Position = UDim2.new(1, 28, 0, 0)
        Tween(card, 0.32, {Position = UDim2.new(0, 0, 0, 0)})
        task.delay(data.duration or Config.NotificationDuration, function()
            if not card.Parent then
                return
            end
            Tween(card, 0.28, {Position = UDim2.new(1, 28, 0, 0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.wait(0.3)
            SafeDestroy(card)
            Runtime.ActiveNotifications = math.max(0, Runtime.ActiveNotifications - 1)
            ProcessNotificationQueue()
        end)
    end
end

local function Notify(title, body, kind, duration)
    if not Config.Notifications or not RAGNAROK_ALIVE then
        return
    end
    local colors = {
        success = Palette.Success,
        warning = Palette.Warning,
        danger = Palette.Danger,
        info = Palette.Accent,
        neutral = Palette.BorderStrong,
    }
    table.insert(Runtime.NotificationQueue, {
        title = tostring(title or "RAGNAROK"),
        body = tostring(body or ""),
        color = colors[kind or "info"] or Palette.Accent,
        duration = duration or Config.NotificationDuration,
    })
    ProcessNotificationQueue()
end

local Icon = CreateInstance("TextButton", {
    Name = "RagnarokIcon",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(Config.IconPos[1], Config.IconPos[2], Config.IconPos[3], Config.IconPos[4]),
    Size = UDim2.new(0, 56, 0, 56),
    BackgroundColor3 = Palette.Surface,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBlack,
    Text = "R",
    TextColor3 = Palette.Accent,
    TextSize = 26,
}, Ragnarok)
AddCorner(Icon, 16)
AddStroke(Icon, Palette.Accent, 1.5, 0.2)
AddGradient(Icon, Palette.SurfaceRaised, Palette.Background, 135)

local Shell = CreateInstance("Frame", {
    Name = "Shell",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 900, 0, 600),
    BackgroundColor3 = Palette.Background,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
}, Ragnarok)
AddCorner(Shell, 16)
local ShellStroke = AddStroke(Shell, Palette.BorderStrong, 1, 0.1)
AddGradient(Shell, Palette.Background, Palette.Surface, 45)
Shell.Position = UDim2.new(Config.WindowPosition[1], Config.WindowPosition[2], Config.WindowPosition[3], Config.WindowPosition[4])

local Header = CreateInstance("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 72),
    BackgroundColor3 = Palette.Surface,
    BorderSizePixel = 0,
}, Shell)
AddStroke(Header, Palette.Border, 1, 0.35)

local BrandMark = CreateInstance("Frame", {
    Size = UDim2.new(0, 38, 0, 38),
    Position = UDim2.new(0, 18, 0, 17),
    BackgroundColor3 = Palette.AccentSoft,
    BorderSizePixel = 0,
}, Header)
AddCorner(BrandMark, 11)
AddStroke(BrandMark, Palette.Accent, 1, 0.3)
local BrandLetter = CreateInstance("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    Text = "R",
    TextColor3 = Palette.Accent,
    TextSize = 21,
}, BrandMark)

local BrandTitle = CreateInstance("TextLabel", {
    Size = UDim2.new(0, 260, 0, 25),
    Position = UDim2.new(0, 68, 0, 13),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "RAGNAROK HUB",
    TextColor3 = Palette.Text,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)
local BrandSubtitle = CreateInstance("TextLabel", {
    Size = UDim2.new(0, 320, 0, 18),
    Position = UDim2.new(0, 68, 0, 38),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "CONTROL SYSTEM  /  V2.0",
    TextColor3 = Palette.TextDim,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local SearchBox = CreateInstance("TextBox", {
    Size = UDim2.new(0, 190, 0, 34),
    Position = UDim2.new(1, -312, 0, 19),
    BackgroundColor3 = Palette.SurfaceRaised,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.GothamMedium,
    PlaceholderText = "Search controls",
    PlaceholderColor3 = Palette.TextDim,
    Text = "",
    TextColor3 = Palette.Text,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)
AddCorner(SearchBox, 8)
AddStroke(SearchBox, Palette.Border, 1, 0.2)
AddPadding(SearchBox, 12, 8, 0, 0)

local HeaderStatus = CreateInstance("TextLabel", {
    Size = UDim2.new(0, 90, 0, 18),
    Position = UDim2.new(1, -410, 0, 27),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "● ONLINE",
    TextColor3 = Palette.Success,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
}, Header)

local MinimizeButton = CreateInstance("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -112, 0, 21),
    BackgroundColor3 = Palette.SurfaceRaised,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "—",
    TextColor3 = Palette.TextMuted,
    TextSize = 16,
}, Header)
AddCorner(MinimizeButton, 8)

local CloseButton = CreateInstance("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -72, 0, 21),
    BackgroundColor3 = Palette.SurfaceRaised,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "×",
    TextColor3 = Palette.Danger,
    TextSize = 18,
}, Header)
AddCorner(CloseButton, 8)

local Sidebar = CreateInstance("Frame", {
    Name = "Sidebar",
    Position = UDim2.new(0, 0, 0, 72),
    Size = UDim2.new(0, 196, 1, -72),
    BackgroundColor3 = Palette.Surface,
    BorderSizePixel = 0,
}, Shell)
AddStroke(Sidebar, Palette.Border, 1, 0.45)
AddPadding(Sidebar, 12, 12, 18, 14)
local SidebarList = AddList(Sidebar, 7, false)

local Content = CreateInstance("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 196, 0, 72),
    Size = UDim2.new(1, -196, 1, -72),
    BackgroundTransparency = 1,
}, Shell)

local Footer = CreateInstance("Frame", {
    Size = UDim2.new(1, -24, 0, 32),
    Position = UDim2.new(0, 12, 1, -44),
    BackgroundColor3 = Palette.Surface,
    BorderSizePixel = 0,
}, Content)
AddCorner(Footer, 8)
AddStroke(Footer, Palette.Border, 1, 0.5)
Runtime.FooterLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(1, -22, 1, 0),
    Position = UDim2.new(0, 11, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "RAGNAROK HUB  /  INITIALIZING",
    TextColor3 = Palette.TextDim,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Footer)

local ContentPages = CreateInstance("Frame", {
    Name = "ContentPages",
    Size = UDim2.new(1, -24, 1, -84),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
}, Content)

local function UpdateFooter(text)
    if Runtime.FooterLabel then
        Runtime.FooterLabel.Text = text
    end
end

local function SetHeaderStatus(text, color)
    HeaderStatus.Text = "● " .. tostring(text):upper()
    HeaderStatus.TextColor3 = color or Palette.Success
end

local function ApplyWindowPosition()
    if Config.WindowPosition and #Config.WindowPosition == 4 then
        Shell.Position = UDim2.new(Config.WindowPosition[1], Config.WindowPosition[2], Config.WindowPosition[3], Config.WindowPosition[4])
    end
end

local function SetShellVisible(visible)
    if visible then
        Shell.Visible = true
        Shell.BackgroundTransparency = 1
        Tween(Shell, 0.28, {BackgroundTransparency = 0})
    else
        Tween(Shell, 0.22, {BackgroundTransparency = 1}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.23, function()
            if not Runtime.Dragging and Shell then
                Shell.Visible = false
            end
        end)
    end
end

local function ToggleShell()
    local visible = not Shell.Visible
    SetShellVisible(visible)
    Icon.Visible = not visible and not Config.HideIcon
end

local function MakeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition
    Track(handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        Runtime.Dragging = true
        dragStart = input.Position
        startPosition = target.Position
        local endConnection
        endConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                Runtime.Dragging = false
                Config.WindowPosition = {
                    target.Position.X.Scale,
                    target.Position.X.Offset,
                    target.Position.Y.Scale,
                    target.Position.Y.Offset,
                }
                SaveConfig(true)
                Disconnect(endConnection)
            end
        end)
    end), "drag")
    Track(handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = dragStart or input.Position
        end
    end), "drag")
    Track(UIS.InputChanged:Connect(function(input)
        if not dragging or not dragStart then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end), "drag")
end

MakeDraggable(Header, Shell)
MakeDraggable(Icon, Icon)

Track(Icon.MouseButton1Click:Connect(function()
    SetShellVisible(true)
    Icon.Visible = false
end), "ui")

Track(MinimizeButton.MouseButton1Click:Connect(function()
    SetShellVisible(false)
    Icon.Visible = not Config.HideIcon
end), "ui")

local ConfirmOverlay = CreateInstance("Frame", {
    Name = "ConfirmOverlay",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.35,
    Visible = false,
    ZIndex = 50,
}, Ragnarok)
local ConfirmCard = CreateInstance("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 380, 0, 220),
    BackgroundColor3 = Palette.SurfaceRaised,
    BorderSizePixel = 0,
    ZIndex = 51,
}, ConfirmOverlay)
AddCorner(ConfirmCard, 14)
AddStroke(ConfirmCard, Palette.BorderStrong, 1.5, 0.1)
local ConfirmTitle = CreateInstance("TextLabel", {
    Size = UDim2.new(1, -40, 0, 28),
    Position = UDim2.new(0, 20, 0, 20),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "CONFIRM ACTION",
    TextColor3 = Palette.Text,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 52,
}, ConfirmCard)
local ConfirmBody = CreateInstance("TextLabel", {
    Size = UDim2.new(1, -40, 0, 62),
    Position = UDim2.new(0, 20, 0, 58),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "",
    TextColor3 = Palette.TextMuted,
    TextSize = 12,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 52,
}, ConfirmCard)
local ConfirmCancel = CreateInstance("TextButton", {
    Size = UDim2.new(0, 150, 0, 38),
    Position = UDim2.new(0, 20, 1, -56),
    BackgroundColor3 = Palette.Surface,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "CANCEL",
    TextColor3 = Palette.TextMuted,
    TextSize = 11,
    ZIndex = 52,
}, ConfirmCard)
AddCorner(ConfirmCancel, 8)
local ConfirmAccept = CreateInstance("TextButton", {
    Size = UDim2.new(0, 150, 0, 38),
    Position = UDim2.new(1, -170, 1, -56),
    BackgroundColor3 = Palette.AccentStrong,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "CONFIRM",
    TextColor3 = Palette.White,
    TextSize = 11,
    ZIndex = 52,
}, ConfirmCard)
AddCorner(ConfirmAccept, 8)
local PendingConfirm

local function AskConfirmation(title, body, callback)
    PendingConfirm = callback
    ConfirmTitle.Text = title
    ConfirmBody.Text = body
    ConfirmOverlay.Visible = true
end

Track(ConfirmCancel.MouseButton1Click:Connect(function()
    PendingConfirm = nil
    ConfirmOverlay.Visible = false
end), "ui")

Track(ConfirmAccept.MouseButton1Click:Connect(function()
    local callback = PendingConfirm
    PendingConfirm = nil
    ConfirmOverlay.Visible = false
    SafeCall(callback)
end), "ui")

local function CreatePage(id, title, subtitle)
    local page = CreateInstance("ScrollingFrame", {
        Name = id,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Palette.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, ContentPages)
    AddPadding(page, 4, 8, 4, 52)
    local list = AddList(page, 12, false)
    local pageHeader = CreateInstance("Frame", {
        Size = UDim2.new(1, -8, 0, 62),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    }, page)
    local pageTitle = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Palette.Text,
        TextSize = 23,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, pageHeader)
    local pageSubtitle = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 33),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = subtitle,
        TextColor3 = Palette.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, pageHeader)
    PageRegistry[id] = {
        Id = id,
        Page = page,
        Header = pageHeader,
        Title = pageTitle,
        Subtitle = pageSubtitle,
        List = list,
        Controls = {},
    }
    return page, PageRegistry[id]
end

local function CreateNavButton(id, label, glyph, order)
    local button = CreateInstance("TextButton", {
        Name = id .. "Nav",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "",
        LayoutOrder = order or 1,
    }, Sidebar)
    AddCorner(button, 9)
    local marker = CreateInstance("Frame", {
        Size = UDim2.new(0, 3, 0, 20),
        Position = UDim2.new(0, 0, 0.5, -10),
        BackgroundColor3 = Palette.Accent,
        BorderSizePixel = 0,
        Visible = false,
    }, button)
    AddCorner(marker, 2)
    local icon = CreateInstance("TextLabel", {
        Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = glyph,
        TextColor3 = Palette.TextDim,
        TextSize = 15,
    }, button)
    local text = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -54, 1, 0),
        Position = UDim2.new(0, 46, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = label,
        TextColor3 = Palette.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)
    PageButtons[id] = {Button = button, Marker = marker, Icon = icon, Text = text}
    Track(button.MouseButton1Click:Connect(function()
        if PageRegistry[id] then
            Runtime.ActivePage = id
            for pageId, pageData in pairs(PageRegistry) do
                local active = pageId == id
                pageData.Page.Visible = active
                local nav = PageButtons[pageId]
                if nav then
                    nav.Marker.Visible = active
                    nav.Button.BackgroundColor3 = active and Palette.AccentSoft or Palette.Surface
                    nav.Icon.TextColor3 = active and Palette.Accent or Palette.TextDim
                    nav.Text.TextColor3 = active and Palette.Text or Palette.TextMuted
                end
            end
            UpdateFooter("RAGNAROK HUB  /  " .. label:upper() .. "  /  READY")
        end
    end), "ui")
    Track(button.MouseEnter:Connect(function()
        if Runtime.ActivePage ~= id then
            Tween(button, 0.15, {BackgroundColor3 = Palette.SurfaceHover})
        end
    end), "ui")
    Track(button.MouseLeave:Connect(function()
        if Runtime.ActivePage ~= id then
            Tween(button, 0.15, {BackgroundColor3 = Palette.Surface})
        end
    end), "ui")
    return button
end

CreateNavButton("dashboard", "Dashboard", "⌂", 1)
CreateNavButton("gameplay", "Gameplay", "◈", 2)
CreateNavButton("movement", "Movement", "↯", 3)
CreateNavButton("visuals", "Visuals", "◉", 4)
CreateNavButton("experimental", "Experimental", "◇", 5)
CreateNavButton("utilities", "Utilities", "▣", 6)
CreateNavButton("settings", "Settings", "⚙", 7)

local SidebarDivider = CreateInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = Palette.Border,
    BorderSizePixel = 0,
    LayoutOrder = 8,
}, Sidebar)
local SidebarVersion = CreateInstance("TextLabel", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "BUILD " .. RAGNAROK_BUILD .. "\nSTABLE RELEASE",
    TextColor3 = Palette.TextDim,
    TextSize = 9,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    LayoutOrder = 9,
}, Sidebar)

local function CreateSection(parent, title, description, order)
    local section = CreateInstance("Frame", {
        Size = UDim2.new(1, -8, 0, 38),
        BackgroundTransparency = 1,
        LayoutOrder = order or 1,
    }, parent)
    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title:upper(),
        TextColor3 = Palette.Accent,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, section)
    local detail = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = description or "",
        TextColor3 = Palette.TextDim,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, section)
    return section
end

local function CreateCard(parent, height, order)
    local card = CreateInstance("Frame", {
        Size = UDim2.new(1, -8, 0, height or 100),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        LayoutOrder = order or 1,
    }, parent)
    AddCorner(card, 11)
    AddStroke(card, Palette.Border, 1, 0.3)
    return card
end

local function CreateRow(parent, height, order)
    local row = CreateInstance("Frame", {
        Size = UDim2.new(1, -28, 0, height or 44),
        BackgroundColor3 = Palette.SurfaceRaised,
        BorderSizePixel = 0,
        LayoutOrder = order or 1,
    }, parent)
    AddCorner(row, 8)
    return row
end

local function CreateLabel(parent, text, size, position, color, font, textSize, order)
    return CreateInstance("TextLabel", {
        Size = size or UDim2.new(1, 0, 1, 0),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = font or Enum.Font.GothamMedium,
        Text = text or "",
        TextColor3 = color or Palette.Text,
        TextSize = textSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order or 1,
    }, parent)
end

local function RegisterControl(key, control)
    ControlRegistry[key] = control
    return control
end

local function FireControlChanged(key, value)
    local control = ControlRegistry[key]
    if control and control.OnChanged then
        SafeCall(control.OnChanged, value)
    end
    if Config.SaveOnChange then
        SaveConfig(true)
    end
end

local function CreateToggle(parent, label, description, key, callback, order)
    local row = CreateRow(parent, description and 62 or 46, order)
    local title = CreateLabel(row, label, UDim2.new(1, -112, 0, 20), UDim2.new(0, 14, 0, description and 10 or 13), Palette.Text, Enum.Font.GothamBold, 12)
    local detail
    if description then
        detail = CreateLabel(row, description, UDim2.new(1, -112, 0, 18), UDim2.new(0, 14, 0, 32), Palette.TextDim, Enum.Font.GothamMedium, 10)
    end
    local switch = CreateInstance("TextButton", {
        Size = UDim2.new(0, 42, 0, 22),
        Position = UDim2.new(1, -58, 0.5, -11),
        BackgroundColor3 = Config[key] and Palette.AccentStrong or Palette.Border,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, row)
    AddCorner(switch, 11)
    local knob = CreateInstance("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = Config[key] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Palette.White,
        BorderSizePixel = 0,
    }, switch)
    AddCorner(knob, 8)
    local function Refresh(value)
        local active = value == true
        Tween(switch, 0.16, {BackgroundColor3 = active and Palette.AccentStrong or Palette.Border})
        Tween(knob, 0.16, {Position = active and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
        title.TextColor3 = active and Palette.Text or Palette.TextMuted
    end
    row:SetAttribute("SearchText", string.lower(label .. " " .. tostring(description or "") .. " " .. key))
    local control = RegisterControl(key, {
        Row = row,
        SearchText = string.lower(label .. " " .. tostring(description or "") .. " " .. key),
        Refresh = Refresh,
        OnChanged = callback,
    })
    Track(switch.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        Refresh(Config[key])
        FireControlChanged(key, Config[key])
        Notify(label, Config[key] and "Enabled" or "Disabled", Config[key] and "success" or "neutral")
    end), "controls")
    Refresh(Config[key])
    return control
end

local function CreateSlider(parent, label, description, key, minimum, maximum, step, callback, order)
    local row = CreateRow(parent, description and 76 or 60, order)
    local title = CreateLabel(row, label, UDim2.new(1, -100, 0, 18), UDim2.new(0, 14, 0, 9), Palette.Text, Enum.Font.GothamBold, 12)
    local valueLabel = CreateLabel(row, FormatNumber(Config[key], step and step < 1 and 1 or 0), UDim2.new(0, 72, 0, 18), UDim2.new(1, -88, 0, 9), Palette.Accent, Enum.Font.GothamBold, 11)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    local detail
    if description then
        detail = CreateLabel(row, description, UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 28), Palette.TextDim, Enum.Font.GothamMedium, 10)
    end
    local trackY = description and 53 or 38
    local track = CreateInstance("Frame", {
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 0, trackY),
        BackgroundColor3 = Palette.Border,
        BorderSizePixel = 0,
        Active = true,
    }, row)
    AddCorner(track, 3)
    local initial = math.clamp((tonumber(Config[key]) or minimum - minimum) - minimum, 0, maximum - minimum) / (maximum - minimum)
    local fill = CreateInstance("Frame", {
        Size = UDim2.new(initial, 0, 1, 0),
        BackgroundColor3 = Palette.Accent,
        BorderSizePixel = 0,
    }, track)
    AddCorner(fill, 3)
    local thumb = CreateInstance("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(initial, 0, 0.5, 0),
        BackgroundColor3 = Palette.White,
        BorderSizePixel = 0,
    }, track)
    AddCorner(thumb, 6)
    local dragging = false
    local function Snap(value)
        local increment = step or 0.1
        return math.clamp(math.floor((value / increment) + 0.5) * increment, minimum, maximum)
    end
    local function SetValue(value, emit)
        local current = Snap(tonumber(value) or minimum)
        local alpha = math.clamp((current - minimum) / (maximum - minimum), 0, 1)
        Config[key] = current
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = step and step < 1 and FormatNumber(current, 1) or FormatNumber(current, 0)
        if emit then
            FireControlChanged(key, current)
        end
    end
    local function UpdateFromInput(input)
        local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        SetValue(minimum + (maximum - minimum) * alpha, true)
        if callback then
            SafeCall(callback, Config[key])
        end
    end
    Track(track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateFromInput(input)
        end
    end), "controls")
    Track(UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFromInput(input)
        end
    end), "controls")
    Track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end), "controls")
    row:SetAttribute("SearchText", string.lower(label .. " " .. tostring(description or "") .. " " .. key))
    local control = RegisterControl(key, {
        Row = row,
        SearchText = string.lower(label .. " " .. tostring(description or "") .. " " .. key),
        Refresh = function(value)
            SetValue(value, false)
        end,
        OnChanged = callback,
    })
    SetValue(Config[key], false)
    return control
end

local function CreateKeybind(parent, label, description, key, callback, order)
    local row = CreateRow(parent, description and 62 or 46, order)
    local title = CreateLabel(row, label, UDim2.new(1, -130, 0, 20), UDim2.new(0, 14, 0, description and 10 or 13), Palette.Text, Enum.Font.GothamBold, 12)
    if description then
        CreateLabel(row, description, UDim2.new(1, -130, 0, 18), UDim2.new(0, 14, 0, 32), Palette.TextDim, Enum.Font.GothamMedium, 10)
    end
    local button = CreateInstance("TextButton", {
        Size = UDim2.new(0, 96, 0, 28),
        Position = UDim2.new(1, -110, 0.5, -14),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = Config[key] or "NONE",
        TextColor3 = Palette.Accent,
        TextSize = 10,
    }, row)
    AddCorner(button, 7)
    AddStroke(button, Palette.BorderStrong, 1, 0.25)
    local listening = false
    local function Refresh(value)
        button.Text = value or "NONE"
        button.TextColor3 = value and value ~= "None" and Palette.Accent or Palette.TextDim
    end
    row:SetAttribute("SearchText", string.lower(label .. " " .. tostring(description or "") .. " " .. key))
    local control = RegisterControl(key, {Row = row, SearchText = string.lower(label .. " " .. tostring(description or "") .. " " .. key), Refresh = Refresh, OnChanged = callback})
    Track(button.MouseButton1Click:Connect(function()
        if listening then
            return
        end
        listening = true
        Runtime.PendingBinding = key
        button.Text = "PRESS KEY"
        button.TextColor3 = Palette.Warning
        local connection
        connection = UIS.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            local name = input.KeyCode.Name
            if name == "Backspace" or name == "Escape" then
                Config[key] = "None"
            else
                Config[key] = name
            end
            listening = false
            Runtime.PendingBinding = nil
            Refresh(Config[key])
            FireControlChanged(key, Config[key])
            Disconnect(connection)
        end)
    end), "controls")
    Refresh(Config[key])
    return control
end

local function CreateAction(parent, label, description, actionText, callback, order, accent)
    local row = CreateRow(parent, description and 62 or 46, order)
    CreateLabel(row, label, UDim2.new(1, -140, 0, 20), UDim2.new(0, 14, 0, description and 10 or 13), Palette.Text, Enum.Font.GothamBold, 12)
    if description then
        CreateLabel(row, description, UDim2.new(1, -140, 0, 18), UDim2.new(0, 14, 0, 32), Palette.TextDim, Enum.Font.GothamMedium, 10)
    end
    local button = CreateInstance("TextButton", {
        Size = UDim2.new(0, 112, 0, 28),
        Position = UDim2.new(1, -126, 0.5, -14),
        BackgroundColor3 = accent or Palette.AccentStrong,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = actionText,
        TextColor3 = Palette.White,
        TextSize = 10,
    }, row)
    AddCorner(button, 7)
    Track(button.MouseButton1Click:Connect(function()
        SafeCall(callback)
    end), "controls")
    Track(button.MouseEnter:Connect(function()
        Tween(button, 0.14, {BackgroundColor3 = Palette.Accent})
    end), "controls")
    Track(button.MouseLeave:Connect(function()
        Tween(button, 0.14, {BackgroundColor3 = accent or Palette.AccentStrong})
    end), "controls")
    return row
end

local function CreateSelect(parent, label, description, key, values, callback, order)
    local row = CreateRow(parent, description and 62 or 46, order)
    CreateLabel(row, label, UDim2.new(1, -150, 0, 20), UDim2.new(0, 14, 0, description and 10 or 13), Palette.Text, Enum.Font.GothamBold, 12)
    if description then
        CreateLabel(row, description, UDim2.new(1, -150, 0, 18), UDim2.new(0, 14, 0, 32), Palette.TextDim, Enum.Font.GothamMedium, 10)
    end
    local button = CreateInstance("TextButton", {
        Size = UDim2.new(0, 122, 0, 28),
        Position = UDim2.new(1, -136, 0.5, -14),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = tostring(Config[key]),
        TextColor3 = Palette.Accent,
        TextSize = 10,
    }, row)
    AddCorner(button, 7)
    AddStroke(button, Palette.BorderStrong, 1, 0.25)
    local index = 1
    for position, value in ipairs(values) do
        if value == Config[key] then
            index = position
            break
        end
    end
    local function Refresh(value)
        button.Text = tostring(value)
    end
    row:SetAttribute("SearchText", string.lower(label .. " " .. tostring(description or "") .. " " .. key))
    RegisterControl(key, {Row = row, SearchText = string.lower(label .. " " .. tostring(description or "") .. " " .. key), Refresh = Refresh, OnChanged = callback})
    Track(button.MouseButton1Click:Connect(function()
        index = index % #values + 1
        Config[key] = values[index]
        Refresh(Config[key])
        FireControlChanged(key, Config[key])
        if callback then
            SafeCall(callback, Config[key])
        end
    end), "controls")
    return row
end

local function CreateMetric(parent, label, value, position, width)
    local card = CreateInstance("Frame", {
        Size = UDim2.new(0, width or 150, 1, 0),
        Position = position,
        BackgroundColor3 = Palette.SurfaceRaised,
        BorderSizePixel = 0,
    }, parent)
    AddCorner(card, 9)
    AddStroke(card, Palette.Border, 1, 0.35)
    CreateLabel(card, label:upper(), UDim2.new(1, -20, 0, 16), UDim2.new(0, 10, 0, 9), Palette.TextDim, Enum.Font.GothamBold, 9)
    local valueLabel = CreateLabel(card, value, UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 29), Palette.Text, Enum.Font.GothamBold, 20)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    Runtime.MetricLabels[label] = valueLabel
    return card
end

local function CreateFeatureStatus(parent, key, label, order)
    local row = CreateInstance("Frame", {
        Size = UDim2.new(1, -22, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder = order or 1,
    }, parent)
    local dot = CreateInstance("Frame", {
        Size = UDim2.new(0, 7, 0, 7),
        Position = UDim2.new(0, 2, 0.5, -3),
        BackgroundColor3 = StatusColor(IsControllerActive(key)),
        BorderSizePixel = 0,
    }, row)
    AddCorner(dot, 4)
    local labelObject = CreateLabel(row, label, UDim2.new(1, -30, 1, 0), UDim2.new(0, 18, 0, 0), Palette.TextMuted, Enum.Font.GothamMedium, 11)
    Runtime.FeatureLabels[key] = Runtime.FeatureLabels[key] or {}
    table.insert(Runtime.FeatureLabels[key], {Dot = dot, Label = labelObject})
    return row
end

local DashboardPage, DashboardMeta = CreatePage("dashboard", "Dashboard", "Estado operativo, métricas y acceso rápido.")
local GameplayPage, GameplayMeta = CreatePage("gameplay", "Gameplay", "Controles de interacción y asistencia de partida.")
local MovementPage, MovementMeta = CreatePage("movement", "Movement", "Movimiento aéreo, salto direccional y rotación.")
local VisualsPage, VisualsMeta = CreatePage("visuals", "Visuals", "Lectura espacial, escala y presentación visual.")
local ExperimentalPage, ExperimentalMeta = CreatePage("experimental", "Experimental", "Parámetros avanzados con aplicación controlada.")
local UtilitiesPage, UtilitiesMeta = CreatePage("utilities", "Utilities", "Persistencia, diagnóstico y mantenimiento.")
local SettingsPage, SettingsMeta = CreatePage("settings", "Settings", "Preferencias de interfaz, atajos y configuración.")

local DashboardMetrics = CreateInstance("Frame", {
    Size = UDim2.new(1, -8, 0, 88),
    BackgroundTransparency = 1,
    LayoutOrder = 2,
}, DashboardPage)
CreateMetric(DashboardMetrics, "FPS", "0", UDim2.new(0, 0, 0, 0), 144)
CreateMetric(DashboardMetrics, "Ping", "0 ms", UDim2.new(0, 154, 0, 0), 144)
CreateMetric(DashboardMetrics, "Memory", "0 MB", UDim2.new(0, 308, 0, 0), 144)
CreateMetric(DashboardMetrics, "Features", "0", UDim2.new(0, 462, 0, 0), 144)

local DashboardLeft = CreateCard(DashboardPage, 238, 3)
CreateLabel(DashboardLeft, "SYSTEM OVERVIEW", UDim2.new(1, -32, 0, 24), UDim2.new(0, 16, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(DashboardLeft, "Runtime state and active controllers", UDim2.new(1, -32, 0, 18), UDim2.new(0, 16, 0, 38), Palette.TextDim, Enum.Font.GothamMedium, 10)
local FeatureList = CreateInstance("Frame", {
    Size = UDim2.new(0.5, -20, 0, 154),
    Position = UDim2.new(0, 16, 0, 68),
    BackgroundTransparency = 1,
}, DashboardLeft)
AddList(FeatureList, 1, false)
CreateFeatureStatus(FeatureList, "hitbox", "Hitbox renderer", 1)
CreateFeatureStatus(FeatureList, "movement", "Movement controller", 2)
CreateFeatureStatus(FeatureList, "stats", "Stat synchronization", 3)
CreateFeatureStatus(FeatureList, "visuals", "Visual pipeline", 4)
CreateFeatureStatus(FeatureList, "utilities", "Utility services", 5)
local DashboardRuntime = CreateInstance("Frame", {
    Size = UDim2.new(0.5, -20, 0, 154),
    Position = UDim2.new(0.5, 4, 0, 68),
    BackgroundColor3 = Palette.SurfaceRaised,
    BorderSizePixel = 0,
}, DashboardLeft)
AddCorner(DashboardRuntime, 9)
CreateLabel(DashboardRuntime, "RUNTIME", UDim2.new(1, -24, 0, 16), UDim2.new(0, 12, 0, 11), Palette.TextDim, Enum.Font.GothamBold, 9)
Runtime.StatusLabel = CreateLabel(DashboardRuntime, "BOOTING", UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, 33), Palette.Success, Enum.Font.GothamBold, 18)
CreateLabel(DashboardRuntime, "Version", UDim2.new(0.45, 0, 0, 18), UDim2.new(0, 12, 0, 72), Palette.TextDim, Enum.Font.GothamMedium, 10)
local RuntimeVersion = CreateLabel(DashboardRuntime, RAGNAROK_VERSION, UDim2.new(0.5, -12, 0, 18), UDim2.new(0.5, 0, 0, 72), Palette.Text, Enum.Font.GothamBold, 10)
RuntimeVersion.TextXAlignment = Enum.TextXAlignment.Right
CreateLabel(DashboardRuntime, "Uptime", UDim2.new(0.45, 0, 0, 18), UDim2.new(0, 12, 0, 96), Palette.TextDim, Enum.Font.GothamMedium, 10)
local RuntimeUptime = CreateLabel(DashboardRuntime, "00:00:00", UDim2.new(0.5, -12, 0, 18), UDim2.new(0.5, 0, 0, 96), Palette.Text, Enum.Font.GothamBold, 10)
RuntimeUptime.TextXAlignment = Enum.TextXAlignment.Right
CreateLabel(DashboardRuntime, "Profile", UDim2.new(0.45, 0, 0, 18), UDim2.new(0, 12, 0, 120), Palette.TextDim, Enum.Font.GothamMedium, 10)
local RuntimeProfile = CreateLabel(DashboardRuntime, "DEFAULT", UDim2.new(0.5, -12, 0, 18), UDim2.new(0.5, 0, 0, 120), Palette.Text, Enum.Font.GothamBold, 10)
RuntimeProfile.TextXAlignment = Enum.TextXAlignment.Right

local DashboardActions = CreateCard(DashboardPage, 198, 4)
CreateLabel(DashboardActions, "QUICK ACTIONS", UDim2.new(1, -32, 0, 24), UDim2.new(0, 16, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
local DashboardActionsBody = CreatePanelBody(DashboardActions, 48, 10)
CreateAction(DashboardActionsBody, "Save configuration", "Persist the current runtime profile.", "SAVE", function()
    if SaveConfig(false) then
        Notify("Configuration", "Saved to the v2 profile.", "success")
    else
        Notify("Configuration", "File persistence is unavailable.", "warning")
    end
end, 1)
CreateAction(DashboardActionsBody, "Restore defaults", "Reset every option to the v2 baseline.", "RESET", function()
    AskConfirmation("RESET PROFILE", "All current values will be replaced by the v2 baseline.", function()
        ResetConfig(false)
        for key, control in pairs(ControlRegistry) do
            if control.Refresh and Config[key] ~= nil then
                SafeCall(control.Refresh, Config[key])
            end
        end
        Notify("Configuration", "Baseline restored.", "success")
    end)
end, 2, Palette.BorderStrong)

local function UpdateMetric(label, value)
    local object = Runtime.MetricLabels[label]
    if object then
        object.Text = tostring(value)
    end
end

local function UpdateFeatureStatus(key, active)
    local statuses = Runtime.FeatureLabels[key]
    if not statuses then
        return
    end
    for _, status in ipairs(statuses) do
        status.Dot.BackgroundColor3 = StatusColor(active)
        status.Label.TextColor3 = active and Palette.Text or Palette.TextMuted
    end
end

local function UpdateDashboard()
    UpdateMetric("FPS", GetFps())
    UpdateMetric("Ping", tostring(GetPlayerPing()) .. " ms")
    UpdateMetric("Memory", tostring(GetMemoryUsage()) .. " MB")
    UpdateMetric("Features", tostring(CountActiveControllers()))
    for key in pairs(Runtime.FeatureLabels) do
        UpdateFeatureStatus(key, IsControllerActive(key))
    end
    if Runtime.StatusLabel then
        Runtime.StatusLabel.Text = RAGNAROK_ALIVE and "OPERATIONAL" or "STOPPED"
        Runtime.StatusLabel.TextColor3 = RAGNAROK_ALIVE and Palette.Success or Palette.Danger
    end
    local elapsed = math.max(0, os.clock() - RAGNAROK_START)
    local seconds = math.floor(elapsed)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainder = seconds % 60
    RuntimeUptime.Text = string.format("%02d:%02d:%02d", hours, minutes, remainder)
end

Runtime.DashboardRefresh = UpdateDashboard
local function CreatePanelBody(card, top, bottom)
    local body = CreateInstance("Frame", {
        Size = UDim2.new(1, -28, 1, -(top or 54) - (bottom or 12)),
        Position = UDim2.new(0, 14, 0, top or 54),
        BackgroundTransparency = 1,
    }, card)
    AddList(body, 8, false)
    AddPadding(body, 0, 0, 0, 0)
    return body
end

local function FindBallModels()
    local models = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child.Name:match("^CLIENT_BALL_%d+$") then
            table.insert(models, child)
        end
    end
    return models
end

local function FindBallReference(model)
    local named = model:FindFirstChild("Ball.001")
    if named and named:IsA("BasePart") and not HitboxRegistry[named] then
        return named
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "Ball.001" then
            return descendant
        end
    end
    return nil
end

local function RemoveHitbox(model)
    local existing = model and model:FindFirstChild("RagnarokHitbox")
    if existing then
        HitboxRegistry[existing] = nil
        SafeDestroy(existing)
    end
end

local function ClearHitboxes()
    for _, model in ipairs(FindBallModels()) do
        RemoveHitbox(model)
    end
    HitboxRegistry = {}
end

local function ApplyHitbox(model, scale)
    if not model or not model.Parent then
        return
    end
    local reference = FindBallReference(model)
    if not reference then
        return
    end
    local hitbox = model:FindFirstChild("RagnarokHitbox")
    if not hitbox then
        hitbox = CreateInstance("Part", {
            Name = "RagnarokHitbox",
            Shape = Enum.PartType.Ball,
            Anchored = true,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
            CastShadow = false,
            Material = Enum.Material.ForceField,
            Transparency = Config.HitboxTransparency,
            Color = AccentColor(),
            Size = Vector3.new(scale, scale, scale),
            CFrame = reference.CFrame,
        }, model)
        HitboxRegistry[hitbox] = model
    else
        hitbox.Size = Vector3.new(scale, scale, scale)
        hitbox.Transparency = Config.HitboxTransparency
        hitbox.Color = AccentColor()
        hitbox.CFrame = reference.CFrame
    end
end

local function RefreshHitboxes(force)
    if not IsAlive() then
        return
    end
    local now = os.clock()
    if not force and now - Runtime.LastHitboxScan < (Config.PerformanceMode and 0.14 or 0.06) then
        return
    end
    Runtime.LastHitboxScan = now
    if not Config.HitboxEnabled then
        ClearHitboxes()
        return
    end
    for _, model in ipairs(FindBallModels()) do
        ApplyHitbox(model, Config.HitboxScale)
    end
    for hitbox, model in pairs(HitboxRegistry) do
        if not hitbox.Parent or not model or not model.Parent then
            HitboxRegistry[hitbox] = nil
        end
    end
end

local StatAttrNames = {
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

local function CaptureBaseline()
    local player = LocalPlayer
    if not player then
        return
    end
    for _, attributeName in pairs(StatAttrNames) do
        if Baseline.PlayerAttributes[attributeName] == nil then
            Baseline.PlayerAttributes[attributeName] = player:GetAttribute(attributeName)
        end
    end
    local character = GetCharacter()
    if not character or Baseline.Character == character then
        return
    end
    local humanoid = GetHumanoid(character)
    if humanoid then
        Baseline.WalkSpeed = humanoid.WalkSpeed
        Baseline.JumpPower = humanoid.JumpPower
        Baseline.JumpHeight = humanoid.JumpHeight
        Baseline.Character = character
    end
    Baseline.CharacterAttributes = {}
    for _, attributeName in pairs(StatAttrNames) do
        Baseline.CharacterAttributes[attributeName] = character:GetAttribute(attributeName)
    end
end

local function SetAttributeSafe(instance, attributeName, value)
    if not instance then
        return
    end
    pcall(function()
        instance:SetAttribute(attributeName, value)
    end)
end

local function ApplyAttributeToScope(attributeName, value)
    SetAttributeSafe(LocalPlayer, attributeName, value)
    local character = GetCharacter()
    if character then
        SetAttributeSafe(character, attributeName, value)
        local humanoid = GetHumanoid(character)
        if humanoid then
            SetAttributeSafe(humanoid, attributeName, value)
        end
    end
end

local function ResetCharacterMovement()
    local humanoid = GetHumanoid()
    if not humanoid then
        return
    end
    if Baseline.WalkSpeed then
        pcall(function()
            humanoid.WalkSpeed = Baseline.WalkSpeed
        end)
    end
    if Baseline.JumpPower then
        pcall(function()
            humanoid.JumpPower = Baseline.JumpPower
        end)
    end
    if Baseline.JumpHeight then
        pcall(function()
            humanoid.JumpHeight = Baseline.JumpHeight
        end)
    end
end

local function ResetAttributes()
    for _, attributeName in pairs(StatAttrNames) do
        local playerValue = Baseline.PlayerAttributes[attributeName]
        ApplyAttributeToScope(attributeName, playerValue)
    end
    ResetCharacterMovement()
end

local function ApplyStats()
    if not Config.EnableStatChangers then
        ResetAttributes()
        return
    end
    CaptureBaseline()
    for key, attributeName in pairs(StatAttrNames) do
        local value = tonumber(Config[key])
        if value then
            ApplyAttributeToScope(attributeName, value)
        end
    end
    local humanoid = GetHumanoid()
    if humanoid then
        local baseWalkSpeed = Baseline.WalkSpeed or 16
        local baseJumpPower = Baseline.JumpPower or 50
        local baseJumpHeight = Baseline.JumpHeight or 7.2
        pcall(function()
            humanoid.WalkSpeed = baseWalkSpeed * (Config.SpeedMult or 1)
            humanoid.JumpPower = baseJumpPower * (Config.JumpPowerMult or 1)
            humanoid.JumpHeight = baseJumpHeight * (Config.JumpPowerMult or 1)
        end)
    end
end

local function RefreshStatHooks()
    DisconnectBucket("attribute-hooks")
    if not Config.EnableStatChangers then
        return
    end
    for key, attributeName in pairs(StatAttrNames) do
        local expected = Config[key]
        Track(LocalPlayer:GetAttributeChangedSignal(attributeName):Connect(function()
            if not IsAlive() or not Config.EnableStatChangers then
                return
            end
            local current = LocalPlayer:GetAttribute(attributeName)
            if current ~= expected then
                SetAttributeSafe(LocalPlayer, attributeName, expected)
            end
        end), "attribute-hooks")
    end
end

local function SetCameraFov()
    local camera = GetCamera()
    if not camera then
        return
    end
    local desired = Config.StretchedRes and Config.StretchedFOV or Config.NormalFOV
    if camera.FieldOfView ~= desired then
        camera.FieldOfView = desired
    end
end

local function SetAutoRotate(enabled)
    local humanoid = GetHumanoid()
    if humanoid and enabled then
        humanoid.AutoRotate = true
    end
end

local function FaceCameraDirection()
    local character = GetCharacter()
    local humanoid = GetHumanoid(character)
    local root = GetRoot(character)
    local camera = GetCamera()
    if not humanoid or not root or not camera or not Config.DirectionalJump then
        return
    end
    local direction = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
    if direction.Magnitude <= 0.01 then
        return
    end
    pcall(function()
        root.CFrame = CFrame.lookAt(root.Position, root.Position + direction.Unit)
        if not Config.AutoRotateEnabled then
            humanoid.AutoRotate = false
        end
    end)
end

local function ApplyAirMove()
    if not Config.AirMoveEnabled then
        return
    end
    local character = GetCharacter()
    local humanoid = GetHumanoid(character)
    local root = GetRoot(character)
    if not humanoid or not root then
        return
    end
    local state = humanoid:GetState()
    local airborne = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
    if not airborne then
        return
    end
    local direction = humanoid.MoveDirection
    if direction.Magnitude <= 0.01 then
        return
    end
    local current = root.AssemblyLinearVelocity
    local horizontal = direction.Unit * Config.AirMoveSpeed
    local vertical = Config.AirMoveVertical and current.Y or current.Y
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.new(horizontal.X, vertical, horizontal.Z)
    end)
end

local function StartAntiAfk()
    if Runtime.AntiAfkRunning then
        return
    end
    Runtime.AntiAfkRunning = true
    task.spawn(function()
        while IsAlive() and Config.AntiAFK do
            task.wait(48)
            if not IsAlive() or not Config.AntiAFK then
                break
            end
            local root = GetRoot()
            if root then
                local position = root.Position
                pcall(function()
                    root.CFrame = root.CFrame + Vector3.new(0, 0.2, 0)
                end)
                task.wait(0.1)
                if root and root.Parent then
                    pcall(function()
                        root.CFrame = CFrame.new(position) * (root.CFrame - root.Position)
                    end)
                end
            end
        end
        Runtime.AntiAfkRunning = false
    end)
end

local function StopAntiAfk()
    Runtime.AntiAfkRunning = false
end

local function SetFeatureConfig(key, value, controllerName)
    Config[key] = value
    if controllerName then
        SetController(controllerName, value)
    end
    FireControlChanged(key, value)
end

RegisterController("hitbox", function()
    RefreshHitboxes(true)
end, function()
    ClearHitboxes()
end, function()
    RefreshHitboxes(true)
end)

RegisterController("movement", function()
    SetAutoRotate(Config.AutoRotateEnabled)
end, function()
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.AutoRotate = true
    end
end, function()
    SetAutoRotate(Config.AutoRotateEnabled)
end)

RegisterController("stats", function()
    CaptureBaseline()
    ApplyStats()
    RefreshStatHooks()
end, function()
    DisconnectBucket("attribute-hooks")
    ResetAttributes()
end, function()
    ApplyStats()
end)

RegisterController("visuals", function()
    SetCameraFov()
    RefreshHitboxes(true)
end, function()
    local camera = GetCamera()
    if camera and Baseline.FieldOfView then
        camera.FieldOfView = Baseline.FieldOfView
    end
end, function()
    SetCameraFov()
end)

RegisterController("utilities", function()
    if Config.AntiAFK then
        StartAntiAfk()
    end
end, function()
    StopAntiAfk()
end, function()
    if Config.AntiAFK then
        StartAntiAfk()
    end
end)

local function RefreshControllers()
    SetController("hitbox", Config.HitboxEnabled)
    SetController("movement", Config.DirectionalJump or Config.AirMoveEnabled or Config.AutoRotateEnabled)
    SetController("stats", Config.EnableStatChangers)
    SetController("visuals", Config.StretchedRes or Config.HitboxEnabled)
    SetController("utilities", Config.AntiAFK)
end

local function UpdateControllerFromConfig(key)
    if key == "HitboxEnabled" then
        SetController("hitbox", Config.HitboxEnabled)
    elseif key == "DirectionalJump" or key == "AirMoveEnabled" or key == "AutoRotateEnabled" then
        SetController("movement", Config.DirectionalJump or Config.AirMoveEnabled or Config.AutoRotateEnabled)
    elseif key == "EnableStatChangers" then
        SetController("stats", Config.EnableStatChangers)
    elseif key == "StretchedRes" or key == "HitboxTransparency" or key == "HitboxColor" then
        SetController("visuals", Config.StretchedRes or Config.HitboxEnabled)
    elseif key == "AntiAFK" then
        SetController("utilities", Config.AntiAFK)
    end
end

local function ReconcileConfiguration()
    ApplyWindowPosition()
    RefreshControllers()
    ApplyStats()
    RefreshStatHooks()
    SetCameraFov()
    RefreshHitboxes(true)
    if Config.HideIcon then
        Icon.Visible = false
    elseif not Shell.Visible then
        Icon.Visible = true
    end
end

local function UpdateControlAndRuntime(key, value)
    if ControlRegistry[key] and ControlRegistry[key].Refresh then
        SafeCall(ControlRegistry[key].Refresh, value)
    end
    UpdateControllerFromConfig(key)
end

local function UpdateAllControls()
    for key, control in pairs(ControlRegistry) do
        if control.Refresh and Config[key] ~= nil then
            SafeCall(control.Refresh, Config[key])
        end
    end
end

CreateSection(GameplayPage, "Game control", "Core interaction options", 2)
local GameplayCoreCard = CreateCard(GameplayPage, 246, 3)
CreateLabel(GameplayCoreCard, "CORE INPUT", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(GameplayCoreCard, "Local control routing and key actions", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local GameplayBody = CreatePanelBody(GameplayCoreCard, 62, 12)
CreateToggle(GameplayBody, "Powerful serve mode", "Registers the Z action without remote enumeration.", "PowerfulServeEnabled", function(value)
    if value then
        Notify("Serve mode", "Local trigger armed on Z.", "success")
    else
        Notify("Serve mode", "Local trigger disarmed.", "neutral")
    end
end, 1)
CreateKeybind(GameplayBody, "Serve action key", "Configurable input binding for serve mode.", "ServeKey", function()
end, 2)
CreateToggle(GameplayBody, "Notifications", "Show state changes and system alerts.", "Notifications", function()
end, 3)

local GameplayStatusCard = CreateCard(GameplayPage, 160, 4)
CreateLabel(GameplayStatusCard, "CONTROL STATUS", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(GameplayStatusCard, "Feature status is refreshed from runtime state.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local GameplayStatusBody = CreatePanelBody(GameplayStatusCard, 62, 12)
CreateFeatureStatus(GameplayStatusBody, "hitbox", "Hitbox renderer", 1)
CreateFeatureStatus(GameplayStatusBody, "movement", "Movement controller", 2)
CreateFeatureStatus(GameplayStatusBody, "stats", "Stat synchronization", 3)

CreateSection(MovementPage, "Movement system", "Air handling and orientation controls", 2)
local MovementCard = CreateCard(MovementPage, 306, 3)
CreateLabel(MovementCard, "MOVEMENT PARAMETERS", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(MovementCard, "Apply only while the relevant controller is active.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local MovementBody = CreatePanelBody(MovementCard, 62, 12)
CreateToggle(MovementBody, "Directional jump", "Aligns the character to the current camera direction.", "DirectionalJump", function()
    UpdateControllerFromConfig("DirectionalJump")
end, 1)
CreateToggle(MovementBody, "Air move", "Applies horizontal movement while airborne.", "AirMoveEnabled", function()
    UpdateControllerFromConfig("AirMoveEnabled")
end, 2)
CreateSlider(MovementBody, "Air move speed", "Horizontal velocity cap while airborne.", "AirMoveSpeed", 1, 120, 1, function()
end, 3)
CreateToggle(MovementBody, "Air vertical control", "Preserves vertical velocity while air movement is active.", "AirMoveVertical", function()
end, 4)

local RotationCard = CreateCard(MovementPage, 136, 4)
CreateLabel(RotationCard, "ORIENTATION", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(RotationCard, "Character orientation lifecycle", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local RotationBody = CreatePanelBody(RotationCard, 62, 12)
CreateToggle(RotationBody, "Auto rotate monitor", "Restores humanoid rotation when disabled by movement logic.", "AutoRotateEnabled", function()
    UpdateControllerFromConfig("AutoRotateEnabled")
end, 1)

CreateSection(VisualsPage, "Visual pipeline", "Rendering, scale and camera presentation", 2)
local VisualsCard = CreateCard(VisualsPage, 322, 3)
CreateLabel(VisualsCard, "VISUAL PARAMETERS", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(VisualsCard, "Readable overlays with controlled update frequency.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local VisualsBody = CreatePanelBody(VisualsCard, 62, 12)
CreateToggle(VisualsBody, "Hitbox enabled", "Render a local visual radius around detected ball models.", "HitboxEnabled", function()
    UpdateControllerFromConfig("HitboxEnabled")
end, 1)
CreateSlider(VisualsBody, "Hitbox scale", "Diameter of the local visual radius.", "HitboxScale", 1, 24, 1, function()
    RefreshHitboxes(true)
end, 2)
CreateSlider(VisualsBody, "Hitbox transparency", "Opacity of the local force-field visual.", "HitboxTransparency", 0.1, 0.95, 0.05, function()
    RefreshHitboxes(true)
end, 3)
CreateSelect(VisualsBody, "Hitbox accent", "Color used by the visual radius.", "HitboxColor", {"Cyan", "Violet", "Green", "Amber"}, function()
    RefreshHitboxes(true)
end, 4)
local CameraCard = CreateCard(VisualsPage, 292, 4)
CreateLabel(CameraCard, "CAMERA", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(CameraCard, "Field of view and performance presentation.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local CameraBody = CreatePanelBody(CameraCard, 62, 12)
CreateToggle(CameraBody, "Stretched presentation", "Use the configured wide field of view.", "StretchedRes", function()
    UpdateControllerFromConfig("StretchedRes")
end, 1)
CreateSlider(CameraBody, "Normal FOV", "Baseline field of view when stretched mode is disabled.", "NormalFOV", 50, 120, 1, function()
    SetCameraFov()
end, 2)
CreateSlider(CameraBody, "Stretched FOV", "Field of view used by stretched presentation.", "StretchedFOV", 70, 130, 1, function()
    SetCameraFov()
end, 3)

CreateSection(ExperimentalPage, "Advanced parameters", "Controlled attribute synchronization and movement multipliers", 2)
local StatToggleCard = CreateCard(ExperimentalPage, 150, 3)
CreateLabel(StatToggleCard, "STAT SYNCHRONIZATION", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(StatToggleCard, "The controller captures a baseline before applying values.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local StatToggleBody = CreatePanelBody(StatToggleCard, 62, 12)
CreateToggle(StatToggleBody, "Enable stat changers", "Apply configured attributes and character multipliers.", "EnableStatChangers", function()
    UpdateControllerFromConfig("EnableStatChangers")
end, 1)

local StatCardA = CreateCard(ExperimentalPage, 520, 4)
CreateLabel(StatCardA, "GAME MULTIPLIERS A", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(StatCardA, "Values are synchronized only while the feature is active.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local StatBodyA = CreatePanelBody(StatCardA, 62, 12)
CreateSlider(StatBodyA, "Dive speed", "Dive speed multiplier.", "DiveSpeed", 0, 5, 0.1, function()
    ApplyStats()
end, 1)
CreateSlider(StatBodyA, "Spike power", "Spike power multiplier.", "SpikePower", 0, 500, 1, function()
    ApplyStats()
end, 2)
CreateSlider(StatBodyA, "Tilt power", "Tilt power multiplier.", "TiltPower", 0, 500, 1, function()
    ApplyStats()
end, 3)
CreateSlider(StatBodyA, "Speed multiplier", "Walk speed multiplier.", "SpeedMult", 0.25, 2, 0.05, function()
    ApplyStats()
end, 4)
CreateSlider(StatBodyA, "Set power", "Set power multiplier.", "SetPower", 0, 500, 1, function()
    ApplyStats()
end, 5)

local StatCardB = CreateCard(ExperimentalPage, 520, 5)
CreateLabel(StatCardB, "GAME MULTIPLIERS B", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(StatCardB, "Use restrained values for predictable behavior.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local StatBodyB = CreatePanelBody(StatCardB, 62, 12)
CreateSlider(StatBodyB, "Serve power", "Serve power multiplier.", "ServePower", 0, 500, 1, function()
    ApplyStats()
end, 1)
CreateSlider(StatBodyB, "Jump power", "Jump power and jump height multiplier.", "JumpPowerMult", 0, 5, 0.1, function()
    ApplyStats()
end, 2)
CreateSlider(StatBodyB, "Bump power", "Bump power multiplier.", "BumpPower", 0, 500, 1, function()
    ApplyStats()
end, 3)
CreateSlider(StatBodyB, "Block power", "Block power multiplier.", "BlockPower", 0, 500, 1, function()
    ApplyStats()
end, 4)
CreateAction(StatBodyB, "Restore captured baseline", "Reapply the values detected before synchronization.", "RESTORE", function()
    ResetAttributes()
    Notify("Statistics", "Captured baseline restored.", "success")
end, 5, Palette.BorderStrong)

CreateSection(UtilitiesPage, "Maintenance", "Persistence, diagnostics and lifecycle controls", 2)
local UtilityCard = CreateCard(UtilitiesPage, 280, 3)
CreateLabel(UtilityCard, "RUNTIME UTILITIES", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(UtilityCard, "Manage the active profile without restarting the hub.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local UtilityBody = CreatePanelBody(UtilityCard, 62, 12)
CreateToggle(UtilityBody, "Anti AFK", "Performs a low-frequency local position nudge.", "AntiAFK", function()
    UpdateControllerFromConfig("AntiAFK")
end, 1)
CreateToggle(UtilityBody, "Performance mode", "Reduces scan cadence and nonessential updates.", "PerformanceMode", function()
    RefreshHitboxes(true)
end, 2)
CreateToggle(UtilityBody, "Show metrics", "Display FPS, ping, memory and active feature cards.", "ShowMetrics", function(value)
    DashboardMetrics.Visible = value
end, 3)

local PersistenceCard = CreateCard(UtilitiesPage, 280, 4)
CreateLabel(PersistenceCard, "PROFILE MANAGEMENT", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(PersistenceCard, "The profile is stored in the v2 configuration path.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local PersistenceBody = CreatePanelBody(PersistenceCard, 62, 12)
CreateAction(PersistenceBody, "Save current profile", "Write the normalized configuration to disk.", "SAVE", function()
    if SaveConfig(false) then
        Notify("Profile", "Saved successfully.", "success")
    else
        Notify("Profile", "Write access is unavailable.", "warning")
    end
end, 1)
CreateAction(PersistenceBody, "Reload saved profile", "Load the last normalized profile from disk.", "LOAD", function()
    if LoadConfig(false) then
        UpdateAllControls()
        ReconcileConfiguration()
        Notify("Profile", "Loaded successfully.", "success")
    else
        Notify("Profile", "No valid saved profile was found.", "warning")
    end
end, 2)
CreateAction(PersistenceBody, "Reset profile", "Replace the current profile with the baseline.", "RESET", function()
    AskConfirmation("RESET PROFILE", "Current values will be replaced by the baseline profile.", function()
        ResetConfig(false)
        UpdateAllControls()
        ReconcileConfiguration()
        Notify("Profile", "Baseline profile restored.", "success")
    end)
end, 3, Palette.BorderStrong)

local DiagnosticsCard = CreateCard(UtilitiesPage, 222, 5)
CreateLabel(DiagnosticsCard, "DIAGNOSTICS", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(DiagnosticsCard, "Compact runtime checks for troubleshooting.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local DiagnosticsBody = CreatePanelBody(DiagnosticsCard, 62, 12)
CreateAction(DiagnosticsBody, "Refresh diagnostics", "Reconcile controllers, camera and visual registry.", "REFRESH", function()
    ReconcileConfiguration()
    UpdateDashboard()
    Notify("Diagnostics", "Runtime state reconciled.", "success")
end, 1)
CreateAction(DiagnosticsBody, "Clear hitbox registry", "Remove all local visual instances and rebuild on demand.", "CLEAR", function()
    ClearHitboxes()
    Notify("Diagnostics", "Visual registry cleared.", "success")
end, 2, Palette.BorderStrong)

CreateSection(SettingsPage, "Interface", "Presentation and interaction preferences", 2)
local SettingsInterface = CreateCard(SettingsPage, 356, 3)
CreateLabel(SettingsInterface, "INTERFACE SETTINGS", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(SettingsInterface, "Tune the hub shell without changing feature behavior.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local SettingsInterfaceBody = CreatePanelBody(SettingsInterface, 62, 12)
CreateToggle(SettingsInterfaceBody, "Hide floating icon", "Keep the launcher hidden while the hub is minimized.", "HideIcon", function(value)
    Icon.Visible = not value and not Shell.Visible
end, 1)
CreateToggle(SettingsInterfaceBody, "Compact mode", "Reduce spacing inside control rows.", "CompactMode", function()
    Notify("Interface", "Compact mode applies to newly built sessions.", "info")
end, 2)
CreateToggle(SettingsInterfaceBody, "Save on change", "Persist controls after each accepted update.", "SaveOnChange", function()
end, 3)
CreateSlider(SettingsInterfaceBody, "Notification duration", "Time before a notification leaves the queue.", "NotificationDuration", 1, 8, 1, function()
end, 4)

local SettingsKeyCard = CreateCard(SettingsPage, 214, 4)
CreateLabel(SettingsKeyCard, "KEYBINDS", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(SettingsKeyCard, "Click a key field and press the desired key.", UDim2.new(1, -28, 0, 16), UDim2.new(0, 14, 0, 36), Palette.TextDim, Enum.Font.GothamMedium, 10)
local SettingsKeyBody = CreatePanelBody(SettingsKeyCard, 62, 12)
CreateKeybind(SettingsKeyBody, "Toggle UI", "Open or minimize the main window.", "ToggleUIKey", function()
end, 1)
CreateKeybind(SettingsKeyBody, "Reset key", "Reserved emergency reset binding.", "ResetKey", function()
end, 2)

local SettingsAbout = CreateCard(SettingsPage, 142, 5)
CreateLabel(SettingsAbout, "BUILD INFORMATION", UDim2.new(1, -28, 0, 22), UDim2.new(0, 14, 0, 14), Palette.Text, Enum.Font.GothamBold, 13)
CreateLabel(SettingsAbout, "Ragnarok Hub v" .. RAGNAROK_VERSION .. "  /  build " .. RAGNAROK_BUILD, UDim2.new(1, -28, 0, 18), UDim2.new(0, 14, 0, 45), Palette.TextMuted, Enum.Font.GothamMedium, 11)
CreateLabel(SettingsAbout, "Lifecycle-safe runtime with normalized configuration.", UDim2.new(1, -28, 0, 18), UDim2.new(0, 14, 0, 72), Palette.TextDim, Enum.Font.GothamMedium, 10)

local function SetActivePage(id)
    local target = PageRegistry[id] and id or "dashboard"
    Runtime.ActivePage = target
    for pageId, pageData in pairs(PageRegistry) do
        local active = pageId == target
        pageData.Page.Visible = active
        local nav = PageButtons[pageId]
        if nav then
            nav.Marker.Visible = active
            nav.Button.BackgroundColor3 = active and Palette.AccentSoft or Palette.Surface
            nav.Icon.TextColor3 = active and Palette.Accent or Palette.TextDim
            nav.Text.TextColor3 = active and Palette.Text or Palette.TextMuted
        end
    end
end

local UpdatePageVisibilityForSearch

local function ApplySearch(query)
    Runtime.SearchQuery = string.lower(tostring(query or ""))
    local normalized = Runtime.SearchQuery
    for _, control in pairs(ControlRegistry) do
        if control.Row then
            local rowText = control.SearchText or string.lower(control.Row.Name)
            control.Row.Visible = normalized == "" or string.find(rowText, normalized, 1, true) ~= nil
        end
    end
    UpdatePageVisibilityForSearch()
end

Track(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    ApplySearch(SearchBox.Text)
end), "ui")

local function HandleKeybind(input, processed)
    if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end
    local keyName = input.KeyCode.Name
    if Runtime.PendingBinding then
        return
    end
    if Config.ToggleUIKey and keyName == Config.ToggleUIKey then
        ToggleShell()
        return
    end
    if Config.ResetKey and Config.ResetKey ~= "None" and keyName == Config.ResetKey then
        AskConfirmation("RESET PROFILE", "The reset key was pressed. Confirm baseline restoration.", function()
            ResetConfig(false)
            UpdateAllControls()
            ReconcileConfiguration()
            Notify("Profile", "Baseline profile restored.", "success")
        end)
        return
    end
    if Config.ServeKey and keyName == Config.ServeKey and Config.PowerfulServeEnabled then
        Notify("Serve mode", "Local serve action received.", "info")
    end
    for featureKey, bind in pairs(Config.Binds) do
        if bind == keyName and ControlRegistry[featureKey] then
            local current = Config[featureKey]
            if type(current) == "boolean" then
                Config[featureKey] = not current
                UpdateControlAndRuntime(featureKey, Config[featureKey])
                Notify(featureKey, Config[featureKey] and "Enabled" or "Disabled", Config[featureKey] and "success" or "neutral")
            end
        end
    end
end

Track(UIS.InputBegan:Connect(HandleKeybind), "input")

local function HandleJump()
    if not IsAlive() then
        return
    end
    if Config.DirectionalJump then
        task.defer(function()
            task.wait(0.04)
            if IsAlive() then
                FaceCameraDirection()
            end
        end)
    end
end

Track(UIS.JumpRequest:Connect(HandleJump), "input")

local function HandleCharacterAdded(character)
    if not IsAlive() then
        return
    end
    Baseline.Character = nil
    Baseline.CharacterAttributes = {}
    task.delay(0.25, function()
        if not IsAlive() or not character.Parent then
            return
        end
        CaptureBaseline()
        ApplyStats()
        RefreshStatHooks()
        SetAutoRotate(Config.AutoRotateEnabled)
    end)
end

Track(LocalPlayer.CharacterAdded:Connect(HandleCharacterAdded), "character")

Track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if not IsAlive() then
        return
    end
    task.defer(SetCameraFov)
end), "visuals")

local function GetPageMatch(id)
    local page = PageRegistry[id]
    if not page then
        return false
    end
    local query = Runtime.SearchQuery
    if query == "" then
        return true
    end
    return string.find(string.lower(page.Title.Text .. " " .. page.Subtitle.Text), query, 1, true) ~= nil
end

UpdatePageVisibilityForSearch = function()
    local query = Runtime.SearchQuery
    if query == "" then
        SetActivePage(Runtime.ActivePage)
        return
    end
    for id, page in pairs(PageRegistry) do
        local pageMatch = GetPageMatch(id)
        for _, child in ipairs(page.Page:GetChildren()) do
            if child:IsA("Frame") and child ~= page.Header then
                local visible = pageMatch
                if not pageMatch then
                    local text = string.lower(child.Name .. " " .. child:GetFullName())
                    visible = string.find(text, query, 1, true) ~= nil
                end
                child.Visible = visible
            end
        end
    end
end

Track(SearchBox.FocusLost:Connect(UpdatePageVisibilityForSearch), "ui")

local function RebuildIconVisibility()
    if Config.HideIcon then
        Icon.Visible = false
    else
        Icon.Visible = not Shell.Visible
    end
end

local function FullShutdown(reason)
    if not RAGNAROK_ALIVE then
        return
    end
    Runtime.ShutdownReason = reason or "manual"
    RAGNAROK_ALIVE = false
    for name, controller in pairs(Controllers) do
        if controller.Active then
            controller.Active = false
            SafeCall(controller.Stop)
        end
    end
    SetHeaderStatus("OFFLINE", Palette.Danger)
    ClearHitboxes()
    DisconnectAll()
    DisconnectBucket("attribute-hooks")
    ResetAttributes()
    local camera = GetCamera()
    if camera then
        pcall(function()
            camera.FieldOfView = Baseline.FieldOfView
        end)
    end
    SafeDestroy(Ragnarok)
    SafeDestroy(NotifyGui)
    if getgenv then
        local environment = getgenv()
        environment.RagnarokShutdown = nil
        environment.RagnarokVersion = RAGNAROK_VERSION
    end
end

Track(CloseButton.MouseButton1Click:Connect(function()
    AskConfirmation("STOP RAGNAROK HUB", "The interface, visual registry and active controllers will be shut down.", function()
        FullShutdown("confirmed")
    end)
end), "ui")

local function UpdateTick(delta)
    if not IsAlive() then
        return
    end
    if delta and delta > 0 then
        Runtime.FrameRate = math.clamp(1 / delta, 0, 999)
    end
    Runtime.LastMetricUpdate = Runtime.LastMetricUpdate + delta
    if Runtime.LastMetricUpdate >= (Config.PerformanceMode and 1 or 0.4) then
        Runtime.LastMetricUpdate = 0
        UpdateDashboard()
    end
end

Track(RunService.RenderStepped:Connect(function(delta)
    if not IsAlive() then
        return
    end
    UpdateTick(delta)
    RefreshHitboxes(false)
    ApplyAirMove()
    if Config.AutoRotateEnabled then
        SetAutoRotate(true)
    end
    SetCameraFov()
end), "runtime")

Track(RunService.Heartbeat:Connect(function()
    if not IsAlive() then
        return
    end
    local now = os.clock()
    if now - Runtime.LastStatsApply >= (Config.PerformanceMode and 1.5 or 0.5) then
        Runtime.LastStatsApply = now
        if Config.EnableStatChangers then
            ApplyStats()
        end
    end
end), "runtime")

if getgenv then
    getgenv().RagnarokShutdown = function()
        FullShutdown("reload")
    end
end

local startupCamera = GetCamera()
if startupCamera then
    Baseline.FieldOfView = startupCamera.FieldOfView
end

SetActivePage("dashboard")
DashboardMetrics.Visible = Config.ShowMetrics
RebuildIconVisibility()
ReconcileConfiguration()
UpdateDashboard()
SetHeaderStatus("ONLINE", Palette.Success)
UpdateFooter("RAGNAROK HUB  /  DASHBOARD  /  READY")
Notify("Ragnarok Hub", "Version " .. RAGNAROK_VERSION .. " initialized.", "success", 2)

local StartupBinding = Config.ToggleUIKey
if StartupBinding == "None" then
    StartupBinding = "RightShift"
end

for key, control in pairs(ControlRegistry) do
    if control.Refresh and Config[key] ~= nil then
        SafeCall(control.Refresh, Config[key])
    end
end

if Config.HideIcon then
    Icon.Visible = false
end

local PublicAPI = {
    Version = RAGNAROK_VERSION,
    Build = RAGNAROK_BUILD,
    Config = Config,
    Notify = Notify,
    SaveConfig = SaveConfig,
    LoadConfig = LoadConfig,
    ResetConfig = ResetConfig,
    Refresh = ReconcileConfiguration,
    Shutdown = FullShutdown,
    Toggle = ToggleShell,
    SetPage = SetActivePage,
}

if getgenv then
    getgenv().RagnarokAPI = PublicAPI
end
