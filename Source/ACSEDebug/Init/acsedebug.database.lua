-----------------------------------------------------------------------
--/  @file   ACSEDebug.Database.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes Database engine API to give access
--/          to mods.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local string       = global.string
local require      = global.require
local tostring     = global.tostring
local setmetatable = global.setmetatable

local Object       = require("Common.object")

local Database = module(..., Object.class)

Database.Init = function(self)
    local raw           = api.database

    -- TODO: Potentially allow loading/saving/creating fdbs in the local file system,
    --       use a sql3 dll bridge to read and run SQL commands on an empty named database.
    -- TODO: Potentially allow to load an sql script and run it through a named database.

    api.database = setmetatable(
        {
            GetNamedDatabases = function(...)
                return self:Api_GetNamedDatabases(raw, ...)
            end,
            CreateEmptyNamedDatabase = function(...)
                return self:Api_CreateEmptyNamedDatabase(raw, ...)
            end,
            LoadAndNameDatabase = function(...)
                return self:Api_LoadAndNameDatabase(raw, ...)
            end,
            UnloadNamedDatabase = function(...)
                return self:Api_UnloadNamedDatabase(raw, ...)
            end,
        },
        { 
            __index = raw 
        }
    )

    self.tNamedDatabases = {}
    api.acsedebug.database = Database
end

Database.Api_GetNamedDatabases = function(self, _raw)
    return self.tNamedDatabases
end

Database.Api_CreateEmptyNamedDatabase = function(self, _raw, sName, ...)
    local ret = _raw.CreateEmptyNamedDatabase(sName, ...)
    if ret then self.tNamedDatabases[sName] = { sSymbol = sName } end
    return ret
end

Database.Api_LoadAndNameDatabase = function(self, _raw, sSymbol, sName, ...)
    api.debug.Trace("Database.LoadAndNameDatabase with name " .. tostring(sName))
    local ret = _raw.LoadAndNameDatabase(sSymbol, sName, ...)
    if ret then self.tNamedDatabases[sName] = { sSymbol = sSymbol } end
    return ret
end

Database.Api_UnloadNamedDatabase = function(self, _raw, sName, ...)
    local ret = _raw.UnloadNamedDatabase(sName, ...)
    self.tNamedDatabases[sName] = nil
    return ret
end

Database.Shutdown = function(self)
    self.tNamedDatabases = {}
    api.database = global.getmetatable(api.database).__index
end