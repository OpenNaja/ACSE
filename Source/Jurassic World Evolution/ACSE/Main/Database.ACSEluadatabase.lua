-----------------------------------------------------------------------
--/  @file   ACSELuaDatabase.lua
--/  @author My Self
--/
--/  @brief  Handles ACSE loading and database creation
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local table = global.table
local pairs = global.pairs
local ipairs = global.ipairs
local type  = global.type
local require = require
local ACSEDatabase = module(...)

-- global.loadfile("Database.ACSELuaDatabase.lua loaded")

-- @brief add our custom databases
ACSEDatabase.AddContentToCall = function(_tContentToCall)
	table.insert(_tContentToCall, require("Database.ACSE"))
end

