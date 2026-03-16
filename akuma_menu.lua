local KEY_URL = "https://raw.githubusercontent.com/akumijin/tprbx/main/key.txt"

local keyOk, VALID_KEY = pcall(function()
    return game:HttpGet(KEY_URL):gsub("%s+", "")
end)

if not keyOk or not VALID_KEY or VALID_KEY == "" then
    warn("[KeySystem] Could not fetch key. Check repo or internet.")
    return
end

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local LP              = Players.LocalPlayer
local Camera          = workspace.CurrentCamera

-- Key GUI
local ksg = Instance.new("ScreenGui")
ksg.ResetOnSpawn = false
ksg.Name = "AkumaKey"
ksg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ksg.Parent = LP.PlayerGui

local kframe = Instance.new("Frame")
kframe.Size = UDim2.new(0, 290, 0, 140)
kframe.Position = UDim2.new(0.5, -145, 0.5, -70)
kframe.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
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
    local entered = kbox.Text:gsub("%s+","")
    if entered == VALID_KEY then
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

local hasMouseAPI = typeof(mousemoveabs)=="function" and typeof(mouse1click)=="function"

local afkState = {
    jump   = { on=false, interval=10000, elapsed=0 },
    follow = { on=false, interval=10000, elapsed=0 },
    fixed  = {},
}
for i=1,6 do
    afkState.fixed[i] = { on=false, interval=10000, elapsed=0, x=0, y=0 }
end

local tpState = {
    noclip   = false,
    slotCount= 3,
    slots    = {},
}
for i=1,10 do
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

-- Jump: all 3 methods
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
    pcall(function() mousemoveabs(x,y); mouse1click() end)
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

-- Outer window
local Win = Instance.new("Frame")
Win.Size = UDim2.new(0, 320, 0, 500)
Win.Position = UDim2.new(0, 20, 0.5, -250)
Win.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
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

-- Title bar
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

-- Tab buttons row
local TabRow = Instance.new("Frame")
TabRow.Size = UDim2.new(1,-20,0,28)
TabRow.Position = UDim2.new(0,10,0,42)
TabRow.BackgroundTransparency = 1
TabRow.Parent = Win

local tabNames = {"⏸ AFK", "📍 Teleport", "👁 Spectate"}
local tabBtns = {}
local tabPanels = {}
local activeTab = 1

local function makeTabBtn(label, idx)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabNames, -3, 1, 0)
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
    return btn
end

for i,name in ipairs(tabNames) do makeTabBtn(name, i) end

-- Tab panels (content areas)
local PANEL_Y = 76
local PANEL_H = 416  -- Win height minus top stuff

for i=1,3 do
    local panel = Instance.new("ScrollingFrame")
    panel.Size = UDim2.new(1,-20, 0, PANEL_H)
    panel.Position = UDim2.new(0,10,0,PANEL_Y)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 3
    panel.ScrollBarImageColor3 = Color3.fromRGB(60,60,60)
    panel.CanvasSize = UDim2.new(0,0,0,0)
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.Visible = i == 1
    panel.Parent = Win
    tabPanels[i] = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)
    layout.Parent = panel

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0,4)
    padding.PaddingBottom = UDim.new(0,4)
    padding.Parent = panel
end

-- Tab switching
local function switchTab(idx)
    activeTab = idx
    for i,btn in ipairs(tabBtns) do
        btn.BackgroundColor3 = i==idx and Color3.fromRGB(35,35,35) or Color3.fromRGB(22,22,22)
        btn.TextColor3 = i==idx and Color3.fromRGB(220,220,220) or Color3.fromRGB(100,100,100)
    end
    for i,panel in ipairs(tabPanels) do
        panel.Visible = i==idx
    end
