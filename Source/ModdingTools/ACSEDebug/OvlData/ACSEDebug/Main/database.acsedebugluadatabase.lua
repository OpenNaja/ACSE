-----------------------------------------------------------------------
--/  @file   Database.ACSEDebugLuaDatabase.lua
--/  @author My Self
--/
--/  @brief  Handles ACSEDebug loading and database creation
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global = _G
local table = global.table
local require = require

local ACSEDebugLuaDatabase = module(...)

-- @brief add our custom databases
ACSEDebugLuaDatabase.AddContentToCall = function(_tContentToCall)
    table.insert(_tContentToCall, require("Database.ACSEDebug"))
end
