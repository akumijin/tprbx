-- // Glass UI patcher — sets 0.5 transparency on all background frames
local function applyGlass(parent)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
            if obj.BackgroundTransparency < 0.4 then
                obj.BackgroundTransparency = 0.5
            end
        end
    end
end
-- // ===================== KEY SYSTEM =====================

local KEY_URL = "https://raw.githubusercontent.com/akumijin/tprbx/main/key.txt"

-- Use executor HTTP (bypasses game HttpEnabled restriction)
local function fetchURL(url)
    if syn and syn.request then
        return syn.request({Url=url, Method="GET"}).Body
    elseif http and http.request then
        return http.request({Url=url, Method="GET"}).Body
    elseif request then
        return request({Url=url, Method="GET"}).Body
    else
        return game:HttpGet(url)
    end
end

local keyOk, STORED_HASH = pcall(function()
    return tonumber(fetchURL(KEY_URL):gsub("%s+", ""))
end)

if not keyOk or not STORED_HASH then
    warn("[KeySystem] Could not fetch key. Check repo or internet.")
    return
end

local function hashString(s)
    local h = 5381
    for i = 1, #s do
        h = bit32.bxor(h * 33, string.byte(s, i)) % 4294967296
    end
    return h
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP               = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- // Key GUI
local ksg = Instance.new("ScreenGui")
ksg.ResetOnSpawn = false
ksg.Name = "AkumaKey"
ksg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ksg.Parent = LP.PlayerGui

local kframe = Instance.new("Frame")
kframe.Size = UDim2.new(0, 290, 0, 140)
kframe.Position = UDim2.new(0.5, -145, 0.5, -70)
kframe.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
kframe.BorderSizePixel = 0
kframe.Active = true
kframe.Parent = ksg
Instance.new("UICorner", kframe).CornerRadius = UDim.new(0, 10)
do
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(55,55,55); s.Thickness = 1.2; s.Parent = kframe
end

local ktbar = Instance.new("Frame")
ktbar.Size = UDim2.new(1,0,0,36)
ktbar.BackgroundColor3 = Color3.fromRGB(20,20,20)
ktbar.BorderSizePixel = 0
ktbar.Parent = kframe
Instance.new("UICorner", ktbar).CornerRadius = UDim.new(0,10)

local ktlbl = Instance.new("TextLabel")
ktlbl.Size = UDim2.new(1,0,1,0)
ktlbl.BackgroundTransparency = 1
ktlbl.Text = "🔑  Akuma Scripts — Enter Key"
ktlbl.TextColor3 = Color3.fromRGB(230,230,230)
ktlbl.Font = Enum.Font.GothamBold
ktlbl.TextSize = 12
ktlbl.Parent = ktbar

local ksublbl = Instance.new("TextLabel")
ksublbl.Size = UDim2.new(1,-20,0,14)
ksublbl.Position = UDim2.new(0,10,0,40)
ksublbl.BackgroundTransparency = 1
ksublbl.Text = "github.com/akumijin/tprbx"
ksublbl.TextColor3 = Color3.fromRGB(70,70,70)
ksublbl.Font = Enum.Font.Gotham
ksublbl.TextSize = 10
ksublbl.TextXAlignment = Enum.TextXAlignment.Left
ksublbl.Parent = kframe

local kbox = Instance.new("TextBox")
kbox.Size = UDim2.new(1,-20,0,30)
kbox.Position = UDim2.new(0,10,0,58)
kbox.BackgroundColor3 = Color3.fromRGB(22,22,22)
kbox.Text = ""
kbox.PlaceholderText = "Enter your key here..."
kbox.PlaceholderColor3 = Color3.fromRGB(75,75,75)
kbox.TextColor3 = Color3.fromRGB(220,220,220)
kbox.Font = Enum.Font.Gotham
kbox.TextSize = 12
kbox.BorderSizePixel = 0
kbox.ClearTextOnFocus = false
kbox.Parent = kframe
Instance.new("UICorner", kbox).CornerRadius = UDim.new(0,6)

local kstatus = Instance.new("TextLabel")
kstatus.Size = UDim2.new(1,-20,0,14)
kstatus.Position = UDim2.new(0,10,0,92)
kstatus.BackgroundTransparency = 1
kstatus.Text = ""
kstatus.TextColor3 = Color3.fromRGB(220,80,80)
kstatus.Font = Enum.Font.Gotham
kstatus.TextSize = 10
kstatus.TextXAlignment = Enum.TextXAlignment.Left
kstatus.Parent = kframe

local ksubmit = Instance.new("TextButton")
ksubmit.Size = UDim2.new(1,-20,0,26)
ksubmit.Position = UDim2.new(0,10,0,108)
ksubmit.BackgroundColor3 = Color3.fromRGB(30,80,140)
ksubmit.Text = "Submit"
ksubmit.TextColor3 = Color3.fromRGB(255,255,255)
ksubmit.Font = Enum.Font.GothamBold
ksubmit.TextSize = 12
ksubmit.BorderSizePixel = 0
ksubmit.Parent = kframe
Instance.new("UICorner", ksubmit).CornerRadius = UDim.new(0,6)

