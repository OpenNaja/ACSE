-----------------------------------------------------------------------
--/  @file   EnvironmentPrototypes.lua
--/  @author My Self
--/
--/  @brief  Creates a prototypes database for modules to hook into the
--           game environment or alter the current ones.
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local pairs = pairs
local type = type
local ipairs = ipairs
local next = global.next
local table = require("Common.tableplus")
local Main = require("Database.Main")
local GameDatabase = require("Database.GameDatabase")
local ACSE = module(...)

-- Constant version
ACSE.nVersion = 0.231

-- List of protos/managers to populate from other mods
ACSE.tParkEnvironmentProtos  = {}
ACSE.tStartEnvironmentProtos = {}

-- Definition of our own database methods
ACSE.tDatabaseMethods   = {
	--/ Park environment hook
	GetParkEnvironmentProtos = function()
		return ACSE.tParkEnvironmentProtos
	end,

	--/ Starting screen environment hook
	GetStartEnvironmentProtos = function()
		return ACSE.tStartEnvironmentProtos
	end,

	--/ Starting screen environment managers
	GetStartEnvironmentManagers = function()
		return ACSE.tStartEnvironmentProtos['Managers']
	end,

	--/ park environment managers
	GetParkEnvironmentManagers = function()
		return ACSE.tParkEnvironmentProtos['Managers']
	end,

	--/ version info
	GetACSEVersion = function()
		return ACSE.nVersion
	end
}

global.api.debug.Trace("ACSE " .. ACSE.nVersion .. " loaded")

-- @brief Database init
ACSE.Init = function()

	ACSE.tParkEnvironmentProtos  = { SearchPaths = {},	Managers = {} }
	ACSE.tStartEnvironmentProtos = { SearchPaths = {},	Managers = {} }

	--/ Request Starting Screeen Managers from other mods
	Main.CallOnContent("AddStartScreenManagers",  function(_sName, _tParams)
		if type(_sName) == 'string' and type(_tParams) == 'table' then
			ACSE.tStartEnvironmentProtos['Managers'][_sName] = _tParams
		end
	end
	)

	--/ Request Park Managers from other mods
	Main.CallOnContent("AddParkManagers",  function(_sName, _tParams)
		if type(_sName) == 'string' and type(_tParams) == 'table' then
			ACSE.tParkEnvironmentProtos['Managers'][_sName] = _tParams
		end
	end
	)

end

-- @brief Environment Shutdown
ACSE.Shutdown = function()
end

-- @brief Called when a Reinit is about to happen
ACSE.ShutdownForReInit = function()
end

-- @brief adds our custom database methods to the main game database
ACSE.AddDatabaseFunctions = function(_tDatabaseFunctions)
	for sName,fnFunction in pairs(ACSE.tDatabaseMethods) do
		_tDatabaseFunctions[sName] = fnFunction
	end
end

-- List of custom managers to force injection on the starting screen
ACSE.tStartScreenManagers = {
	["Managers.ACSEStartScreenManager"] = {}
}

-- List of custom managers to force injection on a park
ACSE.tParkManagers  = {
	["Managers.ACSEParkManager"] = {}
}

-- @brief Add our custom Manager to the starting screen
ACSE.AddStartScreenManagers = function(_fnAdd)
  local tData = ACSE.tStartScreenManagers
  for sManagerName, tParams in pairs(tData) do
    _fnAdd(sManagerName, tParams)
  end
end

-- @brief Add our custom Manager to the starting screen
ACSE.AddParkManagers = function(_fnAdd)
  local tData = ACSE.tParkManagers
  for sManagerName, tParams in pairs(tData) do
    _fnAdd(sManagerName, tParams)
  end
end


