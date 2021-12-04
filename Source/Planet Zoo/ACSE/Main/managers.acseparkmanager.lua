-----------------------------------------------------------------------
--/  @file   Managers.ACSEParkManager.lua
--/  @author My Self
--/
--/  @brief  Boilerplate template for the park manager script
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
local ACSEParkManager = module(..., Mutators.Manager())

global.api.debug.Trace("ACSEParkManager loaded")

-- @Brief Init function for this manager
ACSEParkManager.Init = function(self, _tProperties, _tEnvironment)
	api.debug.Trace("ACSEParkManager:Init()")
end

-- @Brief Update function for this manager
ACSEParkManager.Advance = function(self, _nDeltaTime)
end

-- @Brief Activate function for this manager
ACSEParkManager.Activate = function(self)
end

-- @Brief Deactivate function for this manager
ACSEParkManager.Deactivate = function(self)
end

-- @Brief Shutdown function for this manager
ACSEParkManager.Shutdown = function(self)
	api.debug.Trace("ACSEParkManager:Shutdown()")
end

--/ Validate class methods and interfaces
(Mutators.VerifyManagerModule)(ACSEParkManager)