end
for i,btn in ipairs(tabBtns) do
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

    local inner = Instance.new("UIListLayout")
    inner.SortOrder = Enum.SortOrder.LayoutOrder
    inner.Padding = UDim.new(0,4)
    inner.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0,8)
    pad.PaddingRight = UDim.new(0,8)
    pad.PaddingTop = UDim.new(0,6)
    pad.PaddingBottom = UDim.new(0,8)
    pad.Parent = frame

    if title and title ~= "" then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,0,0,16)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(90,90,90)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = 0
        lbl.Parent = frame
    end

    return frame
end

local function makeToggleRow(parent, label, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-60,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,50,0,22)
    btn.Position = UDim2.new(1,-50,0.5,-11)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(160,160,160)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

    return row, btn
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

local function makeTimerRow(parent, stateTable, label, order, fireFn)
    local sec = makeSection(parent, label, order)

    -- ms + toggle row
    local ctrlRow = Instance.new("Frame")
    ctrlRow.Size = UDim2.new(1,0,0,26)
    ctrlRow.BackgroundTransparency = 1
    ctrlRow.LayoutOrder = 1
    ctrlRow.Parent = sec

    local msBox = Instance.new("TextBox")
    msBox.Size = UDim2.new(0,70,0,22)
    msBox.Position = UDim2.new(0,0,0.5,-11)
    msBox.BackgroundColor3 = Color3.fromRGB(28,28,28)
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
    msLbl.Position = UDim2.new(0,74,0.5,-11)
    msLbl.BackgroundTransparency = 1
    msLbl.Text = "ms"
    msLbl.TextColor3 = Color3.fromRGB(70,70,70)
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

    -- Timer bar
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1,0,0,3)
    barBg.BackgroundColor3 = Color3.fromRGB(28,28,28)
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

    -- Wiring
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

-- Live mouse display
local mouseSec = makeSection(afkPanel, "", 0)
local mouseLbl = Instance.new("TextLabel")
mouseLbl.Size = UDim2.new(1,0,0,16)
mouseLbl.BackgroundTransparency = 1
mouseLbl.Text = "Mouse:  X = 0    Y = 0"
mouseLbl.TextColor3 = Color3.fromRGB(90,160,90)
mouseLbl.Font = Enum.Font.Gotham
mouseLbl.TextSize = 10
mouseLbl.TextXAlignment = Enum.TextXAlignment.Left
mouseLbl.LayoutOrder = 1
mouseLbl.Parent = mouseSec

-- Auto Jump
local _, jumpBar = makeTimerRow(afkPanel, afkState.jump, "── AUTO JUMP", 1)

-- Follow Mouse
local _, followBar = makeTimerRow(afkPanel, afkState.follow, "── AUTO CLICK (Follow Mouse)", 2)