local verified = Instance.new("BindableEvent")
local function trySubmit()
    local entered = kbox.Text:gsub("%s+", "")
    if hashString(entered) == STORED_HASH then
        ksg:Destroy()
        verified:Fire()
    else
        kstatus.Text = "❌  Invalid key."
        kbox.BackgroundColor3 = Color3.fromRGB(55,18,18)
        task.delay(0.6, function()
            kbox.BackgroundColor3 = Color3.fromRGB(22,22,22)
            kstatus.Text = ""
        end)
    end
end
ksubmit.MouseButton1Click:Connect(trySubmit)
kbox.FocusLost:Connect(function(enter) if enter then trySubmit() end end)
verified.Event:Wait()
verified:Destroy()

-- // ===================== STATE =====================

local hasMouseAPI = typeof(mousemoveabs) == "function"
                 and typeof(mouse1click)  == "function"

-- Capture mode: only one slot can be waiting at a time
local captureMode   = false
local captureSlotID = nil
local captureResolvers = {}  -- [slotID] = { xBox, yBox, capBtn, state }

local afkState = {
    jump   = { on=false, interval=10000, elapsed=0 },
    follow = { on=false, interval=10000, elapsed=0 },
    fixed  = {},
}
for i = 1, 6 do
    afkState.fixed[i] = { on=false, interval=10000, elapsed=0, x=0, y=0 }
end

local tpState = {
    noclip    = false,
    slotCount = 3,
    slots     = {},
}
for i = 1, 10 do
    tpState.slots[i] = { name="Slot "..i, x=nil, y=nil, z=nil }
end

local specState = {
    spectating = false,
    target     = nil,
    connection = nil,
}

-- // ===================== CORE FUNCTIONS =====================

local function getRoot()
    local c = LP.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function doJump()
    local ok = pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
        task.delay(0.1, function()
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end)
    if not ok then
        pcall(function()
            keypress(0x20)
            task.delay(0.1, function() keyrelease(0x20) end)
        end)
    end
    local c = LP.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then hum.Jump = true end
    end
end

local function doFollowClick()
    if not hasMouseAPI then return end
    pcall(mouse1click)
end

local function doFixedClick(x, y)
    if not hasMouseAPI then return end
    pcall(function() mousemoveabs(x, y); mouse1click() end)
end

local function stopSpectate()
    specState.spectating = false
    specState.target = nil
    if specState.connection then
        specState.connection:Disconnect()
        specState.connection = nil
    end
    Camera.CameraType = Enum.CameraType.Custom
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
    end
end

local function spectatePlayer(plr)
    if not plr or not plr.Character then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    stopSpectate()
    specState.spectating = true
    specState.target = plr
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = hum
    specState.connection = plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        local newHum = char:FindFirstChildOfClass("Humanoid")
        if newHum and specState.spectating and specState.target == plr then
            Camera.CameraSubject = newHum
        end
    end)
end

-- // ===================== MAIN GUI =====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AkumaMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LP.PlayerGui

local Win = Instance.new("Frame")
Win.Size = UDim2.new(0, 320, 0, 520)
Win.Position = UDim2.new(0, 20, 0.5, -260)
Win.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Win.BorderSizePixel = 0
Win.Active = true
Win.Draggable = true
Win.ClipsDescendants = false
Win.Parent = ScreenGui
Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 10)
do
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(50,50,50); s.Thickness = 1.2; s.Parent = Win
end

-- // Title bar
local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1,0,0,38)
TBar.BackgroundColor3 = Color3.fromRGB(18,18,18)
TBar.BorderSizePixel = 0
TBar.Parent = Win
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0,10)

local TLbl = Instance.new("TextLabel")
TLbl.Size = UDim2.new(1,-10,1,0)
TLbl.Position = UDim2.new(0,10,0,0)
TLbl.BackgroundTransparency = 1
TLbl.Text = "⚙️  Akuma Menu"
TLbl.TextColor3 = Color3.fromRGB(230,230,230)
TLbl.Font = Enum.Font.GothamBold
TLbl.TextSize = 13
TLbl.TextXAlignment = Enum.TextXAlignment.Left
TLbl.Parent = TBar

local KHint = Instance.new("TextLabel")
KHint.Size = UDim2.new(0,70,1,0)
KHint.Position = UDim2.new(1,-75,0,0)
KHint.BackgroundTransparency = 1
KHint.Text = "K = hide"
KHint.TextColor3 = Color3.fromRGB(65,65,65)
KHint.Font = Enum.Font.Gotham
KHint.TextSize = 10
KHint.TextXAlignment = Enum.TextXAlignment.Right
KHint.Parent = TBar

