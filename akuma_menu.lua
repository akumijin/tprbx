-- // Akuma Menu v3
-- // AFK | Teleport | Spectate
-- // github.com/akumijin/tprbx

-- ============================================================
-- // SERVICES
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ============================================================
-- // BOOTSTRAP
-- ============================================================

local LP = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
local Camera    = workspace.CurrentCamera
local PlayerGui = LP:WaitForChild("PlayerGui")

-- ============================================================
-- // STATE
-- ============================================================

local hasMouseAPI = typeof(mousemoveabs) == "function" and typeof(mouse1click) == "function"

local afkState = {
    jump   = { on = false, interval = 10000, elapsed = 0 },
    follow = { on = false, interval = 10000, elapsed = 0 },
    fixed  = {},
}
for i = 1, 6 do
    afkState.fixed[i] = { on = false, interval = 10000, elapsed = 0, x = 0, y = 0 }
end

local tpState = {
    noclip    = false,
    slotCount = 3,
    slots     = {},
}
for i = 1, 10 do
    tpState.slots[i] = { name = "Slot " .. i, x = nil, y = nil, z = nil }
end

local specState = { target = nil, connection = nil }

local captureMode      = false
local captureSlotID    = nil
local captureResolvers = {}

-- ============================================================
-- // CORE FUNCTIONS
-- ============================================================

local function getRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function doJump()
    local ok = pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.delay(0.1, function() VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
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
    if hasMouseAPI then pcall(mouse1click) end
end

local function doFixedClick(x, y)
    if hasMouseAPI then pcall(function() mousemoveabs(x, y); mouse1click() end) end
end

local function stopSpectate()
    if specState.connection then specState.connection:Disconnect() end
    specState.target     = nil
    specState.connection = nil
    Camera.CameraType    = Enum.CameraType.Custom
    local c = LP.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
    end
end

    local myChar = LP.Character
    if not myChar then return end

    local myRoot     = myChar:FindFirstChild("HumanoidRootPart")
    local theirRoot  = plr.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not theirRoot then return end

    local destination = myRoot.CFrame

    -- Step 1: teleport to them so we can weld
    myRoot.CFrame = theirRoot.CFrame

    -- Step 2: weld their root to ours
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = myRoot
    weld.Part1 = theirRoot
    weld.Parent = myRoot

    -- Step 3: drag them back to our original position
    task.wait(0.05)
    myRoot.CFrame = destination

    -- Step 4: release
    task.wait(0.1)
    weld:Destroy()
end

local function spectatePlayer(plr)
    if not plr or not plr.Character then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    stopSpectate()
    specState.target     = plr
    Camera.CameraType    = Enum.CameraType.Custom
    Camera.CameraSubject = hum
    specState.connection = plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        local h = char:FindFirstChildOfClass("Humanoid")
        if h and specState.target == plr then Camera.CameraSubject = h end
    end)
end

-- ============================================================
-- // GUI HELPERS
-- ============================================================

local function newCorner(r, p)
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, r)
end

local function newStroke(color, thickness, p)
    local s = Instance.new("UIStroke", p)
    s.Color = color; s.Thickness = thickness
end

local function newLabel(props)
    local lbl = Instance.new("TextLabel")
    for k, v in pairs(props) do lbl[k] = v end
    return lbl
end

local function setToggleBtn(btn, on)
    if on then
        btn.Text             = "ON"
        btn.BackgroundColor3 = Color3.fromRGB(30, 140, 30)
        btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    else
        btn.Text             = "OFF"
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3       = Color3.fromRGB(160, 160, 160)
    end
end

local function parseMS(text, fallback)
    local n = tonumber(text)
    return (n and n >= 50) and n or (fallback or 10000)
end

local function makeSection(parent, title, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 24)
    f.AutomaticSize    = Enum.AutomaticSize.Y
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order or 0
    f.Parent           = parent
    newCorner(7, f)

    local layout = Instance.new("UIListLayout", f)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 4)

    local pad = Instance.new("UIPadding", f)
    pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight  = UDim.new(0, 8)
    pad.PaddingTop  = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 8)

    if title and title ~= "" then
        newLabel({
            Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
            Text = title, TextColor3 = Color3.fromRGB(85, 85, 85),
            Font = Enum.Font.GothamBold, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = f,
        })
    end
    return f
