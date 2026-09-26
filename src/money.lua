--[[
    LarpSec · Money (Beta)
    Claim/reward remote attempts + client visual spoof
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Money = {}
Money.Config = {
    Enabled = false,
    Amount = 999999,
    Mode = "Client", -- Client | RemoteScan
}

local hookedStats = {}

-- only fire these (might grant currency if server is loose)
local CLAIM_KEYS = {
    "claim", "reward", "daily", "quest", "challenge", "time reward",
    "group reward", "ad", "bonus", "gift", "collect",
}

-- never fire these (spend / open purchase)
local SKIP_KEYS = {
    "purchase", "prompt", "bundle", "store", "buy", "intent",
    "gem", "limited", "product", "marketplace",
}

local function findMoneyValue()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, name in ipairs({"Cash", "Money", "Coins", "Currency", "Gold", "Credits", "Gems"}) do
            local v = ls:FindFirstChild(name)
            if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
                return v
            end
        end
        for _, c in ipairs(ls:GetChildren()) do
            if c:IsA("IntValue") or c:IsA("NumberValue") then
                local n = string.lower(c.Name)
                if n:find("cash") or n:find("money") or n:find("coin") or n:find("gem") then
                    return c
                end
            end
        end
    end
    for _, c in ipairs(LocalPlayer:GetDescendants()) do
        if c:IsA("IntValue") or c:IsA("NumberValue") then
            local n = string.lower(c.Name)
            if n:find("cash") or n:find("money") or n:find("coin") or n:find("currency") or n:find("gem") then
                return c
            end
        end
    end
    return nil
end

local function clientSpoof(amount)
    local v = findMoneyValue()
    if not v then return false, "no money value found" end
    pcall(function() v.Value = amount end)
    if not hookedStats[v] then
        hookedStats[v] = true
        v:GetPropertyChangedSignal("Value"):Connect(function()
            if Money.Config.Enabled and Money.Config.Mode == "Client" then
                if v.Value ~= Money.Config.Amount then
                    pcall(function() v.Value = Money.Config.Amount end)
                end
            end
        end)
    end
    return true, v:GetFullName() .. " = " .. tostring(v.Value)
end

local function classify(r)
    local path = ""
    pcall(function() path = string.lower(r:GetFullName()) end)
    local n = string.lower(r.Name)
    for _, k in ipairs(SKIP_KEYS) do
        if n:find(k, 1, true) or path:find(k, 1, true) then
            return "skip"
        end
    end
    for _, k in ipairs(CLAIM_KEYS) do
        if n:find(k, 1, true) or path:find(k, 1, true) then
            return "claim"
        end
    end
    return "other"
end

function Money.ScanRemotes()
    local claims, skipped, other = {}, {}, {}
    local function walk(root)
        if not root then return end
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                local c = classify(d)
                if c == "claim" then table.insert(claims, d)
                elseif c == "skip" then table.insert(skipped, d)
                end
            end
        end
    end
    pcall(function() walk(ReplicatedStorage) end)
    pcall(function() walk(LocalPlayer) end)
    return claims, skipped
end

local function tryFire(r, amount)
    local okCount = 0
    if r:IsA("RemoteEvent") then
        -- claim remotes usually take no amount — server decides
        if pcall(function() r:FireServer() end) then okCount = okCount + 1 end
        if pcall(function() r:FireServer(true) end) then okCount = okCount + 1 end
        if pcall(function() r:FireServer(amount) end) then okCount = okCount + 1 end
    elseif r:IsA("RemoteFunction") then
        if pcall(function() r:InvokeServer() end) then okCount = okCount + 1 end
        if pcall(function() r:InvokeServer(amount) end) then okCount = okCount + 1 end
    end
    return okCount
end

function Money.AttemptRemote(amount)
    amount = tonumber(amount) or Money.Config.Amount
    local claims, skipped = Money.ScanRemotes()
    print("[Money] claim/reward remotes:", #claims, "| skipped purchases:", #skipped)
    for _, r in ipairs(skipped) do
        print("[Money] skip", r:GetFullName())
    end
    local fired = 0
    for _, r in ipairs(claims) do
        local n = tryFire(r, amount)
        fired = fired + n
        print("[Money] claim", r:GetFullName(), "fires=", n)
    end
    return fired, claims
end

function Money.Apply()
    if not Money.Config.Enabled then return end
    if Money.Config.Mode == "Client" then
        local ok, info = clientSpoof(Money.Config.Amount)
        print("[Money] client spoof", ok, info)
        print("[Money] note: visual only — server balance unchanged")
    else
        Money.AttemptRemote(Money.Config.Amount)
        local ok, info = clientSpoof(Money.Config.Amount)
        print("[Money] client overlay", ok, info)
        print("[Money] if balance didn't rise, claims are server-gated (eligible only)")
    end
end

function Money.Init()
end

return Money