-- // PINNED COORD BAR (always visible, below title)
local PinnedBar = Instance.new("Frame")
PinnedBar.Size = UDim2.new(1,-20,0,28)
PinnedBar.Position = UDim2.new(0,10,0,42)
PinnedBar.BackgroundColor3 = Color3.fromRGB(16,16,16)
PinnedBar.BorderSizePixel = 0
PinnedBar.Parent = Win
Instance.new("UICorner", PinnedBar).CornerRadius = UDim.new(0,6)
do
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(35,35,35); s.Thickness = 1; s.Parent = PinnedBar
end

local PinnedCoordLbl = Instance.new("TextLabel")
PinnedCoordLbl.Size = UDim2.new(0.6,0,1,0)
PinnedCoordLbl.Position = UDim2.new(0,8,0,0)
PinnedCoordLbl.BackgroundTransparency = 1
PinnedCoordLbl.Text = "X: —   Y: —   Z: —"
PinnedCoordLbl.TextColor3 = Color3.fromRGB(100,220,140)
PinnedCoordLbl.Font = Enum.Font.GothamBold
PinnedCoordLbl.TextSize = 11
PinnedCoordLbl.TextXAlignment = Enum.TextXAlignment.Left
PinnedCoordLbl.Parent = PinnedBar

local PinnedMouseLbl = Instance.new("TextLabel")
PinnedMouseLbl.Size = UDim2.new(0.4,-8,1,0)
PinnedMouseLbl.Position = UDim2.new(0.6,0,0,0)
PinnedMouseLbl.BackgroundTransparency = 1
PinnedMouseLbl.Text = "M: 0, 0"
PinnedMouseLbl.TextColor3 = Color3.fromRGB(90,140,90)
PinnedMouseLbl.Font = Enum.Font.Gotham
PinnedMouseLbl.TextSize = 10
PinnedMouseLbl.TextXAlignment = Enum.TextXAlignment.Right
PinnedMouseLbl.Parent = PinnedBar

local PinnedRightPad = Instance.new("UIPadding")
PinnedRightPad.PaddingRight = UDim.new(0,8)
PinnedRightPad.Parent = PinnedBar

-- // Tab buttons
local TabRow = Instance.new("Frame")
TabRow.Size = UDim2.new(1,-20,0,28)
TabRow.Position = UDim2.new(0,10,0,74)
TabRow.BackgroundTransparency = 1
TabRow.Parent = Win

local tabNames = {"⏸ AFK", "📍 Teleport", "👁 Spectate"}
local tabBtns = {}
local tabPanels = {}
local activeTab = 1

for idx, label in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabNames, idx==1 and 0 or -3, 1, 0)
    btn.Position = UDim2.new((idx-1)/#tabNames, idx==1 and 0 or 2, 0, 0)
    btn.BackgroundColor3 = idx==1 and Color3.fromRGB(35,35,35) or Color3.fromRGB(22,22,22)
    btn.Text = label
    btn.TextColor3 = idx==1 and Color3.fromRGB(220,220,220) or Color3.fromRGB(100,100,100)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = TabRow
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    tabBtns[idx] = btn
end

-- // Tab panels
local PANEL_Y = 106
local PANEL_H = 406

for i = 1, 3 do
    local panel = Instance.new("ScrollingFrame")
    panel.Size = UDim2.new(1,-20,0,PANEL_H)
    panel.Position = UDim2.new(0,10,0,PANEL_Y)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 3
    panel.ScrollBarImageColor3 = Color3.fromRGB(55,55,55)
    panel.CanvasSize = UDim2.new(0,0,0,0)
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.Visible = i == 1
    panel.Parent = Win
    tabPanels[i] = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)
    layout.Parent = panel

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0,4)
    pad.PaddingBottom = UDim.new(0,8)
    pad.Parent = panel
end

local function switchTab(idx)
    activeTab = idx
    for i, btn in ipairs(tabBtns) do
        btn.BackgroundColor3 = i==idx and Color3.fromRGB(35,35,35) or Color3.fromRGB(22,22,22)
        btn.TextColor3 = i==idx and Color3.fromRGB(220,220,220) or Color3.fromRGB(100,100,100)
        tabPanels[i].Visible = i == idx
    end
end
for i, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
end

-- // ===================== GUI HELPERS =====================

local function makeSection(parent, title, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,24)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,7)

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)
    layout.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0,8)
    pad.PaddingRight = UDim.new(0,8)
    pad.PaddingTop = UDim.new(0,6)
    pad.PaddingBottom = UDim.new(0,8)
    pad.Parent = frame

    if title and title ~= "" then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,0,0,14)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(85,85,85)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = 0
        lbl.Parent = frame
    end

    return frame
end

