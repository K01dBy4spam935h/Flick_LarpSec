--[[
    Flick · Anti-Detection / Adonis Neutralizer
    Professional grade · early + continuous
]]

local Anti = {}

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok and res
end

-- ─── core: neuter Adonis detection tables ───────────────────────────────────
local function neuterTable(v)
    if type(v) ~= "table" then return end

    -- Detected(method, info) → always return true (no flag)
    local det = rawget(v, "Detected")
    if type(det) == "function" then
        safe(rawset, v, "Detected", function() return true end)
    end

    -- Kill / Kick fallback
    local kill = rawget(v, "Kill")
    if type(kill) == "function" then
        safe(rawset, v, "Kill", function() end)
    end

    -- indexInstance detector payload
    local idx = rawget(v, "indexInstance")
    if type(idx) == "table" then
        safe(rawset, v, "indexInstance", {"kick", function() end})
    end

    -- namecallInstance / other common Adonis keys
    for _, key in ipairs({"namecallInstance", "newIndexInstance", "HookDetected", "Tamper", "AntiCheat"}) do
        local val = rawget(v, key)
        if type(val) == "function" then
            safe(rawset, v, key, function() return true end)
        elseif type(val) == "table" then
            safe(rawset, v, key, {})
        end
    end
end

function Anti.ScanAndNeuter()
    local count = 0
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local hasDet = type(rawget(v, "Detected")) == "function"
            local hasKill = type(rawget(v, "Kill")) == "function"
            local hasIdx  = type(rawget(v, "indexInstance")) == "table"
            local hasVars = rawget(v, "Variables") ~= nil and rawget(v, "Process") ~= nil

            if hasDet or hasKill or hasIdx or hasVars then
                neuterTable(v)
                count = count + 1
            end
        end
    end
    return count
end

-- ─── protect LocalPlayer:Kick / Players:Kick ────────────────────────────────
function Anti.ProtectKick()
    local LP = game:GetService("Players").LocalPlayer
    if not LP then return end

    -- soft: replace Kick with no-op when called from non-executor context
    local oldKick
    oldKick = hookfunction(LP.Kick, newcclosure(function(self, ...)
        if checkcaller and checkcaller() then
            return oldKick(self, ...)
        end
        -- swallow Adonis / anti-cheat kicks
        return
    end))

    -- also cover the Players service path if present
    local Players = game:GetService("Players")
    if Players.Kick then
        local oldPKick
        oldPKick = hookfunction(Players.Kick, newcclosure(function(self, ...)
            if checkcaller and checkcaller() then
                return oldPKick(self, ...)
            end
            return
        end))
    end
end

-- ─── continuous re-scan (Adonis sometimes rebuilds tables) ──────────────────
function Anti.StartWatchdog(interval)
    interval = interval or 4
    task.spawn(function()
        while true do
            Anti.ScanAndNeuter()
            task.wait(interval)
        end
    end)
end

-- ─── entry ──────────────────────────────────────────────────────────────────
function Anti.Init()
    -- phase 1: immediate
    local n = Anti.ScanAndNeuter()
    print(string.format("[Anti] initial neuter: %d tables", n))

    -- phase 2: kick protection
    pcall(Anti.ProtectKick)

    -- phase 3: delayed second pass (Adonis late init)
    task.delay(2.5, function()
        local n2 = Anti.ScanAndNeuter()
        print(string.format("[Anti] delayed neuter: %d tables", n2))
    end)

    -- phase 4: watchdog
    Anti.StartWatchdog(5)

    print("[Anti] Adonis / tamper protection active")
end

return Anti
