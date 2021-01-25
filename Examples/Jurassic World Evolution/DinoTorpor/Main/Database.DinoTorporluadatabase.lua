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
local require = global.require

--/ Module creation
local DinoTorpor = module(...)

-- global.loadfile("TorporLuaDatabase Loaded")

-- @brief add our custom managers to the ACSE database
DinoTorpor.AddContentToCall = function(_tContentToCall)
	table.insert(_tContentToCall, require("Database.DinoTorpor"))
end
