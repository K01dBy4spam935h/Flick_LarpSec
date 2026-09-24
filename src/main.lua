--[[
    LarpSec - Flick v1
    Entry · anti first
]]

local BASE = "https://raw.githubusercontent.com/K01dBy4spam935h/Flick_LarpSec/main/src/"

local function load(path)
    return loadstring(game:HttpGet(BASE .. path))()
end

local Anti = load("anti.lua")
Anti.Init()
task.wait(0.35)

local Silent = load("silent.lua")
local ESP    = load("esp.lua")
local Perf   = load("perf.lua")
local UI     = load("ui.lua")

Perf.Init()
ESP.Init()

task.spawn(function()
    task.wait(1.0)
    Silent.Init()
end)

UI.Init(Silent, ESP, Anti, Perf)