local function setToggleBtn(btn, on)
    if on then
        btn.Text = "ON"
        btn.BackgroundColor3 = Color3.fromRGB(30,140,30)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
    else
        btn.Text = "OFF"
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        btn.TextColor3 = Color3.fromRGB(160,160,160)
    end
end

local function parseMS(text, fallback)
    local n = tonumber(text)
    if n and n >= 50 then return n end
    return fallback or 10000
end

local function makeTimerBlock(parent, stateTable, title, order)
    local sec = makeSection(parent, title, order)

    local ctrlRow = Instance.new("Frame")
    ctrlRow.Size = UDim2.new(1,0,0,26)
    ctrlRow.BackgroundTransparency = 1
    ctrlRow.LayoutOrder = 1
    ctrlRow.Parent = sec

    local msBox = Instance.new("TextBox")
    msBox.Size = UDim2.new(0,72,0,22)
    msBox.Position = UDim2.new(0,0,0.5,-11)
    msBox.BackgroundColor3 = Color3.fromRGB(26,26,26)
    msBox.Text = "10000"
    msBox.PlaceholderText = "ms"
    msBox.TextColor3 = Color3.fromRGB(200,200,200)
    msBox.PlaceholderColor3 = Color3.fromRGB(70,70,70)
    msBox.Font = Enum.Font.Gotham
    msBox.TextSize = 11
    msBox.BorderSizePixel = 0
    msBox.ClearTextOnFocus = false
    msBox.Parent = ctrlRow
    Instance.new("UICorner", msBox).CornerRadius = UDim.new(0,4)

    local msLbl = Instance.new("TextLabel")
    msLbl.Size = UDim2.new(0,18,0,22)
    msLbl.Position = UDim2.new(0,76,0.5,-11)
    msLbl.BackgroundTransparency = 1
    msLbl.Text = "ms"
    msLbl.TextColor3 = Color3.fromRGB(65,65,65)
    msLbl.Font = Enum.Font.Gotham
    msLbl.TextSize = 10
    msLbl.Parent = ctrlRow

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0,50,0,22)
    toggleBtn.Position = UDim2.new(1,-50,0.5,-11)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(160,160,160)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 10
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = ctrlRow
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,4)

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1,0,0,3)
    barBg.BackgroundColor3 = Color3.fromRGB(26,26,26)
    barBg.BorderSizePixel = 0
    barBg.LayoutOrder = 2
    barBg.Parent = sec
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0,2)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0,0,1,0)
    barFill.BackgroundColor3 = Color3.fromRGB(80,200,120)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0,2)

    toggleBtn.MouseButton1Click:Connect(function()
        stateTable.on = not stateTable.on
        if not stateTable.on then
            stateTable.elapsed = 0
            barFill.Size = UDim2.new(0,0,1,0)
        end
        setToggleBtn(toggleBtn, stateTable.on)
    end)

    msBox.FocusLost:Connect(function()
        local v = parseMS(msBox.Text, 10000)
        stateTable.interval = v
        msBox.Text = tostring(v)
        stateTable.elapsed = 0
    end)

    return sec, barFill
end

-- // ===================== TAB 1: AFK =====================

local afkPanel = tabPanels[1]

-- Auto Jump
local _, jumpBar = makeTimerBlock(afkPanel, afkState.jump, "── AUTO JUMP", 1)

-- Follow Mouse
local _, followBar = makeTimerBlock(afkPanel, afkState.follow, "── AUTO CLICK (Follow Mouse)", 2)

-- Fixed x6 with Capture Mode
local fixedBars = {}

