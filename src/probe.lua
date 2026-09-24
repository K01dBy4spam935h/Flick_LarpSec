--[[
    Flick · Magic Probe (SAFE — no metamethods)
    Does NOT touch __namecall / __index / getrawmetatable.
    Only: require BulletHandler, wrap Fire, list known remotes.

    Run → shoot 1–2 times → copy [PROBE] lines.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function log(...)
    print("[PROBE]", ...)
end

local function sep(t)
    log("======== " .. t .. " ========")
end

local function safeType(v)
    local t = typeof(v)
    if t == "table" then
        local n = 0
        for _ in pairs(v) do n = n + 1 end
        return "table(" .. n .. ")"
    elseif t == "Instance" then
        return "Instance:" .. v.ClassName .. ":" .. v.Name
    elseif t == "Vector3" then
        return string.format("Vector3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then
        local p = v.Position
        return string.format("CFrame(%.1f,%.1f,%.1f)", p.X, p.Y, p.Z)
    elseif t == "boolean" or t == "number" or t == "string" then
        return t .. ":" .. tostring(v)
    end
    return t
end

local function dumpTable(t, prefix, depth)
    depth = depth or 0
    if depth > 3 then return end
    for k, v in pairs(t) do
        log(prefix .. tostring(k) .. " = " .. safeType(v))
        if type(v) == "table" and depth < 2 then
            dumpTable(v, prefix .. "  ", depth + 1)
        end
    end
end

-- ── 1. known structure from first probe ─────────────────────
sep("REMINDER (from prior scan)")
log("BulletHandler @ ModuleScripts.GunModules.BulletHandler")
log("Remotes: GunShot, ProjectileRender, ProjectileFinished, ConnectM6D")
log("Per-player: ClientRemotes.CheckShot, ClientRemotes.CheckFire")
log("No metamethods in this probe")

-- ── 2. resolve BulletHandler ────────────────────────────────
sep("RESOLVE")
local BH
local ok, mod = pcall(function()
    return require(
        ReplicatedStorage
            :WaitForChild("ModuleScripts", 5)
            :WaitForChild("GunModules", 5)
            :WaitForChild("BulletHandler", 5)
    )
end)
if ok and type(mod) == "table" and type(mod.Fire) == "function" then
    BH = mod
    log("BulletHandler OK")
else
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "BulletHandler" and v:IsA("ModuleScript") then
            local s, m = pcall(require, v)
            if s and type(m) == "table" and type(m.Fire) == "function" then
                BH = m
                log("BulletHandler OK via scan: " .. v:GetFullName())
                break
            end
        end
    end
end
if not BH then
    log("FAILED — cannot require BulletHandler")
    return
end

-- ── 3. list ClientRemotes on local player ───────────────────
sep("YOUR CLIENT REMOTES")
local function dumpRemotes(parent, label)
    if not parent then
        log(label .. " missing")
        return
    end
    for _, c in ipairs(parent:GetDescendants()) do
        if c:IsA("RemoteEvent") or c:IsA("RemoteFunction") then
            log(label .. " " .. c.ClassName .. " " .. c:GetFullName())
        end
    end
end
dumpRemotes(LocalPlayer:FindFirstChild("ClientRemotes"), "LP")
dumpRemotes(LocalPlayer:FindFirstChild("Backpack"), "BP")
if LocalPlayer.Character then
    dumpRemotes(LocalPlayer.Character, "CHAR")
end
local gunRemoteFolder = ReplicatedStorage:FindFirstChild("ModuleScripts")
if gunRemoteFolder then
    gunRemoteFolder = gunRemoteFolder:FindFirstChild("GunModules")
    if gunRemoteFolder then
        dumpRemotes(gunRemoteFolder:FindFirstChild("Remote"), "GUN")
    end
end

-- ── 4. wrap Fire only ───────────────────────────────────────
sep("FIRE HOOK — shoot now")
local n = 0
local oldFire = BH.Fire
BH.Fire = function(data)
    n = n + 1
    sep("FIRE #" .. n)

    if type(data) ~= "table" then
        log("data type: " .. typeof(data))
        return oldFire(data)
    end

    dumpTable(data, "  ")

    local origin = data.Origin
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
    if typeof(origin) == "Vector3" and root then
        log(string.format("Origin↔Root: %.2f studs", (origin - root.Position).Magnitude))
    end

    local flags = {}
    for k, v in pairs(data) do
        local lk = string.lower(tostring(k))
        if lk:find("penetrat") or lk:find("pierce") or lk:find("wall")
            or lk:find("ignore") or lk:find("filter") or lk:find("black")
            or lk:find("white") or lk:find("ray") or lk:find("hit")
            or lk:find("misc") then
            table.insert(flags, tostring(k) .. "=" .. safeType(v))
        end
    end
    if #flags > 0 then
        log("FLAG-LIKE: " .. table.concat(flags, " | "))
    else
        log("FLAG-LIKE: (none)")
    end

    if typeof(data.Direction) == "Vector3" then
        log(string.format("Direction magnitude: %.4f", data.Direction.Magnitude))
    end

    return oldFire(data)
end

log("wrapped Fire — no namecall")
log("Shoot visible target, then behind wall")
log("Paste all new [PROBE] FIRE lines")
