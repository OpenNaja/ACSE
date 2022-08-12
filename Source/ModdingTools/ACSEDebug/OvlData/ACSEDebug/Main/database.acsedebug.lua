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

-- List of custom managers to force injection on a park, because ACSEDebug source
-- works for both PZ and JWE we need to identify the current game to fill the 
-- table with the right environments
ACSEDebug.tManagers = {
    ["Environments.StartScreenEnvironment"] = {
        ["Managers.ACSEDebugManager"] = {},
    },
}

if api.game.GetGameName() == "Planet Zoo" then
    ACSEDebug.tManagers["Environments.DarwinEnvironment"] = {
            ["Managers.ACSEDebugManager"] = {}
    }
end

if api.game.GetGameName() == "Jurassic World Evolution" then
    ACSEDebug.tManagers["Environments.ParkEnvironment"] = {
        ["Managers.ACSEDebugManager"] = {}
    }
end

if api.game.GetGameName() == "Jurassic World Evolution 2" then
    ACSEDebug.tManagers["Environments.ParkEnvironment"] = {
        ["Managers.ACSEDebugManager"] = {}
    }
    ACSEDebug.tManagers["Environments.ModelViewerEnvironment"] = {
        ["Managers.ACSEDebugManager"] = {}
    }
end


-- @brief Add our custom Manager to the different environments
ACSEDebug.AddManagers = function(_fnAdd)
    local tData = ACSEDebug.tManagers
    for sManagerName, tParams in pairs(tData) do
        _fnAdd(sManagerName, tParams)
    end
end