end

local function makeTimerBlock(parent, st, title, order)
    local sec = makeSection(parent, title, order)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26); row.BackgroundTransparency = 1
    row.LayoutOrder = 1; row.Parent = sec

    local msBox = Instance.new("TextBox")
    msBox.Size = UDim2.new(0, 72, 0, 22); msBox.Position = UDim2.new(0, 0, 0.5, -11)
    msBox.BackgroundColor3 = Color3.fromRGB(35, 35, 50); msBox.Text = "10000"
    msBox.PlaceholderText = "ms"; msBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    msBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 70); msBox.Font = Enum.Font.Gotham
    msBox.TextSize = 11; msBox.BorderSizePixel = 0; msBox.ClearTextOnFocus = false
    msBox.Parent = row; newCorner(4, msBox)

    newLabel({
        Size = UDim2.new(0, 18, 0, 22), Position = UDim2.new(0, 76, 0.5, -11),
        BackgroundTransparency = 1, Text = "ms", TextColor3 = Color3.fromRGB(65, 65, 65),
        Font = Enum.Font.Gotham, TextSize = 10, Parent = row,
    })

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 50, 0, 22); toggle.Position = UDim2.new(1, -50, 0.5, -11)
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50); toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(160, 160, 160); toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 10; toggle.BorderSizePixel = 0; toggle.Parent = row; newCorner(4, toggle)

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 0, 3); barBg.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    barBg.BorderSizePixel = 0; barBg.LayoutOrder = 2; barBg.Parent = sec; newCorner(2, barBg)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0); barFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    barFill.BorderSizePixel = 0; barFill.Parent = barBg; newCorner(2, barFill)

    toggle.MouseButton1Click:Connect(function()
        st.on = not st.on
        if not st.on then st.elapsed = 0; barFill.Size = UDim2.new(0, 0, 1, 0) end
        setToggleBtn(toggle, st.on)
    end)
    msBox.FocusLost:Connect(function()
        local v = parseMS(msBox.Text, 10000)
        st.interval = v; msBox.Text = tostring(v); st.elapsed = 0
    end)

    return sec, barFill, toggle
end

-- ============================================================
-- // MAIN WINDOW
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AkumaMenu"; ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ScreenGui.Parent = PlayerGui

local Win = Instance.new("Frame")
Win.Size = UDim2.new(0, 320, 0, 520); Win.Position = UDim2.new(0, 20, 0.5, -260)
Win.BackgroundColor3 = Color3.fromRGB(20, 20, 30); Win.BorderSizePixel = 0
Win.Active = true; Win.Draggable = false; Win.ClipsDescendants = false; Win.Parent = ScreenGui
newCorner(10, Win); newStroke(Color3.fromRGB(70, 70, 110), 1.2, Win)

-- Title bar (drag handle only)
local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1, 0, 0, 38); TBar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
TBar.BorderSizePixel = 0; TBar.Active = true; TBar.Parent = Win; newCorner(10, TBar)

local _da, _ds, _do = false, nil, nil
TBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        _da = true; _ds = i.Position; _do = Win.Position
    end
end)
TBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then _da = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if _da and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - _ds
        Win.Position = UDim2.new(_do.X.Scale, _do.X.Offset + d.X, _do.Y.Scale, _do.Y.Offset + d.Y)
    end
end)

newLabel({
    Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "⚙️  Akuma Menu",
    TextColor3 = Color3.fromRGB(230, 230, 230), Font = Enum.Font.GothamBold,
    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TBar,
})
newLabel({
    Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(1, -75, 0, 0),
    BackgroundTransparency = 1, Text = "K = hide",
    TextColor3 = Color3.fromRGB(65, 65, 65), Font = Enum.Font.Gotham,
    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = TBar,
})

