--[[
    Flick · probe.lua — official debug
    Reload / controller / respawn diagnostics
    No permanent combat hooks. Safe Fire wrap only for data dump.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
        return string.format("Vector3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
    elseif t == "boolean" or t == "number" or t == "string" then
        return t .. ":" .. tostring(v)
    end
    return t
end

local function dumpKeys(t, limit)
    limit = limit or 40
    local keys = {}
    local n = 0
    pcall(function()
        for k, v in pairs(t) do
            n = n + 1
            if n <= limit then
                table.insert(keys, tostring(k) .. "=" .. safeType(v))
            end
        end
    end)
    table.sort(keys)
    return keys, n
end

-- ── identity helpers ────────────────────────────────────────
local function tableId(t)
    return tostring(t) -- e.g. table: 0x...
end

local function isGunShape(t)
    if type(t) ~= "table" then return false end
    local ok, res = pcall(function()
        return type(rawget(t, "Ammo")) == "number" and type(rawget(t, "reloadTime")) == "number"
    end)
    return ok and res
end

local function scoreGun(t)
    -- higher = more likely live gun controller
    local s = 0
    pcall(function()
        if type(rawget(t, "Ammo")) == "number" then s = s + 2 end
        if type(rawget(t, "reloadTime")) == "number" then s = s + 2 end
        if rawget(t, "CanReload") ~= nil then s = s + 1 end
        if rawget(t, "CanFire") ~= nil then s = s + 1 end
        if rawget(t, "MaxAmmo") ~= nil then s = s + 1 end
        if rawget(t, "Reloading") ~= nil then s = s + 1 end
        if type(rawget(t, "Ammo")) == "number" and rawget(t, "Ammo") > 0 then s = s + 1 end
    end)
    return s
end

-- ── 1. module resolve ───────────────────────────────────────
sep("MODULES")
local BH, GF
pcall(function()
    BH = require(ReplicatedStorage.ModuleScripts.GunModules.BulletHandler)
    log("BulletHandler OK Fire=" .. typeof(BH and BH.Fire))
end)
pcall(function()
    GF = require(ReplicatedStorage.ModuleScripts.GunModules.GunFramework)
    local keys = {}
    if type(GF) == "table" then
        for k, v in pairs(GF) do
            table.insert(keys, tostring(k) .. ":" .. typeof(v))
        end
    end
    log("GunFramework OK keys={" .. table.concat(keys, ",") .. "}")
end)

-- ── 2. gc inventory of gun-shaped tables ────────────────────
local function scanGunTables()
    local list = {}
    pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if isGunShape(obj) then
                table.insert(list, obj)
            end
        end
    end)
    return list
end

sep("GC GUN-SHAPED (Ammo number + reloadTime number)")
local guns = scanGunTables()
log("count=" .. tostring(#guns))
-- group by table id, show top scores
table.sort(guns, function(a, b) return scoreGun(a) > scoreGun(b) end)
local show = math.min(#guns, 8)
for i = 1, show do
    local g = guns[i]
    local keys = dumpKeys(g, 25)
    log(string.format(
        "#%d id=%s score=%d Ammo=%s reloadTime=%s Reloading=%s CanFire=%s",
        i,
        tableId(g),
        scoreGun(g),
        tostring(rawget(g, "Ammo")),
        tostring(rawget(g, "reloadTime")),
        tostring(rawget(g, "Reloading")),
        tostring(rawget(g, "CanFire"))
    ))
    log("  keys: " .. table.concat(keys, " | "))
end
if #guns > show then
    log("... +" .. tostring(#guns - show) .. " more")
end

-- ── 3. hook GunFramework.new — watch identities ─────────────
sep("HOOK GunFramework.new")
local newCount = 0
local lastNewId = nil
if GF and type(GF.new) == "function" then
    local oldNew = GF.new
    GF.new = function(...)
        local obj = oldNew(...)
        newCount = newCount + 1
        lastNewId = tableId(obj)
        log(string.format("NEW #%d id=%s gunShape=%s", newCount, lastNewId, tostring(isGunShape(obj))))
        if type(obj) == "table" then
            local keys = dumpKeys(obj, 20)
            log("  NEW keys: " .. table.concat(keys, " | "))
            -- if not yet gun shape, check next frame
            task.defer(function()
                task.wait(0.05)
                log(string.format("  NEW #%d deferred gunShape=%s Ammo=%s reloadTime=%s",
                    newCount,
                    tostring(isGunShape(obj)),
                    tostring(rawget(obj, "Ammo")),
                    tostring(rawget(obj, "reloadTime"))
                ))
            end)
        end
        return obj
    end
    log("new hooked — equip / respawn to see NEW lines")
else
    log("GunFramework.new unavailable")
end

-- ── 4. Fire wrap — correlate shot with which table Ammo moves ─
sep("HOOK Fire")
local fireN = 0
if BH and type(BH.Fire) == "function" then
    local oldFire = BH.Fire
    BH.Fire = function(data)
        fireN = fireN + 1
        sep("FIRE #" .. fireN)

        -- snapshot all gun-shaped Ammo before
        local before = {}
        local list = scanGunTables()
        for _, g in ipairs(list) do
            before[tableId(g)] = rawget(g, "Ammo")
        end
        log("gun-shaped at fire: " .. tostring(#list))

        if type(data) == "table" and type(data.Misc) == "table" then
            log(string.format("Misc AmmoCount=%s MaxAmmo=%s ReloadTime=%s",
                tostring(data.Misc.AmmoCount),
                tostring(data.Misc.MaxAmmo),
                tostring(data.Misc.ReloadTime)
            ))
        end

        local result = oldFire(data)

        -- which tables changed Ammo?
        task.defer(function()
            local list2 = scanGunTables()
            local changed = 0
            for _, g in ipairs(list2) do
                local id = tableId(g)
                local a = rawget(g, "Ammo")
                local b = before[id]
                if b ~= nil and a ~= b then
                    changed = changed + 1
                    log(string.format("AMMO CHANGE id=%s %s → %s reloadTime=%s Reloading=%s",
                        id, tostring(b), tostring(a),
                        tostring(rawget(g, "reloadTime")),
                        tostring(rawget(g, "Reloading"))
                    ))
                end
            end
            if changed == 0 then
                log("AMMO CHANGE: none (Ammo not on scanned tables, or unchanged)")
            end
        end)

        task.delay(0.2, function()
            local list3 = scanGunTables()
            for _, g in ipairs(list3) do
                local a = rawget(g, "Ammo")
                local rt = rawget(g, "reloadTime")
                local rel = rawget(g, "Reloading")
                if a == 0 or rel == true or (type(rt) == "number" and rt > 0) then
                    log(string.format("POST0.2 id=%s Ammo=%s reloadTime=%s Reloading=%s",
                        tableId(g), tostring(a), tostring(rt), tostring(rel)))
                end
            end
        end)

        return result
    end
    log("Fire hooked — shoot once")
else
    log("BulletHandler.Fire unavailable")
end

-- ── 5. character / tool watch ───────────────────────────────
sep("CHARACTER / TOOL WATCH")
local function watchChar(char)
    if not char then return end
    log("Character=" .. char.Name)
    controller = nil -- luau no-op; just marker
    char.ChildAdded:Connect(function(ch)
        if ch:IsA("Tool") then
            log("Tool added to char: " .. ch.Name)
            task.delay(0.2, function()
                local list = scanGunTables()
                log("after tool+0.2s gun-shaped count=" .. tostring(#list))
                if GF and lastNewId then
                    log("last NEW id=" .. tostring(lastNewId))
                end
            end)
        end
    end)
end

if LocalPlayer.Character then
    watchChar(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(char)
    sep("RESPAWN")
    log("CharacterAdded")
    local beforeIds = {}
    for _, g in ipairs(scanGunTables()) do
        beforeIds[tableId(g)] = true
    end
    log("gun-shaped before settle: " .. tostring(#scanGunTables()))

    watchChar(char)

    task.spawn(function()
        for i = 1, 15 do
            task.wait(0.3)
            local list = scanGunTables()
            local fresh = 0
            for _, g in ipairs(list) do
                if not beforeIds[tableId(g)] then
                    fresh = fresh + 1
                end
            end
            log(string.format("t=%.1f count=%d fresh=%d lastNew=%s",
                i * 0.3, #list, fresh, tostring(lastNewId)))
            if lastNewId or fresh > 0 then
                -- print one fresh detail
                for _, g in ipairs(list) do
                    if not beforeIds[tableId(g)] then
                        log(string.format("  FRESH id=%s Ammo=%s reloadTime=%s",
                            tableId(g), tostring(rawget(g, "Ammo")), tostring(rawget(g, "reloadTime"))))
                        break
                    end
                end
            end
        end
        log("respawn watch done — equip gun + shoot if needed")
    end)
end)

local bp = LocalPlayer:FindFirstChild("Backpack")
if bp then
    bp.ChildAdded:Connect(function(ch)
        if ch:IsA("Tool") then
            log("Tool added to backpack: " .. ch.Name)
        end
    end)
end

-- ── 6. instructions ─────────────────────────────────────────
sep("INSTRUCTIONS")
log("1. Note GC count and top table ids")
log("2. Shoot once — watch AMMO CHANGE lines (which id moved)")
log("3. Die / respawn — watch RESPAWN + NEW + fresh ids")
log("4. Equip gun — Tool added + count/fresh")
log("5. Shoot again — does AMMO CHANGE use a NEW id or old?")
log("Paste all [PROBE] lines from a full cycle")
