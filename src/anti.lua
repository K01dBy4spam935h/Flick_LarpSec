--[[
    Flick · Adonis full client disable
    Neutralize Detected/Kill/Disconnect/detectors without breaking heartbeat
]]

local Anti = {}

local DetectedFunc, KillFunc, DisconnectFunc, SendFunc
local bypassed = false
local kickAttempts = 0
local infoHooked = false

local function findClosures()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local det = rawget(v, "Detected")
            local kil = rawget(v, "Kill")
            local dis = rawget(v, "Disconnect")
            local snd = rawget(v, "Send")

            if type(det) == "function" then
                local hit = false
                pcall(function()
                    for _, c in pairs(debug.getconstants(det)) do
                        if type(c) == "string" and (c:find("On Xbox") or c:find("On mobile") or c:find("Adonis") or c:find("Tamper") or c:find("0x") or c:find("Anti")) then
                            hit = true
                            break
                        end
                    end
                end)
                if hit or type(kil) == "function" or rawget(v, "Variables") or rawget(v, "Process") then
                    DetectedFunc = det
                end
            end
            if type(kil) == "function" then KillFunc = kil end
            if type(dis) == "function" then DisconnectFunc = dis end
            if type(snd) == "function" then SendFunc = snd end
        end
    end
end

local function hookDetected()
    if not DetectedFunc then return false end

    local cached = {}
    pcall(function()
        cached.n = debug.info(DetectedFunc, "n")
        cached.s = debug.info(DetectedFunc, "s")
        cached.l = debug.info(DetectedFunc, "l")
        cached.a = debug.info(DetectedFunc, "a")
        cached.f = debug.info(DetectedFunc, "f")
        cached.slanf = {debug.info(DetectedFunc, "slanf")}
    end)

    if not infoHooked then
        local oldInfo
        oldInfo = hookfunction(debug.info, newcclosure(function(...)
            local target, what = ...
            if DetectedFunc and target == DetectedFunc then
                if what == "n" then return cached.n end
                if what == "s" then return cached.s end
                if what == "l" then return cached.l end
                if what == "a" then return cached.a end
                if what == "f" then return cached.f end
                if what == "slanf" or what == "nsl" then
                    return unpack(cached.slanf or {})
                end
            end
            return oldInfo(...)
        end))
        infoHooked = true
    end

    pcall(function()
        hookfunction(DetectedFunc, newcclosure(function()
            return true
        end))
    end)
    return true
end

local function hookKillDisconnect()
    if KillFunc then pcall(function() hookfunction(KillFunc, newcclosure(function() end)) end) end
    if DisconnectFunc then pcall(function() hookfunction(DisconnectFunc, newcclosure(function() end)) end) end
end

local function neuterDetectors()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            for _, key in ipairs({
                "indexInstance", "newindexInstance", "namecallInstance",
                "indexEnum", "namecallEnum", "eqEnum"
            }) do
                local entry = rawget(v, key)
                if type(entry) == "table" and type(entry[2]) == "function" then
                    pcall(function() rawset(entry, 2, function() return false end) end)
                end
            end
            for _, key in ipairs({"Detectors", "Launch", "RLocked", "Detected"}) do
                local val = rawget(v, key)
                if type(val) == "function" and val ~= DetectedFunc then
                    pcall(function() rawset(v, key, function() return true end) end)
                end
            end
        end
    end
end

local function protectKick()
    local LP = game:GetService("Players").LocalPlayer
    if not LP then return end
    pcall(function()
        local old
        old = hookfunction(LP.Kick, newcclosure(function(self, reason)
            kickAttempts = kickAttempts + 1
            if checkcaller and checkcaller() then
                return old(self, reason)
            end
            return
        end))
    end)
end

local function verify()
    local n = 0
    if DetectedFunc then
        local ok, res = pcall(DetectedFunc, "kick", "t")
        if ok and res == true then n = n + 1 end
    end
    local detOk = true
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local e = rawget(v, "indexInstance")
            if type(e) == "table" and type(e[2]) == "function" then
                local ok, res = pcall(e[2])
                if not ok or res ~= false then detOk = false end
            end
        end
    end
    if detOk then n = n + 1 end
    if KillFunc then
        if pcall(KillFunc, "t") then n = n + 1 end
    else
        n = n + 1
    end
    return n >= 2
end

function Anti.Init()
    findClosures()
    hookDetected()
    hookKillDisconnect()
    neuterDetectors()
    protectKick()

    task.delay(2.2, function()
        findClosures()
        hookDetected()
        hookKillDisconnect()
        neuterDetectors()
        bypassed = verify()
        if bypassed then
            print("Adonis Anti-Exploit Bypassed successfully")
        else
            print("Adonis Anti-Exploit: partial (still safe)")
        end
    end)

    task.spawn(function()
        while true do
            task.wait(3.5)
            findClosures()
            pcall(hookDetected)
            neuterDetectors()
            hookKillDisconnect()
        end
    end)
end

function Anti.IsBypassed() return bypassed end
function Anti.GetKickAttempts() return kickAttempts end

-- "bypassed" | "issue" | "detected"
-- kickAttempts alone is not proof of live detection (hooks may count probes)
function Anti.GetStatus()
    if bypassed then
        return "bypassed"
    end
    if DetectedFunc == nil and KillFunc == nil then
        return "issue"
    end
    -- closures found but verify not confirmed yet
    return "issue"
end

function Anti.Resolve()
    pcall(findClosures)
    pcall(hookDetected)
    pcall(hookKillDisconnect)
    pcall(neuterDetectors)
    pcall(protectKick)
    local ok = false
    pcall(function()
        ok = verify()
    end)
    bypassed = ok and true or false
    if bypassed then
        print("Adonis Anti-Exploit Bypassed successfully")
    else
        print("Adonis Anti-Exploit: still resolving...")
    end
    return Anti.GetStatus()
end

return Anti
