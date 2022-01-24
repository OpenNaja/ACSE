-----------------------------------------------------------------------
--/  @file   Environments.DarwinEnvironment.lua 
--/  @author My Self
--/
--/  @brief  Park Environments definition for Planet Zoo
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local loadfile = global.loadfile
local require = global.require
local module = global.module
local type = global.type
local pairs = global.pairs
local GameDatabase = require("Database.GameDatabase")
local Mutators = require("Environment.ModuleMutators")
local Module = module(..., Mutators.EnvironmentPrototype)

api.debug.Trace("Custom Park Environment loaded")

-- Default Darwin Environment definition from PZ 1.7.2.76346
Module.EnvironmentPrototype = {
    SearchPaths = {"Managers"},
    Managers = {
        ["Managers.CashSpentPopupManager"] = {},
        ["Managers.GuestCountHistoryManager"] = {},
        ["Managers.ScenarioManager"] = {},
        ["Managers.ScenarioEditorManager"] = {},
        ["Managers.ScenarioIntroManager"] = {},
        ["Managers.ScenarioScriptManager"] = {},
        ["Managers.ParkRatingManager"] = {},
        ["Managers.UIPersistenceManager"] = {},
        ["Managers.NotificationManager"] = {},
        ["Managers.MarketingManager"] = {},
        ["Managers.ParkDemographicsManager"] = {},
        ["Managers.DLCPopupManager"] = {},
        ["Managers.AchievementManager"] = {},
        ["Managers.CheatManager"] = {},
        ["Managers.HeatMapManager"] = {},
        ["Managers.CommsManager"] = {},
        ["Managers.CinematicsManager"] = {},
        ["Managers.HelpManager"] = {},
        ["Managers.CameraEffectsManager"] = {}
    }
}

if api.debug.IsDebugAllowed() then
    Module.EnvironmentPrototype.Managers["Managers.SceneryDebugManager"] = {}
end


-- Merge default protos with ACSE collected protos
if GameDatabase.GetParkEnvironmentManagers then

    Module._merge = function(a, b, bModifyOnly)
        if global.type(a) == "table" and global.type(b) == "table" then
            for k, v in global.pairs(b) do
                if global.type(v) == "table" and global.type(a[k] or false) == "table" then
                    Module._merge(a[k], v, bModifyOnly)
                else
                    if not bModifyOnly or bModifyOnly == false or (bModifyOnly == true and a[k] ~= nil) then
                        a[k] = v
                    end
                end
            end
        end
        return a
    end

  for _sName, _tParams in global.pairs( GameDatabase.GetParkEnvironmentManagers() ) do

        if not _tParams.__inheritance or _tParams.__inheritance == 'Overwrite' then
            api.debug.Trace("ACSE Adding Manager: " .. _sName)
            Module.EnvironmentPrototype['Managers'][_sName] = _tParams
        end
        if _tParams.__inheritance == 'Append' then
            api.debug.Trace("ACSE Merging Manager: " .. _sName)
            Module.EnvironmentPrototype['Managers'][_sName] = _merge(Module.EnvironmentPrototype['Managers'][_sName], _tParams)
        end
        if _tParams.__inheritance == 'Modify' then
            api.debug.Trace("ACSE Modifying Manager: " .. _sName)
            Module.EnvironmentPrototype['Managers'][_sName] = _merge(Module.EnvironmentPrototype['Managers'][_sName], _tParams, true)
        end
        -- Any other case will be ignored
  end
end


-- confirm the environment comply its proto
(Mutators.VerifyEnvironmentPrototypeModule)(Module)
