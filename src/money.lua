--[[
    LarpSec · Money (Beta)
    Client visual spoof + remote scan/attempt for spendable paths
    True spendable cash only works if the game trusts a client remote.
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
local scanCache = {}

local function findMoneyValue()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, name in ipairs({"Cash", "Money", "Coins", "Currency", "Gold", "Credits"}) do
            local v = ls:FindFirstChild(name)
            if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
                return v
            end
        end
        for _, c in ipairs(ls:GetChildren()) do
            if c:IsA("IntValue") or c:IsA("NumberValue") then
                local n = string.lower(c.Name)
                if n:find("cash") or n:find("money") or n:find("coin") then
                    return c
                end
            end
        end
    end
    -- deeper scan under player
    for _, c in ipairs(LocalPlayer:GetDescendants()) do
        if (c:IsA("IntValue") or c:IsA("NumberValue")) then
            local n = string.lower(c.Name)
            if n:find("cash") or n:find("money") or n:find("coin") or n:find("currency") then
                return c
            end
        end
    end
    return nil
end

local function clientSpoof(amount)
    local v = findMoneyValue()
    if not v then return false, "no money value found" end
    pcall(function()
        v.Value = amount
    end)
    -- keep forcing while enabled (server may overwrite)
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
    return true, v:GetFullName()
end

local MONEY_NAME_KEYS = {
    "cash", "money", "coin", "currency", "gold", "credit", "earn", "reward", "payout", "purchase", "buy", "shop",
}

local function remoteLooksMonetary(r)
    local n = string.lower(r.Name)
    for _, k in ipairs(MONEY_NAME_KEYS) do
        if n:find(k, 1, true) then return true end
    end
    local path = ""
    pcall(function() path = string.lower(r:GetFullName()) end)
    for _, k in ipairs(MONEY_NAME_KEYS) do
        if path:find(k, 1, true) then return true end
    end
    return false
end

function Money.ScanRemotes()
    scanCache = {}
    local function walk(root)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                if remoteLooksMonetary(d) then
                    table.insert(scanCache, d)
                end
            end
        end
    end
    pcall(function() walk(ReplicatedStorage) end)
    pcall(function() walk(LocalPlayer) end)
    return scanCache
end

function Money.AttemptRemote(amount)
    amount = tonumber(amount) or Money.Config.Amount
    local remotes = Money.ScanRemotes()
    local fired = 0
    for _, r in ipairs(remotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                -- try a few common arg shapes
                r:FireServer(amount)
                r:FireServer(LocalPlayer, amount)
                r:FireServer({ Amount = amount, amount = amount, Value = amount })
                fired = fired + 1
            elseif r:IsA("RemoteFunction") then
                r:InvokeServer(amount)
                fired = fired + 1
            end
        end)
    end
    return fired, remotes
end

function Money.Apply()
    if not Money.Config.Enabled then return end
    if Money.Config.Mode == "Client" then
        local ok, info = clientSpoof(Money.Config.Amount)
        print("[Money] client spoof", ok, info)
    else
        local n, list = Money.AttemptRemote(Money.Config.Amount)
        print("[Money] remote attempts", n)
        for _, r in ipairs(list) do
            print("[Money] remote", r:GetFullName())
        end
        -- also client spoof for UI feedback
        clientSpoof(Money.Config.Amount)
    end
end

function Money.Init()
    -- nothing continuous unless enabled
end

return Money