-- Pinned coord bar
local PinnedBar = Instance.new("Frame")
PinnedBar.Size = UDim2.new(1, -20, 0, 28); PinnedBar.Position = UDim2.new(0, 10, 0, 42)
PinnedBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35); PinnedBar.BorderSizePixel = 0
PinnedBar.Parent = Win; newCorner(6, PinnedBar); newStroke(Color3.fromRGB(45, 45, 65), 1, PinnedBar)
Instance.new("UIPadding", PinnedBar).PaddingRight = UDim.new(0, 8)

local PinnedCoordLbl = newLabel({
    Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1, Text = "X: —   Y: —   Z: —",
    TextColor3 = Color3.fromRGB(100, 220, 140), Font = Enum.Font.GothamBold,
    TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = PinnedBar,
})
local PinnedMouseLbl = newLabel({
    Size = UDim2.new(0.4, -8, 1, 0), Position = UDim2.new(0.6, 0, 0, 0),
    BackgroundTransparency = 1, Text = "M: 0, 0",
    TextColor3 = Color3.fromRGB(90, 140, 90), Font = Enum.Font.Gotham,
    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = PinnedBar,
})

-- Tab row
local TabRow = Instance.new("Frame")
TabRow.Size = UDim2.new(1, -20, 0, 28); TabRow.Position = UDim2.new(0, 10, 0, 74)
TabRow.BackgroundTransparency = 1; TabRow.Parent = Win

local TABS = {"⏸ AFK", "📍 Teleport", "👁 Spectate"}
local tabBtns, tabPanels = {}, {}

for idx, label in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #TABS, idx == 1 and 0 or -3, 1, 0)
    btn.Position = UDim2.new((idx - 1) / #TABS, idx == 1 and 0 or 2, 0, 0)
    btn.BackgroundColor3 = idx == 1 and Color3.fromRGB(40, 40, 60) or Color3.fromRGB(25, 25, 38)
    btn.Text = label
    btn.TextColor3 = idx == 1 and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(100, 100, 100)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.BorderSizePixel = 0
    btn.Parent = TabRow; newCorner(6, btn); tabBtns[idx] = btn
end

for i = 1, 3 do
    local panel = Instance.new("ScrollingFrame")
    panel.Size = UDim2.new(1, -20, 0, 406); panel.Position = UDim2.new(0, 10, 0, 106)
    panel.BackgroundTransparency = 1; panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 3; panel.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 100)
    panel.CanvasSize = UDim2.new(0, 0, 0, 0); panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.Visible = i == 1; panel.Parent = Win; tabPanels[i] = panel
    local l = Instance.new("UIListLayout", panel)
    l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 6)
    local p = Instance.new("UIPadding", panel)
    p.PaddingTop = UDim.new(0, 4); p.PaddingBottom = UDim.new(0, 8)
end

-- Pinned spectate header (sits between tab row and panel, only shown on spectate tab)
local SpecPinnedBar = Instance.new("Frame")
SpecPinnedBar.Size             = UDim2.new(1, -20, 0, 58)
SpecPinnedBar.Position         = UDim2.new(0, 10, 0, 106)
SpecPinnedBar.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
SpecPinnedBar.BorderSizePixel  = 0
SpecPinnedBar.Visible          = false
SpecPinnedBar.Parent           = Win
newCorner(8, SpecPinnedBar)
newStroke(Color3.fromRGB(50, 50, 80), 1, SpecPinnedBar)

local SpecPinnedStatus = newLabel({
    Size = UDim2.new(1, -16, 0, 20),
    Position = UDim2.new(0, 8, 0, 5),
    BackgroundTransparency = 1,
    Text = "Not spectating",
    TextColor3 = Color3.fromRGB(100, 100, 100),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = SpecPinnedBar,
})

local SpecExitBtn = Instance.new("TextButton")
SpecExitBtn.Size             = UDim2.new(1, -16, 0, 22)
SpecExitBtn.Position         = UDim2.new(0, 8, 0, 30)
SpecExitBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
SpecExitBtn.Text             = "↩  Exit Spectate"
SpecExitBtn.TextColor3       = Color3.fromRGB(255, 160, 160)
SpecExitBtn.Font             = Enum.Font.GothamBold
SpecExitBtn.TextSize         = 11
SpecExitBtn.BorderSizePixel  = 0
SpecExitBtn.Parent           = SpecPinnedBar
newCorner(6, SpecExitBtn)