-- Fixed x6
local fixedBars = {}
for i=1,6 do
    local s = afkState.fixed[i]
    local sec, bar = makeTimerRow(afkPanel, s, "── FIXED CLICK #"..i, 2+i)
    fixedBars[i] = bar

    -- X/Y row
    local xyRow = Instance.new("Frame")
    xyRow.Size = UDim2.new(1,0,0,24)
    xyRow.BackgroundTransparency = 1
    xyRow.LayoutOrder = 3
    xyRow.Parent = sec

    local function makeCoordBox(lTxt, xOff)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0,12,1,0)
        lbl.Position = UDim2.new(0,xOff,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = lTxt
        lbl.TextColor3 = Color3.fromRGB(100,100,100)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.Parent = xyRow

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0,60,1,-2)
        box.Position = UDim2.new(0,xOff+14,0,1)
        box.BackgroundColor3 = Color3.fromRGB(22,22,22)
        box.Text = "0"
        box.PlaceholderText = "0"
        box.TextColor3 = Color3.fromRGB(200,200,200)
        box.PlaceholderColor3 = Color3.fromRGB(70,70,70)
        box.Font = Enum.Font.Gotham
        box.TextSize = 11
        box.BorderSizePixel = 0
        box.ClearTextOnFocus = false
        box.Parent = xyRow
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)
        return box
    end

    local xBox = makeCoordBox("X", 0)
    local yBox = makeCoordBox("Y", 84)

    local capBtn = Instance.new("TextButton")
    capBtn.Size = UDim2.new(0,72,1,-2)
    capBtn.Position = UDim2.new(1,-72,0,1)
    capBtn.BackgroundColor3 = Color3.fromRGB(35,60,100)
    capBtn.Text = "📍 Capture"
    capBtn.TextColor3 = Color3.fromRGB(160,200,255)
    capBtn.Font = Enum.Font.GothamBold
    capBtn.TextSize = 10
    capBtn.BorderSizePixel = 0
    capBtn.Parent = xyRow
    Instance.new("UICorner", capBtn).CornerRadius = UDim.new(0,4)

    xBox.FocusLost:Connect(function()
        s.x = tonumber(xBox.Text) or 0
        xBox.Text = tostring(s.x)
    end)
    yBox.FocusLost:Connect(function()
        s.y = tonumber(yBox.Text) or 0
        yBox.Text = tostring(s.y)
    end)
    capBtn.MouseButton1Click:Connect(function()
        local mp = UserInputService:GetMouseLocation()
        s.x = math.floor(mp.X)
        s.y = math.floor(mp.Y)
        xBox.Text = tostring(s.x)
        yBox.Text = tostring(s.y)
        capBtn.BackgroundColor3 = Color3.fromRGB(20,100,20)
        capBtn.Text = "✔ Saved"
        task.delay(1, function()
            capBtn.BackgroundColor3 = Color3.fromRGB(35,60,100)
            capBtn.Text = "📍 Capture"
        end)
    end)
end

-- // ===================== TAB 2: TELEPORT =====================

local tpPanel = tabPanels[2]

-- Live coords
local coordSec = makeSection(tpPanel, "", 0)
local coordLbl = Instance.new("TextLabel")
coordLbl.Size = UDim2.new(1,0,0,20)
coordLbl.BackgroundTransparency = 1
coordLbl.Text = "X: —    Y: —    Z: —"
coordLbl.TextColor3 = Color3.fromRGB(100,220,140)
coordLbl.Font = Enum.Font.GothamBold
coordLbl.TextSize = 12
coordLbl.TextXAlignment = Enum.TextXAlignment.Left
coordLbl.LayoutOrder = 1
coordLbl.Parent = coordSec

-- Noclip
local noclipSec = makeSection(tpPanel, "── NOCLIP", 1)
local _, noclipBtn = makeToggleRow(noclipSec, "👻 Noclip", 1)
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
    card.LayoutOrder = i + 2
    card.Visible = i <= tpState.slotCount
    card.Parent = tpPanel
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,7)

    -- Name label
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

    -- Edit btn
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

    -- Name textbox
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

    -- Coord label
    local coordLabel = Instance.new("TextLabel")
    coordLabel.Size = UDim2.new(1,-10,0,14)
    coordLabel.Position = UDim2.new(0,8,0,6)
    coordLabel.BackgroundTransparency = 1
    coordLabel.Text = "Not saved"
    coordLabel.TextColor3 = Color3.fromRGB(75,75,75)
    coordLabel.Font = Enum.Font.Gotham
    coordLabel.TextSize = 10
    coordLabel.TextXAlignment = Enum.TextXAlignment.Right
    coordLabel.Parent = card

    -- Save btn
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

    -- TP btn
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
            coordLabel.Text = string.format("X:%.1f  Y:%.1f  Z:%.1f", s.x, s.y, s.z)
            coordLabel.TextColor3 = Color3.fromRGB(100,200,120)
        else
            coordLabel.Text = "Not saved"
            coordLabel.TextColor3 = Color3.fromRGB(75,75,75)
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
        if n=="" then n="Slot "..i end
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

for i=1,10 do makeSlotCard(i) end

local function refreshSlots()
    slotNumLbl.Text = tostring(tpState.slotCount)
    for i=1,10 do
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

-- Status
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

-- Return button
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

