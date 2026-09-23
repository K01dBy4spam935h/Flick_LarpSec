--[[
    Flick · Magic Bullet Probe (thorough)
    Run alone in executor while in a match.
    Shoot 1–3 times at a wall / player. Read console.

    Checks:
      1. BulletHandler.Fire data shape (keys, types, nested Misc)
      2. Origin distance vs LocalPlayer (validation hint)
      3. Filter / penetrate / ignore-style fields
      4. Gun-related remotes (Hit, Damage, Shot, etc.)
      5. Whether FireServer is used after Fire (hit-report path)
      6. Module tree under ModuleScripts / GunModules
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local LOG = {}
local function log(...)
    local s = table.concat({...}, " ")
    print("[PROBE]", s)
    table.insert(LOG, s)
end

local function sep(title)
    log("======== " .. title .. " ========")
end

local function safeType(v)
    local t = typeof(v)
    if t == "table" then
        local n = 0
        for _ in pairs(v) do n = n + 1 end
        return "table(" .. n .. ")"
    end
    if t == "Instance" then
        return "Instance:" .. v.ClassName .. ":" .. v:GetFullName()
    end
    if t == "Vector3" then
        return string.format("Vector3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    end
    if t == "CFrame" then
        local p = v.Position
        return string.format("CFrame(%.1f,%.1f,%.1f)", p.X, p.Y, p.Z)
    end
    if t == "boolean" or t == "number" or t == "string" then
        return t .. ":" .. tostring(v)
    end
    return t
end

local function dumpTable(t, prefix, depth)
    depth = depth or 0
    if depth > 3 then return end
    for k, v in pairs(t) do
        local key = tostring(k)
        log(prefix .. key .. " = " .. safeType(v))
        if type(v) == "table" and depth < 2 then
            dumpTable(v, prefix .. "  ", depth + 1)
        end
    end
end

-- ─────────────────────────────────────────────────────────────
sep("1. MODULE TREE")
-- ─────────────────────────────────────────────────────────────
local function listChildren(folder, indent, maxDepth)
    if maxDepth <= 0 or not folder then return end
    for _, c in ipairs(folder:GetChildren()) do
        log(indent .. c.ClassName .. "  " .. c.Name)
        if c:IsA("Folder") or c:IsA("ModuleScript") or c.Name:lower():find("gun") then
            listChildren(c, indent .. "  ", maxDepth - 1)
        end
    end
end

local ms = ReplicatedStorage:FindFirstChild("ModuleScripts")
if ms then
    log("ReplicatedStorage.ModuleScripts found")
    listChildren(ms, "  ", 3)
else
    log("ModuleScripts NOT under ReplicatedStorage — scanning descendants for GunModules / BulletHandler")
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "GunModules" or v.Name == "BulletHandler" then
            log("  found " .. v.ClassName .. " " .. v:GetFullName())
        end
    end
end

-- ─────────────────────────────────────────────────────────────
sep("2. BULLET HANDLER RESOLVE")
-- ─────────────────────────────────────────────────────────────
local BH, BHPath
local function tryRequire(inst)
    local ok, mod = pcall(require, inst)
    if ok and type(mod) == "table" and type(mod.Fire) == "function" then
        return mod
    end
end

if ms then
    local gm = ms:FindFirstChild("GunModules")
    if gm then
        local bh = gm:FindFirstChild("BulletHandler")
        if bh then
            BH = tryRequire(bh)
            BHPath = bh:GetFullName()
        end
    end
end
if not BH then
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "BulletHandler" and v:IsA("ModuleScript") then
            BH = tryRequire(v)
            if BH then
                BHPath = v:GetFullName()
                break
            end
        end
    end
end

if BH then
    log("BulletHandler OK @ " .. tostring(BHPath))
    log("Fire typeof: " .. typeof(BH.Fire))
    -- list module keys
    local keys = {}
    for k, v in pairs(BH) do
        table.insert(keys, tostring(k) .. ":" .. typeof(v))
    end
    table.sort(keys)
    log("BH keys: " .. table.concat(keys, ", "))
else
    log("FAILED to require BulletHandler")
end

-- ─────────────────────────────────────────────────────────────
sep("3. REMOTE INVENTORY (gun / hit / damage)")
-- ─────────────────────────────────────────────────────────────
local INTEREST = {
    "hit", "damage", "shot", "shoot", "fire", "bullet", "gun", "weapon",
    "register", "impact", "kill", "hurt", "ray", "cast", "projectile",
}
local function interesting(name)
    local l = string.lower(name)
    for _, k in ipairs(INTEREST) do
        if l:find(k, 1, true) then return true end
    end
    return false
end

local remotes = {}
for _, v in ipairs(game:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("UnreliableRemoteEvent") then
        if interesting(v.Name) or interesting(v:GetFullName()) then
            table.insert(remotes, v)
            log(v.ClassName .. "  " .. v:GetFullName())
        end
    end
end
log("interesting remotes count: " .. #remotes)

-- also list ALL remotes under ReplicatedStorage (short)
log("--- all remotes under ReplicatedStorage ---")
for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("UnreliableRemoteEvent") then
        log("  " .. v.ClassName .. "  " .. v:GetFullName())
    end
end

-- ─────────────────────────────────────────────────────────────
sep("4. HOOK Fire + WATCH FireServer (shoot now)")
-- ─────────────────────────────────────────────────────────────
local fireCount = 0
local namecallHits = {}

if BH and type(BH.Fire) == "function" then
    local oldFire = BH.Fire
    BH.Fire = function(data)
        fireCount = fireCount + 1
        sep("FIRE #" .. fireCount)

        if type(data) ~= "table" then
            log("data is NOT a table: " .. typeof(data))
            return oldFire(data)
        end

        dumpTable(data, "  ")

        -- origin vs character
        local origin = data.Origin
        local char = LocalPlayer.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
        if typeof(origin) == "Vector3" and root then
            local dist = (origin - root.Position).Magnitude
            log(string.format("Origin↔Root distance: %.2f studs", dist))
            if dist > 25 then
                log("  HINT: Origin already far from body — unusual")
            elseif dist < 12 then
                log("  HINT: Origin near body (typical validated range)")
            end
        end

        -- flag scan
        local flagHits = {}
        for k, v in pairs(data) do
            local lk = string.lower(tostring(k))
            if lk:find("penetrat") or lk:find("pierce") or lk:find("wall")
                or lk:find("ignore") or lk:find("filter") or lk:find("blacklist")
                or lk:find("whitelist") or lk:find("ray") then
                table.insert(flagHits, tostring(k) .. "=" .. safeType(v))
            end
        end
        if #flagHits > 0 then
            log("FILTER/PENETRATE-LIKE FIELDS: " .. table.concat(flagHits, " | "))
        else
            log("No penetrate/ignore/filter-like keys on data")
        end

        if data.Direction and data.Origin and typeof(data.Direction) == "Vector3" and typeof(data.Origin) == "Vector3" then
            log(string.format("Direction magnitude: %.4f (should be ~1 if unit)", data.Direction.Magnitude))
        end

        return oldFire(data)
    end
    log("BulletHandler.Fire hooked — SHOOT now")
else
    log("Could not hook Fire")
end

-- narrow namecall watch (log only, do not modify)
pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            local name = ""
            pcall(function() name = self.Name end)
            local full = ""
            pcall(function() full = self:GetFullName() end)
            if interesting(name) or interesting(full) then
                local args = {...}
                local sig = method .. " " .. full .. " argc=" .. #args
                for i, a in ipairs(args) do
                    sig = sig .. " |[" .. i .. "]=" .. safeType(a)
                end
                -- dedupe spam
                if not namecallHits[sig] then
                    namecallHits[sig] = true
                    log("NAMECALL " .. sig)
                    for i, a in ipairs(args) do
                        if type(a) == "table" then
                            log("  arg" .. i .. " table dump:")
                            dumpTable(a, "    ")
                        end
                    end
                end
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
    log("namecall watcher ON (read-only)")
end)

-- ─────────────────────────────────────────────────────────────
sep("5. INSTRUCTIONS")
-- ─────────────────────────────────────────────────────────────
log("1. Shoot at a visible player once")
log("2. Shoot at someone behind a wall once")
log("3. Copy everything from [PROBE] in console")
log("Watch for: Fire data keys, Origin distance, filter fields, NAMECALL hit remotes")
log("Probe stays active this session — rejoin to clear hooks if needed")

return {
    GetLog = function() return LOG end,
    GetFireCount = function() return fireCount end,
}