-- When spectate tab is active, shift the panel down to make room for the pinned bar
local function switchTab(idx)
    for i, btn in ipairs(tabBtns) do
        btn.BackgroundColor3 = i == idx and Color3.fromRGB(40, 40, 60) or Color3.fromRGB(25, 25, 38)
        btn.TextColor3 = i == idx and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(100, 100, 100)
        tabPanels[i].Visible = i == idx
    end
    local isSpec = idx == 3
    SpecPinnedBar.Visible = isSpec
    -- Shift spectate panel down by pinned bar height when on spectate tab
    tabPanels[3].Position = UDim2.new(0, 10, 0, isSpec and 168 or 106)
    tabPanels[3].Size     = UDim2.new(1, -20, 0, isSpec and 344 or 406)
end
for i, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
end

-- ============================================================
-- // TAB 1: AFK
-- ============================================================

local afkPanel = tabPanels[1]
local _, jumpBar,   jumpToggle  = makeTimerBlock(afkPanel, afkState.jump,   "── AUTO JUMP",               1)
local _, followBar, followToggle = makeTimerBlock(afkPanel, afkState.follow, "── AUTO CLICK (Follow Mouse)", 2)
local fixedBars    = {}
local fixedToggles = {}

for i = 1, 6 do
    local s = afkState.fixed[i]
    local sec, bar, tog = makeTimerBlock(afkPanel, s, "── FIXED CLICK #" .. i, 2 + i)
    fixedBars[i]    = bar
    fixedToggles[i] = tog

    local coordDisp = newLabel({
        Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
        Text = "Click position: not set", TextColor3 = Color3.fromRGB(80, 80, 80),
        Font = Enum.Font.Gotham, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3, Parent = sec,
    })

    local capRow = Instance.new("Frame")
    capRow.Size = UDim2.new(1, 0, 0, 24); capRow.BackgroundTransparency = 1
    capRow.LayoutOrder = 4; capRow.Parent = sec

    local capBtn = Instance.new("TextButton")
    capBtn.Size = UDim2.new(1, 0, 1, 0); capBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 120)
    capBtn.Text = "📍 Capture Click Position"; capBtn.TextColor3 = Color3.fromRGB(160, 200, 255)
    capBtn.Font = Enum.Font.GothamBold; capBtn.TextSize = 11; capBtn.BorderSizePixel = 0
    capBtn.Parent = capRow; newCorner(5, capBtn)

    local function refreshCoordDisp()
        if s.x and s.x ~= 0 then
            coordDisp.Text       = string.format("Click position:  X=%d  Y=%d", s.x, s.y)
            coordDisp.TextColor3 = Color3.fromRGB(100, 200, 120)
        else
            coordDisp.Text       = "Click position: not set"
            coordDisp.TextColor3 = Color3.fromRGB(80, 80, 80)
        end
    end

    captureResolvers[i] = {
        onCapture = function(x, y)
            s.x = x; s.y = y
            refreshCoordDisp()
            capBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 120)
            capBtn.Text             = "📍 Capture Click Position"
            capBtn.TextColor3       = Color3.fromRGB(160, 200, 255)
        end
    }

    local capConn = nil  -- one-shot connection for this slot

    local function cancelCapture()
        captureMode = false; captureSlotID = nil;         if capConn then capConn:Disconnect(); capConn = nil end
        capBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 120)
        capBtn.Text             = "📍 Capture Click Position"
        capBtn.TextColor3       = Color3.fromRGB(160, 200, 255)
    end

    capBtn.MouseButton1Click:Connect(function()
        if captureMode and captureSlotID == i then
            cancelCapture()
            return
        end

        -- Cancel any other slot's capture first
        if captureMode then
            captureMode = false; captureSlotID = nil;             if capConn then capConn:Disconnect(); capConn = nil end
        end

        captureMode = true; captureSlotID = i
        capBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 20)
        capBtn.Text             = "🖱 Click anywhere to set position..."
        capBtn.TextColor3       = Color3.fromRGB(255, 220, 100)

        -- Wait a short delay then create a fresh one-shot listener
        -- This guarantees the current click is completely finished before we start listening
        task.delay(0.2, function()
            if not captureMode or captureSlotID ~= i then return end

            capConn = UserInputService.InputBegan:Connect(function(inp, gpe)
                if gpe then return end
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

                -- This is the user's independent click — capture it
                local mp = UserInputService:GetMouseLocation()
                captureResolvers[i].onCapture(math.floor(mp.X), math.floor(mp.Y))
                cancelCapture()
            end)
        end)
    end)
