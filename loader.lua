--[[
    Flick LarpSec loader
    loadstring(game:HttpGet("https://raw.githubusercontent.com/K01dBy4spam935h/Flick_LarpSec/main/loader.lua"))()
]]

local GITHUB_USER = "K01dBy4spam935h"
local GITHUB_REPO = "Flick_LarpSec"
local BRANCH      = "main"

local BASE = ("https://raw.githubusercontent.com/%s/%s/%s/src/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local function fetch(name)
    return loadstring(game:HttpGet(BASE .. name))()
end

-- anti first
local Anti = fetch("anti.lua")
Anti.Init()
task.wait(0.25)

local Silent = fetch("silent.lua")
local ESP    = fetch("esp.lua")
local Perf   = fetch("perf.lua")
local UI     = fetch("ui.lua")

task.spawn(function()
    task.wait(0.9)
    Silent.Init()
end)
ESP.Init()
Perf.Init()
UI.Init(Silent, ESP, Anti, Perf)
