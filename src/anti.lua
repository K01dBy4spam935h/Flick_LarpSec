--[[
    Flick · Professional Adonis Anti-Detection
    Targets: Detected, Kill, Disconnect, indexInstance, namecallInstance,
             debug.info integrity, Kick, communication heartbeat

    Strategy:
      - Keep Adonis client↔server heartbeat alive (avoids "communication following disconnect")
      - Neutralize Detected so it never reports real flags
      - Spoof debug.info so Adonis cannot see the hook
      - Neuter Kill / Disconnect / detector callbacks
      - Soft kick swallow
]]

local Anti = {}

local function safe(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
end

-- ─────────────────────────────────────────────────────────────
-- 1. Find + hook Detected (core snitch function)
-- ─────────────────────────────────────────────────────────────
local DetectedFunc, KillFunc, DisconnectFunc

local function findAdonisClosures()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local det = rawget(v, "Detected")
            local kil = rawget(v, "Kill")
            local dis = rawget(v, "Disconnect")

            if type(det) == "function" and not DetectedFunc then
                local isAdonis = false
                pcall(function()
                    local consts = debug.getconstants(det)
                    for _, c in pairs(consts) do
                        if type(c) == "string" then
                            if c:find("On Xbox") or c:find("On mobile") or c:find("Adonis") or c:find("Tamper") then
                                isAdonis = true
                                break
                            end
                        end
                    end
                end)
                if isAdonis or (type(kil) == "function") or rawget(v, "Variables") then
                    DetectedFunc = det
                end
            end

            if type(kil) == "function" and not KillFunc then
                KillFunc = kil
            end
            if type(dis) == "function" and not DisconnectFunc then
                DisconnectFunc = dis
            end
        end
    end
end

local function hookDetected()
    if not DetectedFunc then return false end

    -- cache original debug.info results for the real Detected
    local cached = {}
    pcall(function()
        cached.n = debug.info(DetectedFunc, "n")
        cached.s = debug.info(DetectedFunc, "s")
        cached.l = debug.info(DetectedFunc, "l")
        cached.a = debug.info(DetectedFunc, "a")
        cached.f = debug.info(DetectedFunc, "f")
        cached.slanf = {debug.info(DetectedFunc, "slanf")}
    end)

    -- spoof debug.info so Adonis integrity check passes
    local oldInfo
    oldInfo = hookfunction(debug.info, newcclosure(function(...)
        local target, what = ...
        if target == DetectedFunc then
            if what == "n" then return cached.n end
            if what == "s" then return cached.s end
            if what == "l" then return cached.l end
            if what == "a" then return cached.a end
            if what == "f" then return cached.f end
            if what == "slanf" or what == "nsl" or what == "slanf" then
                return unpack(cached.slanf or {})
            end
        end
        return oldInfo(...)
    end))

    -- replace Detected: always return true (required — false/nil triggers tamper)
    hookfunction(DetectedFunc, newcclosure(function(action, info, nocrash)
        return true
    end))

    return true
end

local function hookKillDisconnect()
    if KillFunc then
        pcall(function()
            hookfunction(KillFunc, newcclosure(function() end))
        end)
    end
    if DisconnectFunc then
        pcall(function()
            hookfunction(DisconnectFunc, newcclosure(function() end))
        end)
    end
end

-- ─────────────────────────────────────────────────────────────
-- 2. Neuter detector tables (indexInstance etc.) without killing heartbeat
-- ─────────────────────────────────────────────────────────────
local function neuterDetectors()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            for _, key in ipairs({
                "indexInstance", "newindexInstance", "namecallInstance",
                "indexEnum", "namecallEnum", "eqEnum"
            }) do
                local entry = rawget(v, key)
                if type(entry) == "table" and entry[1] == "kick" and type(entry[2]) == "function" then
                    pcall(function()
                        rawset(entry, 2, function() return false end)
                    end)
                end
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────
-- 3. Kick protection (client-side)
-- ─────────────────────────────────────────────────────────────
local function protectKick()
    local LP = game:GetService("Players").LocalPlayer
    if not LP then return end

    pcall(function()
        local old
        old = hookfunction(LP.Kick, newcclosure(function(self, ...)
            if checkcaller and checkcaller() then
                return old(self, ...)
            end
            return
        end))
    end)
end

-- ─────────────────────────────────────────────────────────────
-- 4. Continuous re-apply
-- ─────────────────────────────────────────────────────────────
local function watchdog()
    task.spawn(function()
        while true do
            task.wait(6)
            findAdonisClosures()
            if DetectedFunc then
                pcall(hookDetected)
            end
            neuterDetectors()
            hookKillDisconnect()
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
-- Entry
-- ─────────────────────────────────────────────────────────────
function Anti.Init()
    findAdonisClosures()

    local okDet = hookDetected()
    hookKillDisconnect()
    neuterDetectors()
    protectKick()

    task.delay(3, function()
        findAdonisClosures()
        hookDetected()
        hookKillDisconnect()
        neuterDetectors()
        print("[Anti] delayed re-hook complete")
    end)

    watchdog()

    print(string.format(
        "[Anti] Adonis bypass active · Detected=%s Kill=%s",
        tostring(okDet),
        tostring(KillFunc ~= nil)
    ))
end

return Anti
