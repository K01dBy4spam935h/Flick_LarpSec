--[[
    FlickUI · Linoria-inspired · pure Luau · OOP
    Library.new() → Window → Tab → Groupbox → Toggle/Slider/Dropdown/Label
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

local Theme = {
    Background = Color3.fromRGB(21, 21, 21),   -- #151515
    Groupbox   = Color3.fromRGB(30, 30, 30),   -- #1e1e1e
    Border     = Color3.fromRGB(46, 46, 46),   -- #2e2e2e
    Text       = Color3.fromRGB(255, 255, 255),
    TextDim    = Color3.fromRGB(170, 170, 170), -- #aaaaaa
    Accent     = Color3.fromRGB(74, 144, 226), -- #4a90e2
    Dark       = Color3.fromRGB(18, 18, 18),
    Hover      = Color3.fromRGB(40, 40, 40),
}

local Library = {}
Library.__index = Library

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Groupbox = {}
Groupbox.__index = Groupbox

-- ─── utils ───────────────────────────────────────────────────
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function Round(n)
    return math.floor(n + 0.5)
end

-- ─── Library ─────────────────────────────────────────────────
function Library.new(opts)
    opts = opts or {}
    local self = setmetatable({
        Title       = opts.Title or "Flick",
        ToggleKey   = opts.ToggleKey or Enum.KeyCode.RightShift,
        Connections = {},
        Windows     = {},
        UnloadFlag  = false,
    }, Library)

    local gui = Create("ScreenGui", {
        Name = "FlickLib",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    self.ScreenGui = gui

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self.ToggleKey then
            for _, win in ipairs(self.Windows) do
                win.Frame.Visible = not win.Frame.Visible
            end
        end
    end))

    return self
end

function Library:CreateWindow(opts)
    opts = opts or {}
    local win = setmetatable({
        Library     = self,
        Title       = opts.Title or self.Title,
        Size        = opts.Size or Vector2.new(550, 450),
        Tabs        = {},
        ActiveTab   = nil,
        Connections = {},
    }, Window)

    local frame = Create("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(win.Size.X, win.Size.Y),
        Position = UDim2.new(0.5, -win.Size.X / 2, 0.5, -win.Size.Y / 2),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        Parent = self.ScreenGui,
    })
    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = frame })
    win.Frame = frame

    -- top bar
    local top = Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Theme.Dark,
        BorderSizePixel = 0,
        Parent = frame,
    })
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = top,
    })
    Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = win.Title,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = top,
    })
    local closeBtn = Create("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -28, 0, 0),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Theme.TextDim,
        TextSize = 16,
        Font = Enum.Font.Code,
        Parent = top,
    })
    closeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
    end)

    -- sidebar
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 120, 1, -28),
        Position = UDim2.fromOffset(0, 28),
        BackgroundColor3 = Theme.Dark,
        BorderSizePixel = 0,
        Parent = frame,
    })
    Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    local tabList = Create("Frame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
        Parent = tabList,
    })
    win.Sidebar = tabList

    -- content
    local content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -120, 1, -28),
        Position = UDim2.fromOffset(120, 28),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = frame,
    })
    win.Content = content

    -- drag (top bar only)
    local dragging, dragStart, startPos
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    top.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    table.insert(win.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    table.insert(self.Windows, win)
    return win
end

function Library:Unload()
    self.UnloadFlag = true
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, win in ipairs(self.Windows) do
        for _, conn in ipairs(win.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        if win.Frame then win.Frame:Destroy() end
    end
    if self.ScreenGui then self.ScreenGui:Destroy() end
end

-- ─── Window ──────────────────────────────────────────────────
function Window:CreateTab(name)
    local tab = setmetatable({
        Window      = self,
        Name        = name,
        Groupboxes  = {},
        Connections = {},
    }, Tab)

    local btn = Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Theme.Dark,
        BorderSizePixel = 0,
        Text = "  " .. name,
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = self.Sidebar,
    })
    local indicator = Create("Frame", {
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = btn,
    })
    tab.Button = btn
    tab.Indicator = indicator

    local page = Create("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = self.Content,
    })
    local holder = Create("Frame", {
        Name = "Holder",
        Size = UDim2.new(1, -12, 0, 0),
        Position = UDim2.fromOffset(6, 6),
        BackgroundTransparency = 1,
        Parent = page,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = holder,
    })
    -- two columns
    local leftCol = Create("Frame", {
        Name = "Left",
        Size = UDim2.new(0.5, -3, 0, 0),
        BackgroundTransparency = 1,
        Parent = holder,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = leftCol,
    })
    local rightCol = Create("Frame", {
        Name = "Right",
        Size = UDim2.new(0.5, -3, 0, 0),
        BackgroundTransparency = 1,
        Parent = holder,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = rightCol,
    })
    tab.Page = page
    tab.Left = leftCol
    tab.Right = rightCol
    tab.Holder = holder

    local function refreshCanvas()
        local lh = leftCol.UIListLayout.AbsoluteContentSize.Y
        local rh = rightCol.UIListLayout.AbsoluteContentSize.Y
        local h = math.max(lh, rh) + 20
        leftCol.Size = UDim2.new(0.5, -3, 0, lh)
        rightCol.Size = UDim2.new(0.5, -3, 0, rh)
        holder.Size = UDim2.new(1, -12, 0, h)
        page.CanvasSize = UDim2.new(0, 0, 0, h + 12)
    end
    tab.Refresh = refreshCanvas
    leftCol.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)
    rightCol.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

    btn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    return tab
