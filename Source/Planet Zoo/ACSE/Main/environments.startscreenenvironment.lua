-----------------------------------------------------------------------
--/  @file   Environment.StartScreenEnvironment.lua
--/  @author My Self
--/
--/  @brief  Starting Screen  Environments definition for Planet Zoo
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global   = _G
local api      = global.api
local require  = global.require
local module   = global.module
local type     = global.type
local pairs    = global.pairs
local loadfile = global.loadfile
local Main     = require("Database.Main")
local GameDatabase = require("Database.GameDatabase")
local Mutators = require("Environment.ModuleMutators")
local Module   = module(..., Mutators.EnvironmentPrototype)

api.debug.Trace("Custom StartScreen Environment loaded")

-- Default Start Screen Environment defintion from PZ 1.7.2.76346
Module.EnvironmentPrototype = {
    SearchPaths = {"Managers"},
    Managers = {
        ["Managers.HelpManager"] = {}
    }
}

-- Merge default protos with ACSE collected protos
if GameDatabase.GetStartEnvironmentManagers then
  for _sName, _tParams in pairs( GameDatabase.GetStartEnvironmentManagers() ) do
   api.debug.Trace("ACSE Adding Manager: " .. _sName)
	Module.EnvironmentPrototype['Managers'][_sName] = _tParams
  end
end

-- confirm the environment comply its proto
(Mutators.VerifyEnvironmentPrototypeModule)(Module)
