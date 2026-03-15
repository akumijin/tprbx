local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer

-- // Slot data
local MAX_SLOTS   = 10
local slotCount   = 3
local slots = {}
for i = 1, MAX_SLOTS do
    slots[i] = { name = "Slot " .. i, x = nil, y = nil, z = nil }
end

-- // Helpers
local function getRoot()
    local c = LP.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(slot)
    if not slot.x then return end
    local root = getRoot()
    if not root then return end
    root.CFrame = CFrame.new(slot.x, slot.y, slot.z)
end

local function saveToSlot(slot)
    local root = getRoot()
    if not root then return end
    slot.x = math.floor(root.Position.X * 10) / 10
    slot.y = math.floor(root.Position.Y * 10) / 10
    slot.z = math.floor(root.Position.Z * 10) / 10
end

-- // ===================== GUI =====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CoordTracker"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LP.PlayerGui

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

-- // Title bar
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

-- // Live coord display
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

-- // Slot count row
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

-- // Divider
local Div = Instance.new("Frame")
Div.Size = UDim2.new(1, -20, 0, 1)
Div.Position = UDim2.new(0, 10, 0, 112)
Div.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Div.BorderSizePixel = 0
Div.Parent = Main

-- // Slot UI storage
local slotFrames = {}

local SLOT_START_Y = 118
local SLOT_HEIGHT  = 54  -- height per slot including gap

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

    -- Top row: name label / Edit btn / coord display
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
    nameBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
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
    coordLabel.AnchorPoint = Vector2.new(0, 0)
    coordLabel.BackgroundTransparency = 1
    coordLabel.Text = "—"
    coordLabel.TextColor3 = Color3.fromRGB(100, 140, 100)
    coordLabel.Font = Enum.Font.Gotham
    coordLabel.TextSize = 10
    coordLabel.TextXAlignment = Enum.TextXAlignment.Right
    coordLabel.Parent = frame

    -- Bottom row: Save + TP buttons
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

    -- // Coord label updater
    local function refreshCoord()
        if s.x then
            coordLabel.Text = string.format(
                "X:%.1f  Y:%.1f  Z:%.1f", s.x, s.y, s.z)
            coordLabel.TextColor3 = Color3.fromRGB(100, 200, 120)
        else
            coordLabel.Text = "Not saved"
            coordLabel.TextColor3 = Color3.fromRGB(90, 90, 90)
        end
    end
    refreshCoord()

    -- // Edit toggle
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

    nameBox.FocusLost:Connect(function(enterPressed)
        editing = false
        local newName = nameBox.Text
        if newName == "" then newName = "Slot " .. i end
        s.name = newName
        nameLabel.Text = newName
        nameBox.Visible = false
        nameLabel.Visible = true
        editBtn.Visible = true
    end)

    -- // Save current position
    saveBtn.MouseButton1Click:Connect(function()
        saveToSlot(s)
        refreshCoord()
        -- Flash green
        saveBtn.BackgroundColor3 = Color3.fromRGB(20, 140, 60)
        task.delay(0.5, function()
            saveBtn.BackgroundColor3 = Color3.fromRGB(30, 90, 50)
        end)
        print(string.format("[Slot %d: %s] Saved → X:%.1f Y:%.1f Z:%.1f",
            i, s.name, s.x, s.y, s.z))
    end)

    -- // Teleport
    tpBtn.MouseButton1Click:Connect(function()
        if not s.x then return end
        teleportTo(s)
        -- Flash blue
        tpBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 180)
        task.delay(0.5, function()
            tpBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 100)
        end)
        print(string.format("[Slot %d: %s] Teleported → X:%.1f Y:%.1f Z:%.1f",
            i, s.name, s.x, s.y, s.z))
    end)

    slotFrames[i] = frame
end

-- Build all 10 slot UIs (only slotCount are visible)
for i = 1, MAX_SLOTS do
    makeSlotUI(i)
end

-- // Resize frame based on slot count
local function refreshLayout()
    SlotNumLbl.Text = tostring(slotCount)
    for i = 1, MAX_SLOTS do
        slotFrames[i].Visible = i <= slotCount
    end
    local totalH = SLOT_START_Y + (slotCount * SLOT_HEIGHT) + 6
    Main.Size = UDim2.new(0, 300, 0, totalH)
end
refreshLayout()

-- // Slot count buttons
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

-- // Keybind
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        Main.Visible = not Main.Visible
    end
end)

-- // Live coord update
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

print("[Coord Tracker] Loaded. K to toggle menu.")