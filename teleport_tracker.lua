-- // ===================== KEY SYSTEM =====================

local KEY_URL = "https://raw.githubusercontent.com/akumijin/tprbx/main/key.txt"

local keyOk, VALID_KEY = pcall(function()
    return game:HttpGet(KEY_URL):gsub("%s+", "")
end)

if not keyOk or not VALID_KEY or VALID_KEY == "" then
    warn("[KeySystem] Could not fetch key from GitHub. Check repo URL or internet.")
    return
end

local lp = game:GetService("Players").LocalPlayer

-- Key GUI
local ksg = Instance.new("ScreenGui")
ksg.ResetOnSpawn = false
ksg.Name = "AkumaKeySystem"
ksg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ksg.Parent = lp.PlayerGui

local kframe = Instance.new("Frame")
kframe.Size = UDim2.new(0, 290, 0, 140)
kframe.Position = UDim2.new(0.5, -145, 0.5, -70)
kframe.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
kframe.BorderSizePixel = 0
kframe.Active = true
kframe.Parent = ksg
Instance.new("UICorner", kframe).CornerRadius = UDim.new(0, 10)

local kstroke = Instance.new("UIStroke")
kstroke.Color = Color3.fromRGB(55, 55, 55)
kstroke.Thickness = 1.2
kstroke.Parent = kframe

local ktitlebar = Instance.new("Frame")
ktitlebar.Size = UDim2.new(1, 0, 0, 36)
ktitlebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ktitlebar.BorderSizePixel = 0
ktitlebar.Parent = kframe
Instance.new("UICorner", ktitlebar).CornerRadius = UDim.new(0, 10)

local ktitle = Instance.new("TextLabel")
ktitle.Size = UDim2.new(1, 0, 1, 0)
ktitle.BackgroundTransparency = 1
ktitle.Text = "🔑  Akuma Scripts — Enter Key"
ktitle.TextColor3 = Color3.fromRGB(230, 230, 230)
ktitle.Font = Enum.Font.GothamBold
ktitle.TextSize = 12
ktitle.Parent = ktitlebar

local ksub = Instance.new("TextLabel")
ksub.Size = UDim2.new(1, -20, 0, 14)
ksub.Position = UDim2.new(0, 10, 0, 40)
ksub.BackgroundTransparency = 1
ksub.Text = "github.com/akumijin/tprbx"
ksub.TextColor3 = Color3.fromRGB(70, 70, 70)
ksub.Font = Enum.Font.Gotham
ksub.TextSize = 10
ksub.TextXAlignment = Enum.TextXAlignment.Left
ksub.Parent = kframe

local kbox = Instance.new("TextBox")
kbox.Size = UDim2.new(1, -20, 0, 30)
kbox.Position = UDim2.new(0, 10, 0, 58)
kbox.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
kbox.Text = ""
kbox.PlaceholderText = "Enter your key here..."
kbox.PlaceholderColor3 = Color3.fromRGB(75, 75, 75)
kbox.TextColor3 = Color3.fromRGB(220, 220, 220)
kbox.Font = Enum.Font.Gotham
kbox.TextSize = 12
kbox.BorderSizePixel = 0
kbox.ClearTextOnFocus = false
kbox.Parent = kframe
Instance.new("UICorner", kbox).CornerRadius = UDim.new(0, 6)

local kstroke2 = Instance.new("UIStroke")
kstroke2.Color = Color3.fromRGB(45, 45, 45)
kstroke2.Thickness = 1
kstroke2.Parent = kbox

local kstatus = Instance.new("TextLabel")
kstatus.Size = UDim2.new(1, -20, 0, 14)
kstatus.Position = UDim2.new(0, 10, 0, 92)
kstatus.BackgroundTransparency = 1
kstatus.Text = ""
kstatus.TextColor3 = Color3.fromRGB(220, 80, 80)
kstatus.Font = Enum.Font.Gotham
kstatus.TextSize = 10
kstatus.TextXAlignment = Enum.TextXAlignment.Left
kstatus.Parent = kframe