for i = 1, 6 do
    local s = afkState.fixed[i]
    local sec, bar = makeTimerBlock(afkPanel, s, "── FIXED CLICK #"..i, 2+i)
    fixedBars[i] = bar

    -- Coord display inside section
    local coordDisp = Instance.new("TextLabel")
    coordDisp.Size = UDim2.new(1,0,0,14)
    coordDisp.BackgroundTransparency = 1
    coordDisp.Text = "Click position: not set"
    coordDisp.TextColor3 = Color3.fromRGB(80,80,80)
    coordDisp.Font = Enum.Font.Gotham
    coordDisp.TextSize = 10
    coordDisp.TextXAlignment = Enum.TextXAlignment.Left
    coordDisp.LayoutOrder = 3
    coordDisp.Parent = sec

    -- Capture button row
    local capRow = Instance.new("Frame")
    capRow.Size = UDim2.new(1,0,0,24)
    capRow.BackgroundTransparency = 1
    capRow.LayoutOrder = 4
    capRow.Parent = sec

    local capBtn = Instance.new("TextButton")
    capBtn.Size = UDim2.new(1,0,1,0)
    capBtn.BackgroundColor3 = Color3.fromRGB(35,60,100)
    capBtn.Text = "📍 Capture Click Position"
    capBtn.TextColor3 = Color3.fromRGB(160,200,255)
    capBtn.Font = Enum.Font.GothamBold
    capBtn.TextSize = 11
    capBtn.BorderSizePixel = 0
    capBtn.Parent = capRow
    Instance.new("UICorner", capBtn).CornerRadius = UDim.new(0,5)

    local function updateCoordDisp()
        if s.x and s.x ~= 0 then
            coordDisp.Text = string.format("Click position:  X=%d  Y=%d", s.x, s.y)
            coordDisp.TextColor3 = Color3.fromRGB(100,200,120)
        else
            coordDisp.Text = "Click position: not set"
            coordDisp.TextColor3 = Color3.fromRGB(80,80,80)
        end
    end

    -- Store resolver so the global InputBegan can fire it
    captureResolvers[i] = {
        xSetter = function(x) s.x = x end,
        ySetter = function(y) s.y = y end,
        onCapture = function(x, y)
            s.x = x; s.y = y
            updateCoordDisp()
            capBtn.BackgroundColor3 = Color3.fromRGB(35,60,100)
            capBtn.Text = "📍 Capture Click Position"
            capBtn.TextColor3 = Color3.fromRGB(160,200,255)
            print(string.format("[Fixed #%d] Captured → X=%d  Y=%d", i, x, y))
        end
    }

    local capBtnHeld = false

    capBtn.MouseButton1Down:Connect(function()
        capBtnHeld = true
    end)

    capBtn.MouseButton1Up:Connect(function()
        capBtnHeld = false
    end)

    capBtn.MouseButton1Click:Connect(function()
        if captureMode and captureSlotID == i then
            -- Cancel
            captureMode = false
            captureSlotID = nil
            capBtn.BackgroundColor3 = Color3.fromRGB(35,60,100)
            capBtn.Text = "📍 Capture Click Position"
            capBtn.TextColor3 = Color3.fromRGB(160,200,255)
            return
        end

        -- Cancel any previously waiting capture
        if captureMode and captureSlotID and captureSlotID ~= i then
            -- previous slot stays as-is visually, we override
        end

        captureMode = true
        captureSlotID = i
        capBtn.BackgroundColor3 = Color3.fromRGB(180,120,20)
        capBtn.Text = "🖱 Click anywhere to capture..."
        capBtn.TextColor3 = Color3.fromRGB(255,220,100)
    end)
end

-- // ===================== TAB 2: TELEPORT =====================

local tpPanel = tabPanels[2]

-- Noclip
local noclipSec = makeSection(tpPanel, "── NOCLIP", 1)
local noclipRow = Instance.new("Frame")
noclipRow.Size = UDim2.new(1,0,0,28)
noclipRow.BackgroundTransparency = 1
noclipRow.LayoutOrder = 1
noclipRow.Parent = noclipSec

local noclipLbl = Instance.new("TextLabel")
noclipLbl.Size = UDim2.new(1,-60,1,0)
noclipLbl.BackgroundTransparency = 1
noclipLbl.Text = "👻 Noclip"
noclipLbl.TextColor3 = Color3.fromRGB(200,200,200)
noclipLbl.Font = Enum.Font.GothamBold
noclipLbl.TextSize = 11
noclipLbl.TextXAlignment = Enum.TextXAlignment.Left
noclipLbl.Parent = noclipRow

local noclipBtn = Instance.new("TextButton")
noclipBtn.Size = UDim2.new(0,50,0,22)
noclipBtn.Position = UDim2.new(1,-50,0.5,-11)
noclipBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
noclipBtn.Text = "OFF"
noclipBtn.TextColor3 = Color3.fromRGB(160,160,160)
noclipBtn.Font = Enum.Font.GothamBold
noclipBtn.TextSize = 10
noclipBtn.BorderSizePixel = 0
noclipBtn.Parent = noclipRow
Instance.new("UICorner", noclipBtn).CornerRadius = UDim.new(0,5)

noclipBtn.MouseButton1Click:Connect(function()
    tpState.noclip = not tpState.noclip
    setToggleBtn(noclipBtn, tpState.noclip)
end)

-- Slot count
local slotCtrlSec = makeSection(tpPanel, "── TELEPORT SLOTS", 2)
local slotCtrlRow = Instance.new("Frame")
slotCtrlRow.Size = UDim2.new(1,0,0,26)
slotCtrlRow.BackgroundTransparency = 1
slotCtrlRow.LayoutOrder = 1
slotCtrlRow.Parent = slotCtrlSec

local slotLbl = Instance.new("TextLabel")
slotLbl.Size = UDim2.new(0,120,1,0)
slotLbl.BackgroundTransparency = 1
slotLbl.Text = "Active Slots:"
slotLbl.TextColor3 = Color3.fromRGB(160,160,160)
slotLbl.Font = Enum.Font.GothamBold
slotLbl.TextSize = 11
slotLbl.TextXAlignment = Enum.TextXAlignment.Left
slotLbl.Parent = slotCtrlRow

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0,26,0,22)
minusBtn.Position = UDim2.new(1,-80,0.5,-11)
minusBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
minusBtn.Text = "−"
minusBtn.TextColor3 = Color3.fromRGB(200,200,200)
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 14
minusBtn.BorderSizePixel = 0
minusBtn.Parent = slotCtrlRow
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0,5)

