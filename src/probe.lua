--[[
    LarpSec · probe.lua — money / currency architecture
    Read-only dump. Run, wait a few seconds, paste all [PROBE] lines.
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

local function safeName(inst)
    local ok, n = pcall(function() return inst:GetFullName() end)
    return ok and n or tostring(inst)
end

-- Flick: cash from kills ($5 body / $10 head), store, crates, quests, gems
-- Currency often NOT classic leaderstats — check attributes, GUI, profile tables

sep("1. PLAYER FOLDERS / VALUES")
pcall(function()
    for _, c in ipairs(LocalPlayer:GetChildren()) do
        log("child", c.ClassName, c.Name)
        if c:IsA("Folder") or c:IsA("Configuration") then
            for _, v in ipairs(c:GetChildren()) do
                if v:IsA("ValueBase") then
                    log("  value", v.ClassName, v.Name, "=", v.Value)
                else
                    log("  ", v.ClassName, v.Name)
                end
            end
        elseif c:IsA("ValueBase") then
            log("  value", c.ClassName, c.Name, "=", c.Value)
        end
    end
end)

sep("2. ATTRIBUTES ON PLAYER")
pcall(function()
    for k, v in pairs(LocalPlayer:GetAttributes()) do
        log("attr", k, typeof(v), tostring(v))
    end
    if LocalPlayer.Character then
        for k, v in pairs(LocalPlayer.Character:GetAttributes()) do
            log("char-attr", k, typeof(v), tostring(v))
        end
    end
end)

sep("3. MONEY-LIKE VALUES (deep under player)")
pcall(function()
    local keys = {"cash", "money", "coin", "currency", "gold", "gem", "credit", "bal", "wallet", "funds"}
    local found = 0
    for _, d in ipairs(LocalPlayer:GetDescendants()) do
        if d:IsA("ValueBase") then
            local n = string.lower(d.Name)
            for _, k in ipairs(keys) do
                if n:find(k, 1, true) then
                    log("HIT", d.ClassName, safeName(d), "=", tostring(d.Value))
                    found = found + 1
                    break
                end
            end
        end
    end
    log("money-like count:", found)
end)

sep("4. PLAYERGUI TEXT (money HUD)")
pcall(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then log("no PlayerGui") return end
    local keys = {"cash", "money", "coin", "currency", "gold", "gem", "credit", "$"}
    local hits = 0
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            local t = d.Text or ""
            local n = string.lower(d.Name)
            local path = string.lower(safeName(d))
            local match = false
            for _, k in ipairs(keys) do
                if n:find(k, 1, true) or path:find(k, 1, true) then match = true break end
            end
            if not match and (t:find("%$") or t:match("^[%d,%.]+$")) then
                -- numeric / dollar-looking labels near money folders
                if path:find("hud") or path:find("currency") or path:find("store") or path:find("cash") then
                    match = true
                end
            end
            if match and t ~= "" and #t < 40 then
                log("GUI", safeName(d), "text=", t)
                hits = hits + 1
                if hits > 40 then break end
            end
        end
    end
    log("gui hits:", hits)
end)

sep("5. REPLICATEDSTORAGE.REMOTES (classified)")
local CLAIM = {"claim", "reward", "quest", "challenge", "gift", "crate", "daily", "ad"}
local BUY = {"purchase", "prompt", "bundle", "store", "buy", "intent", "gem", "limited", "product"}
local claims, buys, other = {}, {}, {}
pcall(function()
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    local roots = { folder, ReplicatedStorage }
    local seen = {}
    for _, root in ipairs(roots) do
        if not root then continue end
        for _, d in ipairs(root:GetDescendants()) do
            if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and not seen[d] then
                seen[d] = true
                local n = string.lower(d.Name)
                local cls = "other"
                -- word-ish match (avoid 'ad' inside Reload)
                for _, k in ipairs(BUY) do
                    if n == k or n:find(k, 1, true) then cls = "buy" break end
                end
                if cls == "other" then
                    for _, k in ipairs(CLAIM) do
                        if k == "ad" then
                            if n:find("rewardedad") or n:find("adcooldown") or n:find("ad_event") or n == "ad" then
                                cls = "claim"
                            end
                        elseif n:find(k, 1, true) then
                            cls = "claim"
                            break
                        end
                    end
                end
                local entry = d.ClassName .. " " .. safeName(d)
                if cls == "claim" then table.insert(claims, entry)
                elseif cls == "buy" then table.insert(buys, entry)
                else table.insert(other, entry) end
            end
        end
    end
end)
log("CLAIM (" .. #claims .. ")")
for _, e in ipairs(claims) do log("  ", e) end
log("BUY (" .. #buys .. ")")
for _, e in ipairs(buys) do log("  ", e) end
log("OTHER sample (max 25 of " .. #other .. ")")
for i = 1, math.min(25, #other) do log("  ", other[i]) end

sep("6. GC TABLES with cash/money/coins/gems keys")
pcall(function()
    if not getgc then log("no getgc") return end
    local found = 0
    local keys = { Cash = true, Money = true, Coins = true, Currency = true, Gems = true, Gold = true, Balance = true, cash = true, money = true, coins = true, gems = true }
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" then
            local hit = {}
            local ok = pcall(function()
                for k, v in pairs(obj) do
                    if type(k) == "string" and keys[k] and (type(v) == "number" or type(v) == "string") then
                        hit[k] = v
                    end
                end
            end)
            if ok then
                local n = 0
                for _ in pairs(hit) do n = n + 1 end
                if n > 0 then
                    found = found + 1
                    local parts = {}
                    for k, v in pairs(hit) do
                        table.insert(parts, k .. "=" .. tostring(v))
                    end
                    log("table", table.concat(parts, " "))
                    if found >= 20 then break end
                end
            end
        end
    end
    log("gc money tables:", found)
end)

sep("7. MODULESCRIPTS mentioning currency")
pcall(function()
    local hits = 0
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("ModuleScript") then
            local n = string.lower(d.Name)
            if n:find("currency") or n:find("cash") or n:find("money") or n:find("store") or n:find("shop") or n:find("economy") or n:find("wallet") or n:find("reward") then
                log("mod", safeName(d))
                hits = hits + 1
            end
        end
    end
    log("module hits:", hits)
end)

sep("8. SAFE CLAIM SNAPSHOT")
-- fire only pure claim remotes (no purchase), snapshot GUI $ text before/after
local function snapshotMoneyGui()
    local out = {}
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, d in ipairs(pg:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text then
                local t = d.Text
                if t:find("%$") or t:match("^[%d,]+$") then
                    local path = string.lower(safeName(d))
                    if path:find("cash") or path:find("money") or path:find("coin") or path:find("currency") or path:find("gem") or path:find("hud") then
                        table.insert(out, d.Name .. "=" .. t)
                    end
                end
            end
        end
    end)
    return table.concat(out, " | ")
end

log("pre-claim GUI:", snapshotMoneyGui())
local claimNames = {
    "ClaimTimeReward", "ClaimGroupReward", "ClaimQuestReward", "ClaimChallengeReward",
    "RewardedAdEvent",
}
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    for _, name in ipairs(claimNames) do
        local r = remotes:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then
            log("FireServer()", name)
            pcall(function() r:FireServer() end)
        elseif r and r:IsA("RemoteFunction") then
            log("InvokeServer()", name)
            pcall(function() r:InvokeServer() end)
        else
            log("missing", name)
        end
    end
end)
task.wait(0.8)
log("post-claim GUI:", snapshotMoneyGui())

sep("9. ARCHITECTURE NOTES")
log("Flick cash sources (public):")
log("  kills: $5 body / $10 headshot (server-awarded)")
log("  daily quests / challenges / time rewards / crates / gems")
log("No public 'AddCash' remote — economy is server-authoritative")
log("Spendable spoof only if a claim/gift remote ignores eligibility")
log("")
log("INSTRUCTIONS:")
log("1. Paste ALL [PROBE] lines")
log("2. Note section 3/4/6 — where balance actually lives")
log("3. Note pre vs post claim GUI — did $ change?")
log("4. If section 6 shows a table with Cash=number, that id is client cache only")