-- Player list section
local playerListSec = makeSection(specPanel, "── PLAYERS", 2)

local playerBtns = {}

local function refreshPlayerList()
    -- Clear old buttons
    for _, btn in ipairs(playerBtns) do
        btn:Destroy()
    end
    playerBtns = {}

    local order = 1
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,30)
        btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
        btn.Text = "👤  " .. plr.DisplayName .. "  (@" .. plr.Name .. ")"
        btn.TextColor3 = Color3.fromRGB(200,200,200)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        btn.BorderSizePixel = 0
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = order
        btn.Parent = playerListSec
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

        -- Padding inside button text
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0,8)
        pad.Parent = btn

        btn.MouseButton1Click:Connect(function()
            spectatePlayer(plr)
            specStatusLbl.Text = "👁 Spectating: " .. plr.DisplayName
            specStatusLbl.TextColor3 = Color3.fromRGB(100,200,255)
            -- Highlight selected
            for _, b in ipairs(playerBtns) do
                b.BackgroundColor3 = Color3.fromRGB(25,25,25)
                b.TextColor3 = Color3.fromRGB(200,200,200)
            end
            btn.BackgroundColor3 = Color3.fromRGB(30,60,90)
            btn.TextColor3 = Color3.fromRGB(150,200,255)
        end)

        table.insert(playerBtns, btn)
        order = order + 1
    end

    if #playerBtns == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1,0,0,24)
        empty.BackgroundTransparency = 1
        empty.Text = "No other players in server"
        empty.TextColor3 = Color3.fromRGB(70,70,70)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 10
        empty.LayoutOrder = 1
        empty.Parent = playerListSec
        table.insert(playerBtns, empty)
    end
end

refreshPlayerList()

-- Refresh btn
local refreshSec = makeSection(specPanel, "", 3)
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1,0,0,24)
refreshBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
refreshBtn.Text = "🔄  Refresh Player List"
refreshBtn.TextColor3 = Color3.fromRGB(150,150,150)
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 10
refreshBtn.BorderSizePixel = 0
refreshBtn.LayoutOrder = 1
refreshBtn.Parent = refreshSec
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0,6)

refreshBtn.MouseButton1Click:Connect(function()
    refreshPlayerList()
end)

-- Auto-refresh when players join/leave
Players.PlayerAdded:Connect(function() task.wait(0.5) refreshPlayerList() end)
Players.PlayerRemoving:Connect(function(plr)
    task.wait(0.1)
    if specState.target == plr then
        stopSpectate()
        specStatusLbl.Text = "Target left the game"
        specStatusLbl.TextColor3 = Color3.fromRGB(220,80,80)
    end
    refreshPlayerList()
end)

-- // ===================== KEYBIND =====================

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        Win.Visible = not Win.Visible
    end
end)

-- // ===================== MAIN LOOP =====================

RunService.Heartbeat:Connect(function(dt)
    local dtms = dt * 1000

    -- Live mouse display (AFK tab)
    local mp = UserInputService:GetMouseLocation()
    mouseLbl.Text = string.format("Mouse:  X = %.0f    Y = %.0f", mp.X, mp.Y)

    -- Live coords (Teleport tab)
    local root = getRoot()
    if root then
        local p = root.Position
        coordLbl.Text = string.format("X: %.1f    Y: %.1f    Z: %.1f", p.X, p.Y, p.Z)
    else
        coordLbl.Text = "X: —    Y: —    Z: —"
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

    -- Follow Mouse Click
    if afkState.follow.on then
        afkState.follow.elapsed = afkState.follow.elapsed + dtms
        followBar.Size = UDim2.new(
            math.min(afkState.follow.elapsed / afkState.follow.interval, 1), 0, 1, 0)
        if afkState.follow.elapsed >= afkState.follow.interval then
            afkState.follow.elapsed = 0
            doFollowClick()
        end
    end

    -- Fixed Clicks x6
    for i=1,6 do
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

print("[Akuma Menu] Loaded. K to toggle.")