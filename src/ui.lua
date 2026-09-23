--[[
    Flick · UI (Linoria library)
]]

local UI = {}

function UI.Init(Silent, ESP, Anti, Perf)
    local Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/K01dBy4spam935h/Flick_LarpSec/main/src/library.lua"
    ))()

    local Lib = Library.new({
        Title = "Flick · LarpSec",
        ToggleKey = Enum.KeyCode.RightShift,
    })

    local Window = Lib:CreateWindow({
        Title = "Flick · LarpSec",
        Size = Vector2.new(560, 480),
    })

    -- ── Combat ──────────────────────────────────────────────
    local TabCombat = Window:CreateTab("Combat")
    local GBSilent = TabCombat:CreateGroupbox("Silent Aim", "Left")
    local GBTarget = TabCombat:CreateGroupbox("Targeting", "Right")

    GBSilent:AddSection("Core")
    GBSilent:AddToggle({
        Text = "Enabled",
        Default = Silent.Config.Enabled,
        Callback = function(v) Silent.Config.Enabled = v end,
    })
    GBSilent:AddSlider({
        Text = "FOV",
        Min = 20, Max = 400, Default = Silent.Config.FOV,
        Callback = function(v) Silent.Config.FOV = v end,
    })
    GBSilent:AddSlider({
        Text = "Hit Chance",
        Min = 1, Max = 100, Default = Silent.Config.HitChance,
        Suffix = "%",
        Callback = function(v) Silent.Config.HitChance = v end,
    })
    GBSilent:AddToggle({
        Text = "Show FOV",
        Default = Silent.Config.ShowFOV,
        Callback = function(v) Silent.Config.ShowFOV = v end,
    })

    GBTarget:AddSection("Priority")
    GBTarget:AddDropdown({
        Text = "Hit Part",
        Values = {"Torso", "Head", "HumanoidRootPart", "UpperTorso"},
        Default = "Torso",
        Callback = function(v)
            if v == "Torso" then
                Silent.Config.HitPart = "UpperTorso"
                Silent.Config.PreferTorso = true
            else
                Silent.Config.HitPart = v
                Silent.Config.PreferTorso = false
            end
        end,
    })
    GBTarget:AddToggle({
        Text = "Visible Check",
        Default = Silent.Config.VisibleCheck,
        Callback = function(v) Silent.Config.VisibleCheck = v end,
    })
    GBTarget:AddToggle({
        Text = "Sticky Aim",
        Default = Silent.Config.Sticky,
        Callback = function(v) Silent.Config.Sticky = v end,
    })

    -- ── Rage ────────────────────────────────────────────────
    local TabRage = Window:CreateTab("Rage")
    local GBRage = TabRage:CreateGroupbox("Gun", "Left")
    local GBRageNote = TabRage:CreateGroupbox("Note", "Right")

    GBRage:AddSection("Reload")
    GBRage:AddToggle({
        Text = "Insta Reload",
        Default = Silent.Config.InstaReload,
        Callback = function(v) Silent.Config.InstaReload = v end,
    })

    GBRageNote:AddSection("Info")
    GBRageNote:AddLabel("Sets ReloadTime = 0")
    GBRageNote:AddLabel("Restores AmmoCount on Fire")
    GBRageNote:AddLabel("From Misc fields on shot data")

    -- ── Visuals ─────────────────────────────────────────────
    local TabVisuals = Window:CreateTab("Visuals")
    local GBPerf = TabVisuals:CreateGroupbox("Performance", "Left")
    local GBOverlay = TabVisuals:CreateGroupbox("Overlay", "Right")

    GBPerf:AddSection("Graphics")
    GBPerf:AddToggle({
        Text = "Performance Mode",
        Default = Perf.Config.Enabled,
        Callback = function(v) Perf.SetEnabled(v) end,
    })

    GBOverlay:AddSection("Counter")
    GBOverlay:AddToggle({
        Text = "FPS / Ping Counter",
        Default = Perf.Config.ShowFPS,
        Callback = function(v) Perf.Config.ShowFPS = v end,
    })

    -- ── ESP ─────────────────────────────────────────────────
    local TabESP = Window:CreateTab("ESP")
    local GBESP = TabESP:CreateGroupbox("ESP", "Left")
    local GBStyle = TabESP:CreateGroupbox("Style", "Right")

    GBESP:AddSection("Elements")
    GBESP:AddToggle({
        Text = "Enabled",
        Default = ESP.Config.Enabled,
        Callback = function(v) ESP.Config.Enabled = v end,
    })
    GBESP:AddToggle({
        Text = "Boxes",
        Default = ESP.Config.Boxes,
        Callback = function(v) ESP.Config.Boxes = v end,
    })
    GBESP:AddToggle({
        Text = "Names",
        Default = ESP.Config.Names,
        Callback = function(v) ESP.Config.Names = v end,
    })
    GBESP:AddToggle({
        Text = "Distance",
        Default = ESP.Config.Distance,
        Callback = function(v) ESP.Config.Distance = v end,
    })
    GBESP:AddToggle({
        Text = "Tracers",
        Default = ESP.Config.Tracers,
        Callback = function(v) ESP.Config.Tracers = v end,
    })

    GBStyle:AddSection("Appearance")
    GBStyle:AddDropdown({
        Text = "Tracer Origin",
        Values = {"Bottom", "Center", "Mouse"},
        Default = ESP.Config.TracerFrom,
        Callback = function(v) ESP.Config.TracerFrom = v end,
    })
    GBStyle:AddSlider({
        Text = "Max Distance",
        Min = 100, Max = 2000, Default = ESP.Config.MaxDistance,
        Suffix = "m",
        Callback = function(v) ESP.Config.MaxDistance = v end,
    })
    GBStyle:AddDropdown({
        Text = "Color",
        Values = {"Blue", "Purple", "Cyan", "Red", "Green", "White", "Orange"},
        Default = "Blue",
        Callback = function(name)
            local map = {
                Blue   = Color3.fromRGB(74, 144, 226),
                Purple = Color3.fromRGB(120, 90, 255),
                Cyan   = Color3.fromRGB(80, 200, 255),
                Red    = Color3.fromRGB(255, 70, 70),
                Green  = Color3.fromRGB(80, 255, 140),
                White  = Color3.fromRGB(240, 240, 245),
                Orange = Color3.fromRGB(255, 160, 60),
            }
            local c = map[name] or map.Blue
            ESP.Config.Color = c
            Silent.Config.FOVColor = c
        end,
    })

    -- ── Info ────────────────────────────────────────────────
    local TabInfo = Window:CreateTab("Info")
    local GBAdonis = TabInfo:CreateGroupbox("Adonis Bypass", "Left")
    local GBArch = TabInfo:CreateGroupbox("Architecture", "Right")
    local GBCtrl = TabInfo:CreateGroupbox("Controls", "Left")

    GBAdonis:AddSection("Hooks")
    GBAdonis:AddLabel("Detected → true")
    GBAdonis:AddLabel("Kill / Disconnect → no-op")
    GBAdonis:AddLabel("indexInstance → false")
    GBAdonis:AddLabel("debug.info spoofed")
    GBAdonis:AddLabel("Kick swallow · heartbeat ok")
    GBAdonis:AddLabel("Watchdog 3.5s")

    GBArch:AddSection("Gun")
    GBArch:AddLabel("BulletHandler.Fire(data)")
    GBArch:AddLabel("Origin locked ~1.7 studs")
    GBArch:AddSection("Silent")
    GBArch:AddLabel("Direction → torso priority")
    GBArch:AddSection("Rage")
    GBArch:AddLabel("Misc.ReloadTime / AmmoCount")

    GBCtrl:AddSection("Keys")
    GBCtrl:AddLabel("RightShift · menu")
    GBCtrl:AddLabel("Title bar · drag")

    Window.Frame.Visible = true
end

return UI