end

function Window:SelectTab(tab)
    for _, t in ipairs(self.Tabs) do
        t.Page.Visible = false
        t.Button.BackgroundColor3 = Theme.Dark
        t.Button.TextColor3 = Theme.TextDim
        t.Indicator.Visible = false
    end
    tab.Page.Visible = true
    tab.Button.BackgroundColor3 = Theme.Background
    tab.Button.TextColor3 = Theme.Text
    tab.Indicator.Visible = true
    self.ActiveTab = tab
end

-- ─── Tab ─────────────────────────────────────────────────────
function Tab:CreateGroupbox(title, side)
    side = side or "Left"
    local parent = (side == "Right") and self.Right or self.Left

    local gb = setmetatable({
        Tab         = self,
        Title       = title,
        Elements    = {},
        Connections = {},
    }, Groupbox)

    local frame = Create("Frame", {
        Name = title,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Theme.Groupbox,
        BorderSizePixel = 0,
        Parent = parent,
    })
    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = frame })

    local header = Create("TextLabel", {
        Size = UDim2.new(1, -8, 0, 20),
        Position = UDim2.fromOffset(6, 2),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local body = Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, -8, 0, 0),
        Position = UDim2.fromOffset(4, 22),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
        Parent = body,
    })
    gb.Frame = frame
    gb.Body = body

    local function resize()
        local h = body.UIListLayout.AbsoluteContentSize.Y
        body.Size = UDim2.new(1, -8, 0, h)
        frame.Size = UDim2.new(1, 0, 0, h + 28)
        if self.Refresh then self.Refresh() end
    end
    gb.Resize = resize
    body.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)

    table.insert(self.Groupboxes, gb)
    return gb
end

