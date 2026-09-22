--[[
    Flick · Silent Aim
    BulletHandler.Fire rewrite only · no metamethods
]]

local Silent = {}

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

Silent.Config = {
    Enabled      = true,
    FOV          = 140,
    HitPart      = "Head",
    VisibleCheck = true,
    Prediction   = 0.135,
    ShowFOV      = true,
    FOVColor     = Color3.fromRGB(140, 80, 255),
    FOVThickness = 1.5,
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = Silent.Config.FOVThickness
FOVCircle.NumSides  = 64
FOVCircle.Filled    = false
FOVCircle.Color     = Silent.Config.FOVColor
FOVCircle.Visible   = false
FOVCircle.ZIndex    = 2

local function GetChar(plr) return plr and plr.Character end
local function GetHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function GetRoot(c)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
end
local function GetPart(c, n) return c and c:FindFirstChild(n) end
local function Alive(plr)
    local c, h = GetChar(plr), GetHum(GetChar(plr))
    return c and h and h.Health > 0
end

local function Visible(part)
    if not Silent.Config.VisibleCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local hit = workspace:Raycast(origin, dir, params)
    return hit == nil or hit.Instance:IsDescendantOf(part.Parent)
end

local function GetClosest()
    local best, bestDist = nil, Silent.Config.FOV
    local mouse = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not Alive(plr) then continue end
        local char = GetChar(plr)
        local part = GetPart(char, Silent.Config.HitPart) or GetRoot(char)
        if not part or not Visible(part) then continue end

        local sp, on = Camera:WorldToViewportPoint(part.Position)
        if not on then continue end
        local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
        if d < bestDist then
            bestDist = d
            best = part
        end
    end
    return best
end

local function FindBulletHandler()
    local ok, mod = pcall(function()
        return require(
            ReplicatedStorage
                :WaitForChild("ModuleScripts", 6)
                :WaitForChild("GunModules", 6)
                :WaitForChild("BulletHandler", 6)
        )
    end)
    if ok and mod and type(mod.Fire) == "function" then return mod end

    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "BulletHandler" and v:IsA("ModuleScript") then
            local s, m = pcall(require, v)
            if s and m and type(m.Fire) == "function" then return m end
        end
    end
    return nil
end

function Silent.Init()
    local BH = FindBulletHandler()
    if not BH then
        warn("[Silent] BulletHandler not found")
        return false
    end

    local oldFire = BH.Fire
    BH.Fire = function(data)
        if Silent.Config.Enabled and type(data) == "table" then
            local target = GetClosest()
            if target then
                local origin = data.Origin or Camera.CFrame.Position
                local pos = target.Position
                if Silent.Config.Prediction > 0 then
                    local vel = target.AssemblyLinearVelocity or Vector3.zero
                    pos = pos + vel * Silent.Config.Prediction
                end
                data.Direction = (pos - origin).Unit
            end
        end
        return oldFire(data)
    end

    -- FOV render
    game:GetService("RunService").RenderStepped:Connect(function()
        if Silent.Config.Enabled and Silent.Config.ShowFOV then
            FOVCircle.Position = UserInputService:GetMouseLocation()
            FOVCircle.Radius   = Silent.Config.FOV
            FOVCircle.Color    = Silent.Config.FOVColor
            FOVCircle.Visible  = true
        else
            FOVCircle.Visible = false
        end
    end)

    print("[Silent] BulletHandler.Fire hooked")
    return true
end

return Silent
