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
	GetACSEVersionString = function()
		return api.acse.GetACSEVersionString()
	end,

	--/ have access to the tweakables
	GetAllTweakables = function()
		return api.acse.GetTweakables()
	end,
}

api.debug.Trace("ACSE " .. api.acse.GetACSEVersionString() .. " Running on " .. global._VERSION)


-- @brief Database init
ACSE.Init = function()

  ACSE._initLuaOverrides()
  global.api.debug.Trace("ACSE:Init()")

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

  -- Register our own custom shell commands
  ACSE.tShellCommands = {
  	api.debug.RegisterShellCommand(
  		function(tEnv, tArgs)
  			tweakable = api.acse.GetDebugTweakable(tArgs[1])
  			if tweakable ~= nil then
  				tweakable.value = tArgs[2]
  			end
      end, 
      "SetTweakable {String} {Number}", 
      "Changes the value of a tweakable.\n"
    ),
  	api.debug.RegisterShellCommand(
  		function(tEnv, tArgs)
 				api.debug.Trace("List of Tweakables:")
  			for k,v in pairs(api.acse.tTweakables) do
  				api.debug.Trace(v.id .. " = " .. tostring(v.val))
  			end
      end, 
      "ListTweakables", 
      "Prints a list of the current tweakables and its values.\n"
    ),
  }

end

-- @brief Environment Shutdown
ACSE.Shutdown = function()
  global.api.debug.Trace("ACSE:Shutdown()")

  -- Remove custom commands
  for i,oCommand in ipairs(ACSE.tShellCommands) do
    api.debug.UnregisterShellCommand(oCommand)
  end
  ACSE.tShellCommands = nil

  -- Restore Lua environment
  ACSE._shutdownLuaOverrides()
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

-- @brief Add our custom Manager to the starting screen
ACSE.AddStartScreenManagers = function(_fnAdd)
  local tData = ACSE.tStartScreenManagers
  for sManagerName, tParams in pairs(tData) do
    _fnAdd(sManagerName, tParams)
  end
end

-- List of custom managers to force injection on a park
ACSE.tParkManagers  = {
	["Managers.ACSEParkManager"] = {}
}

-- @brief Add our custom Manager to the starting screen
ACSE.AddParkManagers = function(_fnAdd)
  local tData = ACSE.tParkManagers
  for sManagerName, tParams in pairs(tData) do
    _fnAdd(sManagerName, tParams)
  end
end

-- @Brief Perform any custom Lua:global/api updates
ACSE._initLuaOverrides = function()

  -- Perform Lua override
  local raw = global.api.debug
  local tMetaTable = {}
  tMetaTable._sampleAPI = function(...)
    return self:_sampleAPI(raw, ...)
  end
--  global.api.debug = global.setmetatable(tMetaTable, { __index = raw })
  global.api.debug = global.setmetatable(global.api.acse, { __index = raw })
  global.api.debug.Trace("Exiting lua overrides")



end

-- @Brief Undo all Lua changes so the game exists gracefully
ACSE._shutdownLuaOverrides = function()
 --  Perform API/Lua clean up
   api.debug = global.getmetatable(api.debug).__index
end

ACSE._sampleAPI = function(self, raw, test)
    return 
end


