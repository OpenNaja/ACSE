-----------------------------------------------------------------------
--/  @file   Database.ACSEDebugluadatabase.lua
--/  @author My Self
--/
--/  @brief  Handles loading data and managers for the ACSE Debug mod
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local table = global.table
local pairs = global.pairs
local ipairs = global.ipairs

--/ Module creation
local ACSEDebug = module(...)

-- List of custom managers to force injection on the starting screen,
-- we define our own window manager
ACSEDebug.tStartScreenManagers = {
    ["Managers.ACSEDebugManager"] = {}
}

-- @brief Add our custom Manager to the starting screen
ACSEDebug.AddStartScreenManagers = function(_fnAdd)
    local tData = ACSEDebug.tStartScreenManagers
    for sManagerName, tParams in pairs(tData) do
        _fnAdd(sManagerName, tParams)
    end
end

-- List of custom managers to force injection on a park
ACSEDebug.tParkManagers = {
    ["Managers.ACSEDebugManager"] = {}
}

-- @brief Add our custom Manager to the starting screen
ACSEDebug.AddParkManagers = function(_fnAdd)
    local tData = ACSEDebug.tParkManagers
    for sManagerName, tParams in pairs(tData) do
        _fnAdd(sManagerName, tParams)
    end
end

--[[
ACSEDebug.tControls = {
    KeyboardSettings_DebugMenu = {
        ["index"] = 1,
        ["label"] = "[STRING_LITERAL:Value=\'Debug\']",
        ["id"] = "keyboardsettings_debug",
        ["itemRendererClass"] = 4                
    },
    -- This is a logical control, use the name to enable rebinding
    ACSEDebug_ToggleConsole = {
        ['index'] = 2,
        ["label"] = "[STRING_LITERAL:Value=\'Toggle Console\']",
        ["valueLabel"] = "[INPUT_ICON:InputName=#LogicalButton.ACSEDebug_ToggleConsole:device=keyboard#]",
        ["tooltipDescription"] = "[STRING_LITERAL:Value=\'Toggles visibility of the debug consonle On/Off\']",
        ["tooltipTitle"] = "[STRING_LITERAL:Value=\'Toggle Console\']",
        ["id"] = "keyboardsettings:acsedebug:toggleconsole",
        ["itemRendererClass"] = 5  -- Will use control name to rebind the keyboard
    },
    -- This is a tweakable, use the tweakable full name 
    ['Camera.Map.FOVDeg'] = {
        ['index'] = 3,
        ["maxValue"] = 100,
        ["incrementValue"] = 1,
        ["minValue"] = -10,
        ["label"] = "[STRING_LITERAL:Value=\'Custom Slider\']",
        ["id"] = "keyboardsettings:acsedebug:customslider",
        ["tooltipDescription"] = "[STRING_LITERAL:Value=\'Custom Slider Desc\']",
        ["tooltipTitle"] = "[STRING_LITERAL:Value=\'Custom Slider Title\']",
        ["tooltipImage"] = "AccessibilityHelpImage_DisableHelpImages",
        ["currValue"] = 0, -- will be replaced with the getter/setter of the tweakable
        ["itemRendererClass"] = 0, -- will use a the control name to access a tweakable for set/get
    },
    -- This is a tweakable, use the tweakable full name 
    ['Camera.KeepInsideParkBoundary'] = {
        ['index'] = 4,
        ["tooltipDescription"] = "[STRING_LITERAL:Value=\'Custom toggleable Desc\']",
        ["id"] = "keyboardsettings:acsedebug:customtoggeable",
        ["label"] = "[STRING_LITERAL:Value=\'Custom toggle value\']",
        ["tooltipTitle"] = "[STRING_LITERAL:Value=\'Custom toggleable Title\']",
        ["toggled"] = false, -- will be replaced with the getter/setter of the tweakable
        ["itemRendererClass"] = 1, -- Will use the control name to access a tweakable
    }
}
]]
-- Menu entry types:
--OptionsGUI.SLIDER = 0
--OptionsGUI.CHECKBOX = 1
--OptionsGUI.CAROUSEL = 3
--OptionsGUI.SUBHEADER = 4
--OptionsGUI.REBIND = 5
--OptionsGUI.HEADER = 6
--[[
ACSEDebug.tControls = {
  {
    KeyboardSettings_DebugMenu = {
        ["index"] = 1,
        ["label"] = "[STRING_LITERAL:Value='Debug']",
        ["itemRendererClass"] = 4 -- SubHeader type
    },
  },
  {
    -- This is a logical control, use the name to enable rebinding
    ACSEDebug_ToggleConsole = {
        ["index"] = "KeyboardSettings_DebugMenu",
        ["label"] = "[STRING_LITERAL:Value='Console UI']",
        ["tooltipDescription"] = "[STRING_LITERAL:Value='Toggles visibility of the debug console On/Off']",
        ["tooltipTitle"] = "[STRING_LITERAL:Value='Toggle Console']",
        ["itemRendererClass"] = 5 -- Rebind type, Will use control name to rebind the keyboard
    },
  },
  {
    -- This is a tweakable, use the tweakable full name
    ["Camera.Map.FOVDeg"] = {
        ["index"] = 'KeyboardSettings_DebugMenu',
        ["label"] = "[STRING_LITERAL:Value='Custom Slider']",
        ["tooltipDescription"] = "[STRING_LITERAL:Value='Custom Slider Desc']",
        ["tooltipTitle"] = "[STRING_LITERAL:Value='Custom Slider Title']",
        ["tooltipImage"] = "AccessibilityHelpImage_DisableHelpImages",
        ["itemRendererClass"] = 0 -- Slider Type, will use a the control name to access a tweakable for set/get
    },
  },
  {
    -- This is a tweakable, use the tweakable full name
    ["Camera.KeepInsideParkBoundary"] = {
        ["index"] = 'KeyboardSettings_DebugMenu',
        ["tooltipDescription"] = "[STRING_LITERAL:Value='Custom toggleable Desc']",
        ["id"] = "keyboardsettings:acsedebug:customtoggeable",
        ["label"] = "[STRING_LITERAL:Value='Custom toggle value']",
        ["tooltipTitle"] = "[STRING_LITERAL:Value='Custom toggleable Title']",
        ["itemRendererClass"] = 1 -- Checkbox type, Will use the control name to access a tweakable
    },
  },
}

-- @brief Add our custom keyboard controls to the settings
--  Doing indexed table to keep items in order
ACSEDebug.AddKeyboardControls = function(_fnAdd)
    local tData = ACSEDebug.tControls
    for _, _Control in ipairs(tData) do
        for sControlName, tParams in pairs(_Control) do
            _fnAdd(sControlName, tParams)
        end
    end
end
]]