local ksubmit = Instance.new("TextButton")
ksubmit.Size = UDim2.new(1, -20, 0, 26)
ksubmit.Position = UDim2.new(0, 10, 0, 108)
ksubmit.BackgroundColor3 = Color3.fromRGB(30, 80, 140)
ksubmit.Text = "Submit"
ksubmit.TextColor3 = Color3.fromRGB(255, 255, 255)
ksubmit.Font = Enum.Font.GothamBold
ksubmit.TextSize = 12
ksubmit.BorderSizePixel = 0
ksubmit.Parent = kframe
Instance.new("UICorner", ksubmit).CornerRadius = UDim.new(0, 6)

-- Wait for correct key
local verified = Instance.new("BindableEvent")

local function trySubmit()
    local entered = kbox.Text:gsub("%s+", "")
    if entered == VALID_KEY then
        ksg:Destroy()
        verified:Fire()
    else
        kstatus.Text = "❌  Invalid key. Try again."
        kbox.BackgroundColor3 = Color3.fromRGB(55, 18, 18)
        task.delay(0.6, function()
            kbox.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            kstatus.Text = ""
        end)
    end
end

ksubmit.MouseButton1Click:Connect(trySubmit)
kbox.FocusLost:Connect(function(enter)
    if enter then trySubmit() end
end)

verified.Event:Wait()
verified:Destroy()

-- // ===================== TELEPORT TRACKER =====================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MAX_SLOTS  = 10
local slotCount  = 3
local slots = {}
for i = 1, MAX_SLOTS do
    slots[i] = { name = "Slot " .. i, x = nil, y = nil, z = nil }
end

local function getRoot()
    local c = lp.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function saveToSlot(slot)
    local root = getRoot()
    if not root then return end
    slot.x = math.floor(root.Position.X * 10) / 10
    slot.y = math.floor(root.Position.Y * 10) / 10
    slot.z = math.floor(root.Position.Z * 10) / 10
end

local function teleportTo(slot)
    if not slot.x then return end
    local root = getRoot()
    if not root then return end
    root.CFrame = CFrame.new(slot.x, slot.y, slot.z)
end

-- // GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CoordTracker"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = lp.PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 100)
Main.Position = UDim2.new(0, 20, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = false
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(55, 55, 55)
Stroke.Thickness = 1.2
Stroke.Parent = Main

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -10, 1, 0)
TitleLbl.Position = UDim2.new(0, 10, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "📍  Coordinate Tracker"
TitleLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 13
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TitleBar

local KeyHint = Instance.new("TextLabel")
KeyHint.Size = UDim2.new(0, 80, 1, 0)
KeyHint.Position = UDim2.new(1, -85, 0, 0)
KeyHint.BackgroundTransparency = 1
KeyHint.Text = "K = hide"
KeyHint.TextColor3 = Color3.fromRGB(70, 70, 70)
KeyHint.Font = Enum.Font.Gotham
KeyHint.TextSize = 10
KeyHint.TextXAlignment = Enum.TextXAlignment.Right
KeyHint.Parent = TitleBar

-- Live coord display
local CoordBg = Instance.new("Frame")
CoordBg.Size = UDim2.new(1, -20, 0, 32)
CoordBg.Position = UDim2.new(0, 10, 0, 42)
CoordBg.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
CoordBg.BorderSizePixel = 0
CoordBg.Parent = Main
Instance.new("UICorner", CoordBg).CornerRadius = UDim.new(0, 6)

local CoordLbl = Instance.new("TextLabel")
CoordLbl.Size = UDim2.new(1, -10, 1, 0)
CoordLbl.Position = UDim2.new(0, 8, 0, 0)
CoordLbl.BackgroundTransparency = 1
CoordLbl.Text = "X: —    Y: —    Z: —"
CoordLbl.TextColor3 = Color3.fromRGB(100, 220, 140)
CoordLbl.Font = Enum.Font.GothamBold
CoordLbl.TextSize = 12
CoordLbl.TextXAlignment = Enum.TextXAlignment.Left
CoordLbl.Parent = CoordBg

-- Slot count row
local SlotCountRow = Instance.new("Frame")
SlotCountRow.Size = UDim2.new(1, -20, 0, 26)
SlotCountRow.Position = UDim2.new(0, 10, 0, 80)
SlotCountRow.BackgroundTransparency = 1
SlotCountRow.Parent = Main

local SlotCountLbl = Instance.new("TextLabel")
SlotCountLbl.Size = UDim2.new(0, 120, 1, 0)
SlotCountLbl.BackgroundTransparency = 1
SlotCountLbl.Text = "Teleport Slots:"
SlotCountLbl.TextColor3 = Color3.fromRGB(160, 160, 160)
SlotCountLbl.Font = Enum.Font.GothamBold
SlotCountLbl.TextSize = 11
SlotCountLbl.TextXAlignment = Enum.TextXAlignment.Left
SlotCountLbl.Parent = SlotCountRow

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 26, 0, 22)
MinusBtn.Position = UDim2.new(1, -80, 0.5, -11)
MinusBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MinusBtn.Text = "−"
MinusBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.TextSize = 14
MinusBtn.BorderSizePixel = 0
MinusBtn.Parent = SlotCountRow
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 5)

