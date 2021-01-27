-----------------------------------------------------------------------
--/  @file   ParkEnvironment.lua
--/  @author My Self
--/
--/  @frief  Starting Screen  Environments definition for Jurassic World
--/			 Evolution
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

global.api.debug.Trace("Custom StartScreen Environment loaded")

-- Default Start Screen Environment defintion from JWE 1.8
Module.EnvironmentPrototype = {
	SearchPaths = {"Managers"},
	Managers = {
		["Managers.GameUnlockManager"] = {},
		["Managers.GameWideProgressManager"] = {},
		["Managers.RecordsManager"] = {}
	}
}

-- Merge default protos with ACSE collected protos
if GameDatabase.GetStartEnvironmentManagers then
  for _sName, _tParams in pairs( GameDatabase.GetStartEnvironmentManagers() ) do
    global.api.debug.Trace("acse Adding Manager: " .. _sName)
	Module.EnvironmentPrototype['Managers'][_sName] = _tParams
  end
end

-- confirm the environment comply its proto
(Mutators.VerifyEnvironmentPrototypeModule)(Module)
