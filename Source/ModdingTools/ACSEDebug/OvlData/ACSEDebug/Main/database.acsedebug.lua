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

-- List of custom managers to force injection
local sParkEnvironment = "Environments.ParkEnvironment"
if api.game.GetGameName() == "Planet Zoo" then
    sParkEnvironment = "Environments.DarwinEnvironment"
end
ACSEDebug.tManagers = {
    ["Environments.StartScreenEnvironment"] = {
        ["Managers.ACSEDebugManager"] = {},
    },
    [sParkEnvironment] = {
        ["Managers.ACSEDebugManager"] = {}
    }
}

-- @brief Add our custom Manager to the different environments
ACSEDebug.AddManagers = function(_fnAdd)
    local tData = ACSEDebug.tManagers
    for sManagerName, tParams in pairs(tData) do
        _fnAdd(sManagerName, tParams)
    end
end