local slotNumLbl = Instance.new("TextLabel")
slotNumLbl.Size = UDim2.new(0,24,1,0)
slotNumLbl.Position = UDim2.new(1,-52,0,0)
slotNumLbl.BackgroundTransparency = 1
slotNumLbl.Text = tostring(tpState.slotCount)
slotNumLbl.TextColor3 = Color3.fromRGB(255,255,255)
slotNumLbl.Font = Enum.Font.GothamBold
slotNumLbl.TextSize = 13
slotNumLbl.TextXAlignment = Enum.TextXAlignment.Center
slotNumLbl.Parent = slotCtrlRow

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0,26,0,22)
plusBtn.Position = UDim2.new(1,-28,0.5,-11)
plusBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
plusBtn.Text = "+"
plusBtn.TextColor3 = Color3.fromRGB(200,200,200)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 14
plusBtn.BorderSizePixel = 0
plusBtn.Parent = slotCtrlRow
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0,5)

-- Slot cards
local slotFrames = {}

local function makeSlotCard(i)
    local s = tpState.slots[i]

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1,0,0,52)
    card.BackgroundColor3 = Color3.fromRGB(20,20,20)
    card.BorderSizePixel = 0
    card.LayoutOrder = i+2
    card.Visible = i <= tpState.slotCount
    card.Parent = tpPanel
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,7)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0,100,0,18)
    nameLbl.Position = UDim2.new(0,8,0,4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = s.name
    nameLbl.TextColor3 = Color3.fromRGB(210,210,210)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = card

    local editBtn = Instance.new("TextButton")
    editBtn.Size = UDim2.new(0,36,0,18)
    editBtn.Position = UDim2.new(0,108,0,4)
    editBtn.BackgroundColor3 = Color3.fromRGB(40,60,90)
    editBtn.Text = "✏ Edit"
    editBtn.TextColor3 = Color3.fromRGB(160,200,255)
    editBtn.Font = Enum.Font.GothamBold
    editBtn.TextSize = 9
    editBtn.BorderSizePixel = 0
    editBtn.Parent = card
    Instance.new("UICorner", editBtn).CornerRadius = UDim.new(0,4)

    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(0,142,0,20)
    nameBox.Position = UDim2.new(0,6,0,4)
    nameBox.BackgroundColor3 = Color3.fromRGB(28,28,45)
    nameBox.Text = s.name
    nameBox.TextColor3 = Color3.fromRGB(220,220,255)
    nameBox.PlaceholderText = "Enter name..."
    nameBox.PlaceholderColor3 = Color3.fromRGB(80,80,100)
    nameBox.Font = Enum.Font.GothamBold
    nameBox.TextSize = 11
    nameBox.BorderSizePixel = 0
    nameBox.ClearTextOnFocus = false
    nameBox.Visible = false
    nameBox.Parent = card
    Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0,4)

    local coordLbl = Instance.new("TextLabel")
    coordLbl.Size = UDim2.new(1,-10,0,14)
    coordLbl.Position = UDim2.new(0,8,0,6)
    coordLbl.BackgroundTransparency = 1
    coordLbl.Text = "Not saved"
    coordLbl.TextColor3 = Color3.fromRGB(75,75,75)
    coordLbl.Font = Enum.Font.Gotham
    coordLbl.TextSize = 10
    coordLbl.TextXAlignment = Enum.TextXAlignment.Right
    coordLbl.Parent = card

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.48,-4,0,20)
    saveBtn.Position = UDim2.new(0,6,1,-24)
    saveBtn.BackgroundColor3 = Color3.fromRGB(28,85,48)
    saveBtn.Text = "💾 Save"
    saveBtn.TextColor3 = Color3.fromRGB(150,255,180)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 10
    saveBtn.BorderSizePixel = 0
    saveBtn.Parent = card
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0,5)

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0.48,-4,0,20)
    tpBtn.Position = UDim2.new(0.5,2,1,-24)
    tpBtn.BackgroundColor3 = Color3.fromRGB(28,48,100)
    tpBtn.Text = "⚡ Teleport"
    tpBtn.TextColor3 = Color3.fromRGB(150,180,255)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 10
    tpBtn.BorderSizePixel = 0
    tpBtn.Parent = card
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0,5)

    local function refreshCoord()
        if s.x then
            coordLbl.Text = string.format("X:%.1f  Y:%.1f  Z:%.1f", s.x, s.y, s.z)
            coordLbl.TextColor3 = Color3.fromRGB(100,200,120)
        else
            coordLbl.Text = "Not saved"
            coordLbl.TextColor3 = Color3.fromRGB(75,75,75)
        end
    end
    refreshCoord()

    editBtn.MouseButton1Click:Connect(function()
        nameBox.Text = s.name
        nameBox.Visible = true
        nameLbl.Visible = false
        editBtn.Visible = false
        nameBox:CaptureFocus()
    end)
    nameBox.FocusLost:Connect(function()
        local n = nameBox.Text
        if n == "" then n = "Slot "..i end
        s.name = n
        nameLbl.Text = n
        nameBox.Visible = false
        nameLbl.Visible = true
        editBtn.Visible = true
    end)

    saveBtn.MouseButton1Click:Connect(function()
        local root = getRoot()
        if not root then return end
        s.x = math.floor(root.Position.X*10)/10
        s.y = math.floor(root.Position.Y*10)/10
        s.z = math.floor(root.Position.Z*10)/10
        refreshCoord()
        saveBtn.BackgroundColor3 = Color3.fromRGB(20,140,60)
        task.delay(0.5, function() saveBtn.BackgroundColor3 = Color3.fromRGB(28,85,48) end)
    end)

    tpBtn.MouseButton1Click:Connect(function()
        if not s.x then return end
        local root = getRoot()
        if not root then return end
        root.CFrame = CFrame.new(s.x, s.y, s.z)
        tpBtn.BackgroundColor3 = Color3.fromRGB(20,80,180)
        task.delay(0.5, function() tpBtn.BackgroundColor3 = Color3.fromRGB(28,48,100) end)
    end)

    slotFrames[i] = card