end

-- ============================================================
-- // TAB 2: TELEPORT
-- ============================================================

local tpPanel = tabPanels[2]

-- Noclip toggle
local noclipSec = makeSection(tpPanel, "── NOCLIP", 1)
local noclipRow = Instance.new("Frame")
noclipRow.Size = UDim2.new(1, 0, 0, 28); noclipRow.BackgroundTransparency = 1
noclipRow.LayoutOrder = 1; noclipRow.Parent = noclipSec

newLabel({
    Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Text = "👻 Noclip",
    TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.GothamBold,
    TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = noclipRow,
})

local noclipBtn = Instance.new("TextButton")
noclipBtn.Size = UDim2.new(0, 50, 0, 22); noclipBtn.Position = UDim2.new(1, -50, 0.5, -11)
noclipBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); noclipBtn.Text = "OFF"
noclipBtn.TextColor3 = Color3.fromRGB(160, 160, 160); noclipBtn.Font = Enum.Font.GothamBold
noclipBtn.TextSize = 10; noclipBtn.BorderSizePixel = 0; noclipBtn.Parent = noclipRow; newCorner(5, noclipBtn)

noclipBtn.MouseButton1Click:Connect(function()
    tpState.noclip = not tpState.noclip
    setToggleBtn(noclipBtn, tpState.noclip)
end)

-- Slot count selector
local slotCtrlSec = makeSection(tpPanel, "── TELEPORT SLOTS", 2)
local slotCtrlRow = Instance.new("Frame")
slotCtrlRow.Size = UDim2.new(1, 0, 0, 26); slotCtrlRow.BackgroundTransparency = 1
slotCtrlRow.LayoutOrder = 1; slotCtrlRow.Parent = slotCtrlSec

newLabel({
    Size = UDim2.new(0, 120, 1, 0), BackgroundTransparency = 1, Text = "Active Slots:",
    TextColor3 = Color3.fromRGB(160, 160, 160), Font = Enum.Font.GothamBold,
    TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = slotCtrlRow,
})

local function makeSmallBtn(text, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 26, 0, 22); btn.Position = UDim2.new(1, xPos, 0.5, -11)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 58); btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14; btn.BorderSizePixel = 0; btn.Parent = slotCtrlRow; newCorner(5, btn)
    return btn
end

local minusBtn = makeSmallBtn("−", -80)
local slotNumLbl = newLabel({
    Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -52, 0, 0),
    BackgroundTransparency = 1, Text = tostring(tpState.slotCount),
    TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold,
    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Parent = slotCtrlRow,
})
local plusBtn = makeSmallBtn("+", -28)

-- Slot cards
local slotFrames = {}