local SlotNumLbl = Instance.new("TextLabel")
SlotNumLbl.Size = UDim2.new(0, 24, 1, 0)
SlotNumLbl.Position = UDim2.new(1, -52, 0, 0)
SlotNumLbl.BackgroundTransparency = 1
SlotNumLbl.Text = tostring(slotCount)
SlotNumLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
SlotNumLbl.Font = Enum.Font.GothamBold
SlotNumLbl.TextSize = 13
SlotNumLbl.TextXAlignment = Enum.TextXAlignment.Center
SlotNumLbl.Parent = SlotCountRow

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 26, 0, 22)
PlusBtn.Position = UDim2.new(1, -28, 0.5, -11)
PlusBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.TextSize = 14
PlusBtn.BorderSizePixel = 0
PlusBtn.Parent = SlotCountRow
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 5)

-- Divider
local Div = Instance.new("Frame")
Div.Size = UDim2.new(1, -20, 0, 1)
Div.Position = UDim2.new(0, 10, 0, 112)
Div.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Div.BorderSizePixel = 0
Div.Parent = Main

-- // Slot UI
local slotFrames = {}
local SLOT_START_Y = 118
local SLOT_HEIGHT  = 54

local function makeSlotUI(i)
    local s = slots[i]

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 48)
    frame.Position = UDim2.new(0, 10, 0, SLOT_START_Y + (i - 1) * SLOT_HEIGHT)
    frame.BackgroundColor3 = Color3.fromRGB(19, 19, 19)
    frame.BorderSizePixel = 0
    frame.Visible = i <= slotCount
    frame.Parent = Main
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 100, 0, 20)
    nameLabel.Position = UDim2.new(0, 8, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = s.name
    nameLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 11
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = frame

    -- Edit button
    local editBtn = Instance.new("TextButton")
    editBtn.Size = UDim2.new(0, 36, 0, 18)
    editBtn.Position = UDim2.new(0, 108, 0, 6)
    editBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
    editBtn.Text = "✏ Edit"
    editBtn.TextColor3 = Color3.fromRGB(160, 200, 255)
    editBtn.Font = Enum.Font.GothamBold
    editBtn.TextSize = 9
    editBtn.BorderSizePixel = 0
    editBtn.Parent = frame
    Instance.new("UICorner", editBtn).CornerRadius = UDim.new(0, 4)

    -- Name textbox (hidden by default)
    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(0, 142, 0, 20)
    nameBox.Position = UDim2.new(0, 6, 0, 5)
    nameBox.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
    nameBox.Text = s.name
    nameBox.TextColor3 = Color3.fromRGB(220, 220, 255)
    nameBox.PlaceholderText = "Enter name..."
    nameBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
    nameBox.Font = Enum.Font.GothamBold
    nameBox.TextSize = 11
    nameBox.BorderSizePixel = 0
    nameBox.ClearTextOnFocus = false
    nameBox.Visible = false
    nameBox.Parent = frame
    Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 4)

    -- Coord label
    local coordLabel = Instance.new("TextLabel")
    coordLabel.Size = UDim2.new(1, -10, 0, 16)
    coordLabel.Position = UDim2.new(0, 8, 0, 8)
    coordLabel.BackgroundTransparency = 1
    coordLabel.Text = "Not saved"
    coordLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    coordLabel.Font = Enum.Font.Gotham
    coordLabel.TextSize = 10
    coordLabel.TextXAlignment = Enum.TextXAlignment.Right
    coordLabel.Parent = frame

    -- Save button
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.48, -4, 0, 20)
    saveBtn.Position = UDim2.new(0, 6, 1, -24)
    saveBtn.BackgroundColor3 = Color3.fromRGB(30, 90, 50)
    saveBtn.Text = "💾 Save"
    saveBtn.TextColor3 = Color3.fromRGB(150, 255, 180)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 10
    saveBtn.BorderSizePixel = 0
    saveBtn.Parent = frame
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 5)

    -- Teleport button
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0.48, -4, 0, 20)
    tpBtn.Position = UDim2.new(0.5, 2, 1, -24)
    tpBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 100)
    tpBtn.Text = "⚡ Teleport"
    tpBtn.TextColor3 = Color3.fromRGB(150, 180, 255)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 10
    tpBtn.BorderSizePixel = 0
    tpBtn.Parent = frame
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)

    -- Coord refresh
    local function refreshCoord()
        if s.x then
            coordLabel.Text = string.format(
                "X:%.1f  Y:%.1f  Z:%.1f", s.x, s.y, s.z)
            coordLabel.TextColor3 = Color3.fromRGB(100, 200, 120)
        else
            coordLabel.Text = "Not saved"
            coordLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
        end
    end
    refreshCoord()

    -- Edit logic
    local editing = false
    editBtn.MouseButton1Click:Connect(function()
        editing = not editing
        if editing then
            nameBox.Text = s.name
            nameBox.Visible = true
            nameLabel.Visible = false
            editBtn.Visible = false
            nameBox:CaptureFocus()
        end
    end)

    nameBox.FocusLost:Connect(function()
        editing = false
        local newName = nameBox.Text
        if newName == "" then newName = "Slot " .. i end
        s.name = newName
        nameLabel.Text = newName
        nameBox.Visible = false
        nameLabel.Visible = true
        editBtn.Visible = true
    end)

    -- Save
    saveBtn.MouseButton1Click:Connect(function()
        saveToSlot(s)
        refreshCoord()
        saveBtn.BackgroundColor3 = Color3.fromRGB(20, 140, 60)
        task.delay(0.5, function()
            saveBtn.BackgroundColor3 = Color3.fromRGB(30, 90, 50)
        end)
        print(string.format("[%s] Saved → X:%.1f  Y:%.1f  Z:%.1f",
            s.name, s.x, s.y, s.z))
    end)

    -- Teleport
    tpBtn.MouseButton1Click:Connect(function()
        if not s.x then return end
        teleportTo(s)
        tpBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 180)
        task.delay(0.5, function()
            tpBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 100)
        end)
        print(string.format("[%s] Teleported → X:%.1f  Y:%.1f  Z:%.1f",
            s.name, s.x, s.y, s.z))
    end)

    slotFrames[i] = frame
