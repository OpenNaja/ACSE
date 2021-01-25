-----------------------------------------------------------------------
--/  @file   DinoTorporLuaDatabase.lua
--/  @author My Self
--/
--/  @brief  Handles loading data and managers for the DinoTorpor mod
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global  = _G
local api     = global.api
local table   = global.table
local pairs   = global.pairs

--/ Module creation
local DinoTorporData = module(...)

--/ Used as debug output for now
-- global.loadfile("Database.DinoTorpor.lua Loaded")

--/ List of custom managers to force injection on a park
DinoTorporData.tParkManagers  = {
	["Managers.DinoTorporManager"] = {}
}

-- @brief Add our custom Manager to the park
DinoTorporData.AddParkManagers = function(_fnAdd)
	local tData = DinoTorporData.tParkManagers
	for sManagerName, tParams in pairs(tData) do
		_fnAdd(sManagerName, tParams)
	end
end