local function makeSlotCard(i)
    local s = tpState.slots[i]

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 52); card.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    card.BorderSizePixel = 0; card.LayoutOrder = i + 2
    card.Visible = i <= tpState.slotCount; card.Parent = tpPanel; newCorner(7, card)

    local nameLbl = newLabel({
        Size = UDim2.new(0, 100, 0, 18), Position = UDim2.new(0, 8, 0, 4),
        BackgroundTransparency = 1, Text = s.name, TextColor3 = Color3.fromRGB(210, 210, 210),
        Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
    })

    local editBtn = Instance.new("TextButton")
    editBtn.Size = UDim2.new(0, 36, 0, 18); editBtn.Position = UDim2.new(0, 108, 0, 4)
    editBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 90); editBtn.Text = "✏ Edit"
    editBtn.TextColor3 = Color3.fromRGB(160, 200, 255); editBtn.Font = Enum.Font.GothamBold
    editBtn.TextSize = 9; editBtn.BorderSizePixel = 0; editBtn.Parent = card; newCorner(4, editBtn)

    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(0, 142, 0, 20); nameBox.Position = UDim2.new(0, 6, 0, 4)
    nameBox.BackgroundColor3 = Color3.fromRGB(38, 38, 60); nameBox.Text = s.name
    nameBox.TextColor3 = Color3.fromRGB(220, 220, 255); nameBox.PlaceholderText = "Enter name..."
    nameBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 100); nameBox.Font = Enum.Font.GothamBold
    nameBox.TextSize = 11; nameBox.BorderSizePixel = 0; nameBox.ClearTextOnFocus = false
    nameBox.Visible = false; nameBox.Parent = card; newCorner(4, nameBox)

    local coordLbl = newLabel({
        Size = UDim2.new(1, -10, 0, 14), Position = UDim2.new(0, 8, 0, 6),
        BackgroundTransparency = 1, Text = "Not saved", TextColor3 = Color3.fromRGB(75, 75, 75),
        Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = card,
    })

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.48, -4, 0, 20); saveBtn.Position = UDim2.new(0, 6, 1, -24)
    saveBtn.BackgroundColor3 = Color3.fromRGB(28, 85, 48); saveBtn.Text = "💾 Save"
    saveBtn.TextColor3 = Color3.fromRGB(150, 255, 180); saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 10; saveBtn.BorderSizePixel = 0; saveBtn.Parent = card; newCorner(5, saveBtn)

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0.48, -4, 0, 20); tpBtn.Position = UDim2.new(0.5, 2, 1, -24)
    tpBtn.BackgroundColor3 = Color3.fromRGB(28, 48, 100); tpBtn.Text = "⚡ Teleport"
    tpBtn.TextColor3 = Color3.fromRGB(150, 180, 255); tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 10; tpBtn.BorderSizePixel = 0; tpBtn.Parent = card; newCorner(5, tpBtn)

    local function refreshCoord()
        if s.x then
            coordLbl.Text       = string.format("X:%.1f  Y:%.1f  Z:%.1f", s.x, s.y, s.z)
            coordLbl.TextColor3 = Color3.fromRGB(100, 200, 120)
        else
            coordLbl.Text       = "Not saved"
            coordLbl.TextColor3 = Color3.fromRGB(75, 75, 75)
        end
    end
    refreshCoord()

    editBtn.MouseButton1Click:Connect(function()
        nameBox.Text = s.name; nameBox.Visible = true
        nameLbl.Visible = false; editBtn.Visible = false; nameBox:CaptureFocus()
    end)
    nameBox.FocusLost:Connect(function()
        local n = nameBox.Text ~= "" and nameBox.Text or ("Slot " .. i)
        s.name = n; nameLbl.Text = n
        nameBox.Visible = false; nameLbl.Visible = true; editBtn.Visible = true
    end)
    saveBtn.MouseButton1Click:Connect(function()
        local root = getRoot(); if not root then return end
        s.x = math.floor(root.Position.X * 10) / 10
        s.y = math.floor(root.Position.Y * 10) / 10
        s.z = math.floor(root.Position.Z * 10) / 10
        refreshCoord()
        saveBtn.BackgroundColor3 = Color3.fromRGB(20, 140, 60)
        task.delay(0.5, function() saveBtn.BackgroundColor3 = Color3.fromRGB(28, 85, 48) end)
    end)
    tpBtn.MouseButton1Click:Connect(function()
        if not s.x then return end
        local root = getRoot(); if not root then return end
        root.CFrame = CFrame.new(s.x, s.y, s.z)
        tpBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 180)
        task.delay(0.5, function() tpBtn.BackgroundColor3 = Color3.fromRGB(28, 48, 100) end)
    end)

    slotFrames[i] = card
end

for i = 1, 10 do makeSlotCard(i) end

local function refreshSlots()
    slotNumLbl.Text = tostring(tpState.slotCount)
    for i = 1, 10 do slotFrames[i].Visible = i <= tpState.slotCount end