end

for i = 1, 10 do makeSlotCard(i) end

local function refreshSlots()
    slotNumLbl.Text = tostring(tpState.slotCount)
    for i = 1, 10 do
        slotFrames[i].Visible = i <= tpState.slotCount
    end
end

minusBtn.MouseButton1Click:Connect(function()
    if tpState.slotCount > 1 then
        tpState.slotCount = tpState.slotCount - 1
        refreshSlots()
    end
end)
plusBtn.MouseButton1Click:Connect(function()
    if tpState.slotCount < 10 then
        tpState.slotCount = tpState.slotCount + 1
        refreshSlots()
    end
end)

-- // ===================== TAB 3: SPECTATE =====================

local specPanel = tabPanels[3]

local specStatusSec = makeSection(specPanel, "", 0)
local specStatusLbl = Instance.new("TextLabel")
specStatusLbl.Size = UDim2.new(1,0,0,16)
specStatusLbl.BackgroundTransparency = 1
specStatusLbl.Text = "Not spectating"
specStatusLbl.TextColor3 = Color3.fromRGB(100,100,100)
specStatusLbl.Font = Enum.Font.GothamBold
specStatusLbl.TextSize = 11
specStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
specStatusLbl.LayoutOrder = 1
specStatusLbl.Parent = specStatusSec

local returnSec = makeSection(specPanel, "", 1)
local returnBtn = Instance.new("TextButton")
returnBtn.Size = UDim2.new(1,0,0,28)
returnBtn.BackgroundColor3 = Color3.fromRGB(100,30,30)
returnBtn.Text = "↩  Return to Own Character"
returnBtn.TextColor3 = Color3.fromRGB(255,160,160)
returnBtn.Font = Enum.Font.GothamBold
returnBtn.TextSize = 11
returnBtn.BorderSizePixel = 0
returnBtn.LayoutOrder = 1
returnBtn.Parent = returnSec
Instance.new("UICorner", returnBtn).CornerRadius = UDim.new(0,6)

returnBtn.MouseButton1Click:Connect(function()
    stopSpectate()
    specStatusLbl.Text = "Not spectating"
    specStatusLbl.TextColor3 = Color3.fromRGB(100,100,100)
end)

local playerListSec = makeSection(specPanel, "── PLAYERS", 2)
local playerBtns = {}

local function refreshPlayerList()
    for _, b in ipairs(playerBtns) do b:Destroy() end
    playerBtns = {}

    local order = 1
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,30)
        btn.BackgroundColor3 = Color3.fromRGB(22,22,22)
        btn.Text = "👤  "..plr.DisplayName.."  (@"..plr.Name..")"
        btn.TextColor3 = Color3.fromRGB(200,200,200)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        btn.BorderSizePixel = 0
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = order
        btn.Parent = playerListSec
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0,8)
        pad.Parent = btn

        btn.MouseButton1Click:Connect(function()
            spectatePlayer(plr)
            specStatusLbl.Text = "👁 Spectating: "..plr.DisplayName
            specStatusLbl.TextColor3 = Color3.fromRGB(100,200,255)
            for _, b in ipairs(playerBtns) do
                b.BackgroundColor3 = Color3.fromRGB(22,22,22)
                b.TextColor3 = Color3.fromRGB(200,200,200)
            end
            btn.BackgroundColor3 = Color3.fromRGB(28,55,90)
            btn.TextColor3 = Color3.fromRGB(150,200,255)
        end)

        table.insert(playerBtns, btn)
        order = order + 1
    end

    if #playerBtns == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1,0,0,22)
        empty.BackgroundTransparency = 1
        empty.Text = "No other players in server"
        empty.TextColor3 = Color3.fromRGB(65,65,65)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 10
        empty.LayoutOrder = 1
        empty.Parent = playerListSec
        table.insert(playerBtns, empty)
    end