-- ─── Groupbox elements ───────────────────────────────────────
function Groupbox:AddSection(text)
    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Body,
    })
    Create("TextLabel", {
        Size = UDim2.new(1, -4, 0, 13),
        Position = UDim2.fromOffset(2, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    -- stronger underline
    Create("Frame", {
        Size = UDim2.new(1, -4, 0, 2),
        Position = UDim2.fromOffset(2, 15),
        BackgroundColor3 = Color3.fromRGB(70, 70, 78),
        BorderSizePixel = 0,
        Parent = row,
    })
    self.Resize()
    return row
end

function Groupbox:AddLabel(text)
    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Parent = self.Body,
    })
    Create("TextLabel", {
        Size = UDim2.new(1, -4, 1, 0),
        Position = UDim2.fromOffset(2, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    self.Resize()
    return row
end

function Groupbox:AddToggle(opts)
    opts = opts or {}
    local text = opts.Text or "Toggle"
    local default = opts.Default or false
    local callback = opts.Callback or function() end

    local state = default
    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Body,
    })
    Create("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.fromOffset(2, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local box = Create("TextButton", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(1, -18, 0.5, -7),
        BackgroundColor3 = state and Theme.Accent or Theme.Background,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = box })

    box.MouseButton1Click:Connect(function()
        state = not state
        box.BackgroundColor3 = state and Theme.Accent or Theme.Background
        callback(state)
    end)

    self.Resize()
    return {
        Set = function(_, v)
            state = v
            box.BackgroundColor3 = state and Theme.Accent or Theme.Background
            callback(state)
        end,
        Get = function() return state end,
    }
end

function Groupbox:AddSlider(opts)
    opts = opts or {}
    local text = opts.Text or "Slider"
    local min = opts.Min or 0
    local max = opts.Max or 100
    local default = opts.Default or min
    local callback = opts.Callback or function() end
    local suffix = opts.Suffix or ""

    local value = default
    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = self.Body,
    })
    local label = Create("TextLabel", {
        Size = UDim2.new(1, -4, 0, 14),
        Position = UDim2.fromOffset(2, 0),
        BackgroundTransparency = 1,
        Text = string.format("%s: %s%s [%s/%s]", text, tostring(value), suffix, tostring(min), tostring(max)),
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local track = Create("Frame", {
        Size = UDim2.new(1, -4, 0, 6),
        Position = UDim2.fromOffset(2, 18),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = row,
    })
    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = track })
    local fill = Create("Frame", {
        Name = "SliderFill",
        Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    do
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Color3.new(
                math.min(1, Theme.Accent.R + 0.2),
                math.min(1, Theme.Accent.G + 0.2),
                math.min(1, Theme.Accent.B + 0.15)
            )),
        })
        g.Rotation = 0
        g.Parent = fill
    end

    local dragging = false
    local function update(inputX)
        local rel = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = Round(min + (max - min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        label.Text = string.format("%s: %s%s [%s/%s]", text, tostring(value), suffix, tostring(min), tostring(max))
        callback(value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position.X)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end))
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    self.Resize()
    return {
        Set = function(_, v)
            value = math.clamp(Round(v), min, max)
            local rel = (value - min) / math.max(max - min, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            label.Text = string.format("%s: %s%s [%s/%s]", text, tostring(value), suffix, tostring(min), tostring(max))
            callback(value)
        end,
        Get = function() return value end,
    }
end

function Groupbox:AddDropdown(opts)
    opts = opts or {}
    local text = opts.Text or "Dropdown"
    local values = opts.Values or {"Option"}
    local default = opts.Default or values[1]
    local callback = opts.Callback or function() end

    local current = default
    local open = false

    local row = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Parent = self.Body,
        ClipsDescendants = false,
        ZIndex = 5,
    })
    Create("TextLabel", {
        Size = UDim2.new(1, -4, 0, 14),
        Position = UDim2.fromOffset(2, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.TextDim,
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local btn = Create("TextButton", {
        Size = UDim2.new(1, -4, 0, 18),
        Position = UDim2.fromOffset(2, 16),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Text = "  " .. tostring(current),
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ZIndex = 6,
        Parent = row,
    })
    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = btn })

    local list = Create("Frame", {
        Size = UDim2.new(1, -4, 0, 0),
        Position = UDim2.fromOffset(2, 36),
        BackgroundColor3 = Theme.Groupbox,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
        Parent = row,
    })
    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = list })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = list,
    })

    local function rebuild()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, v in ipairs(values) do
            local opt = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = Theme.Groupbox,
                BorderSizePixel = 0,
                Text = "  " .. tostring(v),
                TextColor3 = Theme.Text,
                TextSize = 12,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                ZIndex = 21,
                Parent = list,
            })
            opt.MouseEnter:Connect(function()
                opt.BackgroundColor3 = Theme.Hover
            end)
            opt.MouseLeave:Connect(function()
                opt.BackgroundColor3 = Theme.Groupbox
            end)
            opt.MouseButton1Click:Connect(function()
                current = v
                btn.Text = "  " .. tostring(current)
                open = false
                list.Visible = false
                list.Size = UDim2.new(1, -4, 0, 0)
                row.Size = UDim2.new(1, 0, 0, 38)
                self.Resize()
                callback(current)
            end)
        end
    end
    rebuild()

    btn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            local h = #values * 18
            list.Size = UDim2.new(1, -4, 0, h)
            list.Visible = true
            row.Size = UDim2.new(1, 0, 0, 38 + h)
        else
            list.Visible = false
            list.Size = UDim2.new(1, -4, 0, 0)
            row.Size = UDim2.new(1, 0, 0, 38)
        end
        self.Resize()
    end)

    self.Resize()
    return {
        Set = function(_, v)
            current = v
            btn.Text = "  " .. tostring(current)
            callback(current)
        end,
        Get = function() return current end,
        SetValues = function(_, newVals)
            values = newVals
            rebuild()
        end,
    }
end

return Library