end
minusBtn.MouseButton1Click:Connect(function()
    if tpState.slotCount > 1  then tpState.slotCount -= 1; refreshSlots() end
end)
plusBtn.MouseButton1Click:Connect(function()
    if tpState.slotCount < 10 then tpState.slotCount += 1; refreshSlots() end
end)

-- ============================================================
-- // TAB 3: SPECTATE
-- ============================================================

local specPanel        = tabPanels[3]
local playerBtns       = {}
local selectedPlayerBtn = nil

-- specStatusLbl and returnBtn are now the pinned SpecPinnedStatus and SpecExitBtn
-- Keep references pointing to the pinned versions
local specStatusLbl = SpecPinnedStatus
local returnBtn     = SpecExitBtn

returnBtn.MouseButton1Click:Connect(function()
    stopSpectate()
    specStatusLbl.Text       = "Not spectating"
    specStatusLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
    if selectedPlayerBtn then
        selectedPlayerBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
        selectedPlayerBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
        selectedPlayerBtn = nil
    end
end)

-- Search bar
local searchSec = makeSection(specPanel, "── SEARCH", 0)
local searchBox = Instance.new("TextBox")
searchBox.Size             = UDim2.new(1, 0, 0, 26)
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
searchBox.Text             = ""
searchBox.PlaceholderText  = "🔍  Type to search players..."
searchBox.PlaceholderColor3= Color3.fromRGB(80, 80, 100)
searchBox.TextColor3       = Color3.fromRGB(220, 220, 220)
searchBox.Font             = Enum.Font.Gotham
searchBox.TextSize         = 11
searchBox.BorderSizePixel  = 0
searchBox.ClearTextOnFocus = false
searchBox.LayoutOrder      = 1
searchBox.Parent           = searchSec
newCorner(5, searchBox)
Instance.new("UIPadding", searchBox).PaddingLeft = UDim.new(0, 8)

local playerListSec = makeSection(specPanel, "── PLAYERS", 1)

local searchQuery = ""

local function refreshPlayerList()
    for _, b in ipairs(playerBtns) do b:Destroy() end
    playerBtns = {}

    -- Get all players except self
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            table.insert(list, plr)
        end
    end

    -- Sort alphabetically by DisplayName
    table.sort(list, function(a, b)
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)

    local order   = 1
    local shown   = 0
    local query   = searchQuery:lower()

    for _, plr in ipairs(list) do
        -- Filter: only show if display name starts with search query
        if query ~= "" and not plr.DisplayName:lower():sub(1, #query) == query then
            continue
        end
        -- Also accept if starts with query
        if query ~= "" then
            local nameStart = plr.DisplayName:lower():sub(1, #query)
            if nameStart ~= query then continue end
        end

        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
        btn.Text             = "👤  " .. plr.DisplayName .. "  (@" .. plr.Name .. ")"
        btn.TextColor3       = Color3.fromRGB(200, 200, 200)
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 11
        btn.BorderSizePixel  = 0
        btn.TextXAlignment   = Enum.TextXAlignment.Left
        btn.LayoutOrder      = order
        btn.Parent           = playerListSec
        newCorner(6, btn)
        Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 8)

        btn.MouseButton1Click:Connect(function()
            spectatePlayer(plr)
            specStatusLbl.Text       = "👁  " .. plr.DisplayName
            specStatusLbl.TextColor3 = Color3.fromRGB(100, 200, 255)
            for _, b in ipairs(playerBtns) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
                    b.TextColor3       = Color3.fromRGB(200, 200, 200)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(28, 55, 90)
            btn.TextColor3       = Color3.fromRGB(150, 200, 255)
            selectedPlayerBtn    = btn
        end)

        table.insert(playerBtns, btn)
        order  += 1
        shown  += 1
    end

    if shown == 0 then
        local msg = query ~= "" and ("No players matching "" .. searchQuery .. """) or "No other players in server"
        local e = newLabel({
            Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
            Text = msg, TextColor3 = Color3.fromRGB(65, 65, 65),
            Font = Enum.Font.Gotham, TextSize = 10, LayoutOrder = 1, Parent = playerListSec,
        })
        table.insert(playerBtns, e)
    end
end

-- Live search: filter as you type
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = searchBox.Text
    refreshPlayerList()
end)