end

refreshPlayerList()

local refreshSec = makeSection(specPanel, "", 3)
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1,0,0,24)
refreshBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
refreshBtn.Text = "🔄  Refresh Player List"
refreshBtn.TextColor3 = Color3.fromRGB(140,140,140)
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 10
refreshBtn.BorderSizePixel = 0
refreshBtn.LayoutOrder = 1
refreshBtn.Parent = refreshSec
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0,6)

refreshBtn.MouseButton1Click:Connect(refreshPlayerList)

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    refreshPlayerList()
end)
Players.PlayerRemoving:Connect(function(plr)
    task.wait(0.1)
    if specState.target == plr then
        stopSpectate()
        specStatusLbl.Text = "Target left the game"
        specStatusLbl.TextColor3 = Color3.fromRGB(220,80,80)
    end
    refreshPlayerList()
end)

-- // ===================== INPUT HANDLER =====================
-- Handles both K toggle and capture mode click detection

UserInputService.InputBegan:Connect(function(input, gpe)
    -- K = hide/show menu (always works)
    if input.KeyCode == Enum.KeyCode.K then
        Win.Visible = not Win.Visible
        return
    end

    -- Capture mode: intercept the NEXT independent left mouse click
    -- Uses InputEnded to confirm the button is fully released before we start listening
    if captureMode and input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Wait for mouse button to be fully released first (InputEnded fires next)
        -- We handle this in InputEnded below instead
    end
end)

-- // Capture: fire on InputEnded so button release doesn't self-capture
UserInputService.InputEnded:Connect(function(input)
    if captureMode and input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Only capture if this isn't the Capture button's own release
        -- We wait a frame to let any MouseButton1Up from the capBtn clear first
        task.defer(function()
            if not captureMode then return end
            local mp = UserInputService:GetMouseLocation()
            local slotID = captureSlotID
            captureMode = false
            captureSlotID = nil
            if slotID and captureResolvers[slotID] then
                captureResolvers[slotID].onCapture(math.floor(mp.X), math.floor(mp.Y))
            end
        end)
    end
end)

-- // ===================== MAIN LOOP =====================

RunService.Heartbeat:Connect(function(dt)
    local dtms = dt * 1000

    -- Update pinned coord + mouse bar (always visible)
    local mp = UserInputService:GetMouseLocation()
    PinnedMouseLbl.Text = string.format("M: %d, %d", math.floor(mp.X), math.floor(mp.Y))

    local root = getRoot()
    if root then
        local p = root.Position
        PinnedCoordLbl.Text = string.format(
            "X:%.1f  Y:%.1f  Z:%.1f", p.X, p.Y, p.Z)
    else
        PinnedCoordLbl.Text = "X: —   Y: —   Z: —"
    end

    -- Auto Jump
    if afkState.jump.on then
        afkState.jump.elapsed = afkState.jump.elapsed + dtms
        jumpBar.Size = UDim2.new(
            math.min(afkState.jump.elapsed / afkState.jump.interval, 1), 0, 1, 0)
        if afkState.jump.elapsed >= afkState.jump.interval then
            afkState.jump.elapsed = 0
            doJump()
        end
    end

    -- Follow Mouse
    if afkState.follow.on then
        afkState.follow.elapsed = afkState.follow.elapsed + dtms
        followBar.Size = UDim2.new(
            math.min(afkState.follow.elapsed / afkState.follow.interval, 1), 0, 1, 0)
        if afkState.follow.elapsed >= afkState.follow.interval then
            afkState.follow.elapsed = 0
            doFollowClick()
        end
    end

    -- Fixed x6
    for i = 1, 6 do
        local s = afkState.fixed[i]
        if s.on then
            s.elapsed = s.elapsed + dtms
            fixedBars[i].Size = UDim2.new(
                math.min(s.elapsed / s.interval, 1), 0, 1, 0)
            if s.elapsed >= s.interval then
                s.elapsed = 0
                doFixedClick(s.x, s.y)
            end
        end
    end
end)

-- Noclip loop
RunService.Stepped:Connect(function()
    if not tpState.noclip then return end
    local c = LP.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            p.CanCollide = false
        end
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    if tpState.noclip then
        setToggleBtn(noclipBtn, true)
    end
end)

-- Apply glass transparency to all frames
applyGlass(ScreenGui)

print("[Akuma Menu v2] Loaded. K to toggle.")
