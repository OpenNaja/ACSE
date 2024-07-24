-----------------------------------------------------------------------
--/  @file   ACSE.ComponentManager.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the ComponentManager engine API.
--/
--/  @Note   This module doesn't have a Shutdown function yet
--/  @Note   Required to support custom components and Ids
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local string       = global.string
local table        = global.table
local tostring     = global.tostring
local require      = global.require
local setmetatable = global.setmetatable
local getmetatable = global.getmetatable
local GameDatabase = require("Database.GameDatabase")
local Object       = require("Common.object")

local ComponentManager = module(..., Object.class)

ComponentManager.Init = function(self)
    local raw  = api.componentmanager

    api.componentmanager = setmetatable(
        {
            LookupComponentManagerID = function(...)
                return self:Api_LookupComponentManagerID(raw, ...)
            end,
            GetComponentManagerNameFromID = function(...)
                return self:Api_GetComponentManagerNameFromID(raw, ...)
            end,
        },
        { 
            __index = raw 
        }
    )

    api.acse.componentmanager = ComponentManager
end

ComponentManager.Api_LookupComponentManagerID = function(self, _raw, _sName)
    --api.debug.Trace("Api_LookupComponentManagerID: " .. global.tostring(_sName))
    local ret = _raw.LookupComponentManagerID(_sName)

    if not ret and global.api.acsecomponentmanager then 
        ret = global.api.acsecomponentmanager:GetComponentIDFromName(_sName)
    end
    return ret
end

ComponentManager.Api_GetComponentManagerNameFromID = function(self, _raw, _nID)
    --api.debug.Trace("Api_GetComponentManagerNameFromID: " .. global.tostring(_nID))
    local ret = _raw.GetComponentManagerNameFromID(_nID)
    if not ret and global.api.acsecomponentmanager then 
        ret = global.api.acsecomponentmanager:GetComponentNameFromID(_nID)
    end
    return ret
end

ComponentManager.Shutdown = function(self)
    api.componentmanager = getmetatable(api.componentmanager).__index
end