refreshPlayerList()

local refreshSec = makeSection(specPanel, "", 2)
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1, 0, 0, 24); refreshBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
refreshBtn.Text = "🔄  Refresh Player List"; refreshBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
refreshBtn.Font = Enum.Font.GothamBold; refreshBtn.TextSize = 10; refreshBtn.BorderSizePixel = 0
refreshBtn.LayoutOrder = 1; refreshBtn.Parent = refreshSec; newCorner(6, refreshBtn)
refreshBtn.MouseButton1Click:Connect(refreshPlayerList)

Players.PlayerAdded:Connect(function() task.wait(0.5); refreshPlayerList() end)
Players.PlayerRemoving:Connect(function(plr)
    task.wait(0.1)
    if specState.target == plr then
        stopSpectate()
        specStatusLbl.Text       = "Target left the game"
        specStatusLbl.TextColor3 = Color3.fromRGB(220, 80, 80)
        selectedPlayerBtn = nil
    end
    refreshPlayerList()
end)

-- ============================================================
-- // INPUT
-- ============================================================

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.K then
        Win.Visible = not Win.Visible

    elseif input.KeyCode == Enum.KeyCode.L then
        -- Stop follow mouse
        afkState.follow.on = false
        afkState.follow.elapsed = 0
        followBar.Size = UDim2.new(0, 0, 1, 0)
        setToggleBtn(followToggle, false)
        -- Stop all fixed clickers
        for i = 1, 6 do
            afkState.fixed[i].on = false
            afkState.fixed[i].elapsed = 0
            fixedBars[i].Size = UDim2.new(0, 0, 1, 0)
            setToggleBtn(fixedToggles[i], false)
        end
        print("[AkumaMenu] All autoclickers stopped (L key)")
    end
end)

-- Capture is now handled via per-slot one-shot InputBegan connections (see AFK section)

-- ============================================================
-- // RUNTIME LOOPS
-- ============================================================

RunService.Heartbeat:Connect(function(dt)
    local dtms = dt * 1000
    local mp   = UserInputService:GetMouseLocation()
    local root = getRoot()

    PinnedMouseLbl.Text = string.format("M: %d, %d", math.floor(mp.X), math.floor(mp.Y))
    PinnedCoordLbl.Text = root
        and string.format("X:%.1f  Y:%.1f  Z:%.1f", root.Position.X, root.Position.Y, root.Position.Z)
        or  "X: —   Y: —   Z: —"

    if afkState.jump.on then
        afkState.jump.elapsed += dtms
        jumpBar.Size = UDim2.new(math.min(afkState.jump.elapsed / afkState.jump.interval, 1), 0, 1, 0)
        if afkState.jump.elapsed >= afkState.jump.interval then afkState.jump.elapsed = 0; doJump() end
    end

    if afkState.follow.on then
        afkState.follow.elapsed += dtms
        followBar.Size = UDim2.new(math.min(afkState.follow.elapsed / afkState.follow.interval, 1), 0, 1, 0)
        if afkState.follow.elapsed >= afkState.follow.interval then afkState.follow.elapsed = 0; doFollowClick() end
    end

    for i = 1, 6 do
        local s = afkState.fixed[i]
        if s.on then
            s.elapsed += dtms
            fixedBars[i].Size = UDim2.new(math.min(s.elapsed / s.interval, 1), 0, 1, 0)
            if s.elapsed >= s.interval then s.elapsed = 0; doFixedClick(s.x, s.y) end
        end
    end
end)

RunService.Stepped:Connect(function()
    if not tpState.noclip then return end
    local c = LP.Character; if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    if tpState.noclip then setToggleBtn(noclipBtn, true) end
end)

-- ============================================================
-- // GLASS — apply 0.5 transparency to all background frames
-- ============================================================

for _, obj in ipairs(ScreenGui:GetDescendants()) do
    if (obj:IsA("Frame") or obj:IsA("ScrollingFrame")) and obj.BackgroundTransparency < 0.4 then
        obj.BackgroundTransparency = 0.5
    end
end

print("[Akuma Menu v3] Loaded. K to toggle.")
