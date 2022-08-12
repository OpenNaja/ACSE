-----------------------------------------------------------------------
--/  @file   Managers.ACSEStartScreenManager.lua
--/  @author My Self
--/
--/  @brief  Boilerplate template for the starting screen manager script
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local pairs = global.pairs
local require = global.require
local module = global.module
local table = require("Common.tableplus")
local Object = require("Common.object")
local Mutators = require("Environment.ModuleMutators")
local ACSEStartScreenManager= module(..., Mutators.Manager())

global.api.debug.Trace("ACSE StartScreen manager loaded")

-- @Brief Init function for this manager
ACSEStartScreenManager.Init = function(self, _tProperties, _tEnvironment)
	global.api.debug.Trace("ACSEStartScreenManager:Init()")
end

-- @Brief Update function for this manager
ACSEStartScreenManager.Advance = function(self, _nDeltaTime)
end

-- @Brief Activate function for this manager
ACSEStartScreenManager.Activate = function(self)
end

-- @Brief Deactivate function for this manager
ACSEStartScreenManager.Deactivate = function(self)
end

-- @Brief Shutdown function for this manager
ACSEStartScreenManager.Shutdown = function(self)
end

--/ Validate class methods and interfaces
(Mutators.VerifyManagerModule)(ACSEStartScreenManager)