end

for i = 1, MAX_SLOTS do
    makeSlotUI(i)
end

-- Layout refresh
local function refreshLayout()
    SlotNumLbl.Text = tostring(slotCount)
    for i = 1, MAX_SLOTS do
        slotFrames[i].Visible = i <= slotCount
    end
    Main.Size = UDim2.new(0, 300, 0,
        SLOT_START_Y + (slotCount * SLOT_HEIGHT) + 6)
end
refreshLayout()

MinusBtn.MouseButton1Click:Connect(function()
    if slotCount > 1 then
        slotCount = slotCount - 1
        refreshLayout()
    end
end)

PlusBtn.MouseButton1Click:Connect(function()
    if slotCount < MAX_SLOTS then
        slotCount = slotCount + 1
        refreshLayout()
    end
end)

-- Keybind
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        Main.Visible = not Main.Visible
    end
end)

-- Live coord loop
RunService.Heartbeat:Connect(function()
    local root = getRoot()
    if root then
        local p = root.Position
        CoordLbl.Text = string.format(
            "X: %.1f    Y: %.1f    Z: %.1f", p.X, p.Y, p.Z)
    else
        CoordLbl.Text = "X: —    Y: —    Z: —"
    end
end)

print("[Coord Tracker] Loaded. K to toggle.")