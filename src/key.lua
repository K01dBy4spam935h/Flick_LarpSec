--[[
    LarpSec · Key gate
    Key: root
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local VALID = "root"

local Key = {}

function Key.Prompt()
    local done = Instance.new("BindableEvent")
    local passed = false

    local gui = Instance.new("ScreenGui")
    gui.Name = "LarpSecKey"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 16, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 20, 70)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 40, 50)),
    })
    grad.Rotation = 0
    grad.Parent = bg

    local blob1 = Instance.new("Frame")
    blob1.Size = UDim2.new(0, 280, 0, 280)
    blob1.Position = UDim2.new(0.15, 0, 0.2, 0)
    blob1.BackgroundColor3 = Color3.fromRGB(74, 144, 226)
    blob1.BackgroundTransparency = 0.85
    blob1.BorderSizePixel = 0
    blob1.Parent = bg
    Instance.new("UICorner", blob1).CornerRadius = UDim.new(1, 0)

    local blob2 = Instance.new("Frame")
    blob2.Size = UDim2.new(0, 220, 0, 220)
    blob2.Position = UDim2.new(0.65, 0, 0.55, 0)
    blob2.BackgroundColor3 = Color3.fromRGB(180, 80, 220)
    blob2.BackgroundTransparency = 0.88
    blob2.BorderSizePixel = 0
    blob2.Parent = bg
    Instance.new("UICorner", blob2).CornerRadius = UDim.new(1, 0)

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 340, 0, 220)
    card.Position = UDim2.new(0.5, -170, 0.5, -110)
    card.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.Parent = bg
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(74, 144, 226)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = card

    local cardGrad = Instance.new("UIGradient")
    cardGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 34, 55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 20, 28)),
    })
    cardGrad.Rotation = 90
    cardGrad.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 28)
    title.Position = UDim2.new(0, 12, 0, 16)
    title.BackgroundTransparency = 1
    title.Text = "LarpSec"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 22
    title.Font = Enum.Font.Fantasy
    title.Parent = card

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -24, 0, 18)
    sub.Position = UDim2.new(0, 12, 0, 46)
    sub.BackgroundTransparency = 1
    sub.Text = "enter key to continue"
    sub.TextColor3 = Color3.fromRGB(160, 170, 190)
    sub.TextSize = 13
    sub.Font = Enum.Font.Gotham
    sub.Parent = card

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -24, 0, 36)
    box.Position = UDim2.new(0, 12, 0, 80)
    box.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    box.BorderSizePixel = 0
    box.PlaceholderText = "key"
    box.PlaceholderColor3 = Color3.fromRGB(90, 95, 110)
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(240, 240, 255)
    box.TextSize = 15
    box.Font = Enum.Font.Code
    box.ClearTextOnFocus = false
    box.Parent = card
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(50, 60, 90)
    boxStroke.Thickness = 1
    boxStroke.Parent = box

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -24, 0, 16)
    status.Position = UDim2.new(0, 12, 0, 124)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 36)
    btn.Position = UDim2.new(0, 12, 0, 152)
    btn.BackgroundColor3 = Color3.fromRGB(74, 144, 226)
    btn.BorderSizePixel = 0
    btn.Text = "Unlock"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    card.Size = UDim2.new(0, 0, 0, 0)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 220),
        Position = UDim2.new(0.5, -170, 0.5, -110),
    }):Play()

    local anim = true
    task.spawn(function()
        local r = 0
        while anim and gui.Parent do
            r = (r + 0.4) % 360
            grad.Rotation = r
            cardGrad.Rotation = (r * 0.5) % 360
            blob1.Position = UDim2.new(0.12 + 0.04 * math.sin(tick()), 0, 0.18 + 0.05 * math.cos(tick() * 0.7), 0)
            blob2.Position = UDim2.new(0.62 + 0.05 * math.cos(tick() * 0.6), 0, 0.5 + 0.06 * math.sin(tick() * 0.9), 0)
            stroke.Color = Color3.fromHSV((tick() * 0.08) % 1, 0.55, 1)
            RunService.RenderStepped:Wait()
        end
    end)

    local function submit()
        local k = tostring(box.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if k == VALID then
            passed = true
            status.TextColor3 = Color3.fromRGB(100, 255, 140)
            status.Text = "access granted"
            TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
            }):Play()
            task.wait(0.35)
            anim = false
            gui:Destroy()
            done:Fire()
        else
            status.TextColor3 = Color3.fromRGB(255, 90, 90)
            status.Text = "invalid key"
            local orig = card.Position
            for i = 1, 4 do
                card.Position = orig + UDim2.new(0, (i % 2 == 0) and 6 or -6, 0, 0)
                task.wait(0.04)
            end
            card.Position = orig
            boxStroke.Color = Color3.fromRGB(220, 60, 60)
            task.delay(0.8, function()
                if boxStroke then boxStroke.Color = Color3.fromRGB(50, 60, 90) end
            end)
        end
    end

    btn.MouseButton1Click:Connect(submit)
    box.FocusLost:Connect(function(enter)
        if enter then submit() end
    end)

    done.Event:Wait()
    return passed
end

return Key
