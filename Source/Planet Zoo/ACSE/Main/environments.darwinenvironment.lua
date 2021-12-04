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


-- Merge default Managers with ACSE collected protos
if GameDatabase.GetParkEnvironmentManagers then
  for _sName, _tParams in pairs( GameDatabase.GetParkEnvironmentManagers() ) do
    api.debug.Trace("ACSE Adding Manager: " .. _sName)
    Module.EnvironmentPrototype['Managers'][_sName] = _tParams
  end
end

-- confirm the environment comply its proto
(Mutators.VerifyEnvironmentPrototypeModule)(Module)
