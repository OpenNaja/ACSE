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
