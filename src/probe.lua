--[[
    Flick · probe.lua — official debug
    Focus: reload timer ownership (tables vs upvalues vs Misc)
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
    elseif t == "number" or t == "boolean" or t == "string" then
        return t .. ":" .. tostring(v)
    end
    return t
end

local function isGunShape(t)
    if type(t) ~= "table" then return false end
    local ok, res = pcall(function()
        return type(rawget(t, "Ammo")) == "number" and type(rawget(t, "reloadTime")) == "number"
    end)
    return ok and res
end

local function tableId(t)
    return tostring(t)
end

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

local function fnSrc(fn)
    local s, n = "", ""
    pcall(function() s = tostring(debug.info(fn, "s")) end)
    pcall(function() n = tostring(debug.info(fn, "n")) end)
    return n, s
end

local function hasReloadConst(fn)
    local ok, consts = pcall(debug.getconstants, fn)
    if not ok or type(consts) ~= "table" then return false, {} end
    local hits = {}
    for _, c in ipairs(consts) do
        if type(c) == "string" then
            local l = string.lower(c)
            if l:find("reload", 1, true) or l == "ammo" or l:find("canfire", 1, true) then
                table.insert(hits, c)
            end
        end
    end
    return #hits > 0, hits
end

local function dumpUpvalues(fn, label)
    local lines = {}
    pcall(function()
        local i = 1
        while i <= 40 do
            local name, val = debug.getupvalue(fn, i)
            if not name then break end
            local show = false
            local ln = string.lower(tostring(name))
            if type(val) == "number" or type(val) == "boolean" then
                show = true
            elseif type(val) == "table" and isGunShape(val) then
                show = true
            elseif ln:find("reload") or ln:find("ammo") or ln:find("cool") or ln:find("wait") or ln:find("delay") then
                show = true
            end
            if show then
                local extra = ""
                if type(val) == "table" and isGunShape(val) then
                    extra = string.format(" [Ammo=%s reloadTime=%s]",
                        tostring(rawget(val, "Ammo")),
                        tostring(rawget(val, "reloadTime")))
                end
                table.insert(lines, string.format("  uv[%d] %s = %s%s", i, tostring(name), safeType(val), extra))
            end
            i = i + 1
        end
    end)
    if #lines > 0 then
        log(label)
        for _, L in ipairs(lines) do log(L) end
    end
end

-- ── modules ─────────────────────────────────────────────────
sep("MODULES")
local BH, GF
pcall(function()
    BH = require(ReplicatedStorage.ModuleScripts.GunModules.BulletHandler)
    log("BulletHandler OK")
end)
pcall(function()
    GF = require(ReplicatedStorage.ModuleScripts.GunModules.GunFramework)
    log("GunFramework OK")
end)

-- ── list GF reload-related functions + upvalues once ────────
sep("GUNFRAMEWORK RELOAD FNS + UPVALUES")
local reloadFns = {}
pcall(function()
    for _, obj in ipairs(getgc()) do
        if type(obj) == "function" then
            local n, s = fnSrc(obj)
            if s:find("GunFramework", 1, true) then
                local has, hits = hasReloadConst(obj)
                if has then
                    table.insert(reloadFns, obj)
                    log(string.format("fn name=%s consts=[%s]", n, table.concat(hits, ",")))
                    dumpUpvalues(obj, "  upvalues:")
                end
            end
        end
    end
end)
log("reload-related GF fns: " .. tostring(#reloadFns))

-- ── gc gun tables ───────────────────────────────────────────
sep("GC GUN-SHAPED")
do
    local list = scanGunTables()
    log("count=" .. tostring(#list))
    for i, g in ipairs(list) do
        if i > 5 then break end
        log(string.format("#%d id=%s Ammo=%s reloadTime=%s",
            i, tableId(g), tostring(rawget(g, "Ammo")), tostring(rawget(g, "reloadTime"))))
    end
end

-- ── Fire: snapshot tables + upvalue numbers around shot ─────
sep("FIRE HOOK")
local fireN = 0

local function snapshotReloadState(tag)
    log("-- snapshot " .. tag)
    local list = scanGunTables()
    log("gun-shaped count=" .. tostring(#list))
    for _, g in ipairs(list) do
        log(string.format("  table id=%s Ammo=%s reloadTime=%s",
            tableId(g), tostring(rawget(g, "Ammo")), tostring(rawget(g, "reloadTime"))))
    end
    for _, fn in ipairs(reloadFns) do
        local n = fnSrc(fn)
        pcall(function()
            local i = 1
            while i <= 40 do
                local name, val = debug.getupvalue(fn, i)
                if not name then break end
                if type(val) == "number" then
                    local ln = string.lower(tostring(name))
                    if ln:find("reload") or ln:find("ammo") or ln:find("cool")
                        or ln:find("wait") or ln:find("delay") or ln:find("time")
                        or val == 0.8 or (val > 0 and val < 5) then
                        log(string.format("  uv %s.%s = %s", n, tostring(name), tostring(val)))
                    end
                elseif type(val) == "boolean" then
                    local ln = string.lower(tostring(name))
                    if ln:find("reload") or ln:find("fire") or ln:find("ready") then
                        log(string.format("  uv %s.%s = %s", n, tostring(name), tostring(val)))
                    end
                elseif type(val) == "table" and isGunShape(val) then
                    log(string.format("  uv %s.%s → table Ammo=%s reloadTime=%s",
                        n, tostring(name),
                        tostring(rawget(val, "Ammo")),
                        tostring(rawget(val, "reloadTime"))))
                end
                i = i + 1
            end
        end)
    end
end

if BH and type(BH.Fire) == "function" then
    local oldFire = BH.Fire
    BH.Fire = function(data)
        fireN = fireN + 1
        sep("FIRE #" .. fireN)
        if type(data) == "table" and type(data.Misc) == "table" then
            log(string.format("Misc AmmoCount=%s MaxAmmo=%s ReloadTime=%s",
                tostring(data.Misc.AmmoCount),
                tostring(data.Misc.MaxAmmo),
                tostring(data.Misc.ReloadTime)
            ))
        end
        snapshotReloadState("pre")
        local result = oldFire(data)
        task.defer(function()
            snapshotReloadState("post-defer")
        end)
        task.delay(0.15, function()
            snapshotReloadState("post-0.15")
        end)
        task.delay(0.5, function()
            snapshotReloadState("post-0.5")
        end)
        return result
    end
    log("Fire hooked")
else
    log("no BulletHandler.Fire")
end

-- ── respawn ─────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function()
    sep("RESPAWN")
    task.spawn(function()
        task.wait(0.4)
        local list = scanGunTables()
        log("gun-shaped after respawn+0.4s: " .. tostring(#list))
        for _, g in ipairs(list) do
            log(string.format("  id=%s Ammo=%s reloadTime=%s",
                tableId(g), tostring(rawget(g, "Ammo")), tostring(rawget(g, "reloadTime"))))
        end
        -- refresh fn list upvalues after respawn
        snapshotReloadState("respawn+0.4")
    end)
end)

sep("INSTRUCTIONS")
log("1. Shoot once (alive)")
log("2. Die, respawn, wait for auto gun")
log("3. Shoot once")
log("4. Paste all [PROBE] lines")
log("Watch: uv *reload* / *0.8* changing around FIRE vs table reloadTime")
