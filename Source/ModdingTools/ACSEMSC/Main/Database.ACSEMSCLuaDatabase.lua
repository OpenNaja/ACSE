-----------------------------------------------------------------------
--/  @file   Database.ACSEMSCLuaDatabase.lua
--/  @author My Self
--/
--/  @brief  Provides modding commands for ACSE
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global = _G
local table = global.table
local require = require

local ACSEMSCLuaDatabase = module(...)

-- @brief add our custom databases
ACSEMSCLuaDatabase.AddContentToCall = function(_tContentToCall)
    table.insert(_tContentToCall, require("Database.ACSEMSC"))
end
