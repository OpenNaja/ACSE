-----------------------------------------------------------------------
--/  @file   ACSEDebug.Entity.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the Entity engine API.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local string       = global.string
local pairs        = global.pairs
local tostring     = global.tostring
local require      = global.require
local setmetatable = global.setmetatable
local getmetatable = global.getmetatable
local table        = require('common.tableplus')
local GameDatabase = require("Database.GameDatabase")
local Object       = require("Common.object")

local Entity = module(..., Object.class)

Entity.Init = function(self)
    local raw  = api.entity

    api.entity = setmetatable(
        {
            FindPrefab = function(...)
                local ret = self:Api_FindPrefab(raw, ...)
                return ret
            end,
            FindEntityByName = function(...)
                return self:Api_FindEntityByName(raw, ...)
            end,
            InstantiatePrefab = function(...)
                --api.debug.Trace("Instantiate prefab")
                return self:Api_InstantiatePrefab(raw, ...)
            end,
            InstantiateDesc = function(...)
                --api.debug.Trace("Instantiate Desc")
                return self:Api_InstantiateDesc(raw, ...)
            end,
            HaveRequestsCompleted = function(...)
                return self:Api_HaveRequestsCompleted(raw, ...)
            end,
        },
        { 
            __index = raw 
        }
    )

    api.acsedebug.entity = Entity
end

Entity.Api_FindPrefab = function(self, _raw, sPrefabName)
    api.debug.Trace("Entity FindPrefab: " .. tostring(sPrefabName))
    local ret = _raw.FindPrefab(sPrefabName)
    return ret
end
Entity.Api_FindEntityByName = function(self, _raw, sName, nParentID)
    --api.debug.Trace("Entity FindEntityByName: " .. tostring(sName) .. " Parent: " .. tostring(nParentID))
    local ret = _raw.FindEntityByName(sName, nParentID)
    --api.debug.Trace("Entity found: " .. tostring(ret))
    return ret
end

Entity.Api_InstantiatePrefab = function(self, _raw, sPrefab, sName, uToken, vTransform, nParent, bAttach, tProperties, nInstanceID)
    --api.debug.Trace("Entity InstantiatePrefab: " .. tostring(sPrefab))
    local ret = _raw.InstantiatePrefab(sPrefab, sName, uToken, vTransform, nParent, bAttach, tProperties, nInstanceID)
    api.debug.Trace("InstantiatePrefab " .. tostring(sPrefab)  .. " with entityID: " .. tostring(ret))
    return ret
end

Entity.Api_InstantiateDesc = function(self, _raw, sPrefab, uToken)
    --api.debug.Trace("Entity InstantiatePrefab: " .. tostring(sPrefab))
    local ret = _raw.InstantiateDesc(sPrefab, uToken)
    api.debug.Trace("InstantiateDesc " .. tostring(sPrefab)  .. " with entityID: " .. tostring(ret))
    return ret
end

Entity.Api_HaveRequestsCompleted = function(self, _raw, uToken)
    --api.debug.Trace("Entity HaveRequestsCompleted: " .. tostring(uToken))
    local ret = _raw.HaveRequestsCompleted(uToken)
    --api.debug.Trace("Entity result: " .. tostring(ret))
    return ret
end

Entity.Shutdown = function(self)
    api.entity = getmetatable(api.entity).__index
end