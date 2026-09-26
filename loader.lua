--[[
    LarpSec - Flick v1
    loadstring(game:HttpGet("https://raw.githubusercontent.com/K01dBy4spam935h/Flick_LarpSec/main/loader.lua"))()
]]

local GITHUB_USER = "K01dBy4spam935h"
local GITHUB_REPO = "Flick_LarpSec"
local BRANCH      = "main"

local BASE = ("https://raw.githubusercontent.com/%s/%s/%s/src/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local function fetch(name)
    local url = BASE .. name
    local src
    local ok, err = pcall(function()
        src = game:HttpGet(url)
    end)
    if not ok or not src or src == "" then
        error("[LarpSec] HttpGet failed: " .. tostring(name) .. " " .. tostring(err))
    end
    local fn, compileErr = loadstring(src)
    if not fn then
        error("[LarpSec] compile failed: " .. tostring(name) .. "\n" .. tostring(compileErr))
    end
    local mod
    ok, err = pcall(function()
        mod = fn()
    end)
    if not ok then
        error("[LarpSec] runtime failed: " .. tostring(name) .. "\n" .. tostring(err))
    end
    return mod
end

local Anti = fetch("anti.lua")
Anti.Init()
task.wait(0.25)

local Config    = fetch("config.lua")
local Silent    = fetch("silent.lua")
local ESP       = fetch("esp.lua")
local Perf      = fetch("perf.lua")
local KillSound = fetch("killsound.lua")
local UI        = fetch("ui.lua")

KillSound.Init(Config)
Silent.OnKillFeedback = function() KillSound.Play() end
pcall(function()
    (getgenv and getgenv() or _G).LarpSecKillSound = KillSound
end)

task.spawn(function()
    task.wait(0.9)
    Silent.Init()
end)
ESP.Init()
Perf.Init()
UI.Init(Silent, ESP, Anti, Perf, Config, KillSound)
