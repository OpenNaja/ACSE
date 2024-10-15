-----------------------------------------------------------------------
--/  @file   ACSE.Entity.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the Entity engine API.
--/
--/  @Note   This module does all the prefab transformation required
--/          for custom components to work.
--/  @Note   This module doesn't have a Shutdown function yet
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
                return self:Api_FindPrefab(raw, ...)
            end,
            CompilePrefab = function(...)
                return self:Api_CompilePrefab(raw, ...)
            end,
            AddComponentsToEntity = function(...)
                return self:Api_AddComponentsToEntity(raw, ...)
            end,
            RemoveComponentsFromEntity = function(...)
                return self:Api_RemoveComponentsFromEntity(raw, ...)
            end,
            InstantiatePrefab = function(...)
                return self:Api_InstantiatePrefab(raw, ...)
            end,
        },
        { 
            __index = raw 
        }
    )

    api.acse.entity = Entity
end

Entity.Api_FindPrefab = function(self, _raw, sPrefabName)
    --api.debug.Trace("Entity FindPrefab: " .. tostring(sPrefabName))

    -- PC1 case, FindPrefab doesn't exist, this prevents a crash
    if _raw.FindPrefab == nil then return nil end
    
    local ret = _raw.FindPrefab(sPrefabName)

    --[[
    if global.type(ret) == 'table' then
        local tPrefab = ret

        -- UnGroup components 
        ACSEEntity_UnGroupComponents = function(tPrefab, tComponentNames)
            local tComponents = {}

            if tPrefab['Components'] and tPrefab['Components']["StandaloneScenerySerialisation"] then
                local bRemove = true
                for key, value in pairs(tPrefab['Components']["StandaloneScenerySerialisation"]) do
                    if global.type(value) == 'table' then
                        tPrefab['Components'][key] = table.copy(value)
                        tPrefab['Components']["StandaloneScenerySerialisation"][key] = nil            
                    else
                        bRemove = true
                    end
                end
                if bRemove then
                    tPrefab['Components']["StandaloneScenerySerialisation"] = nil
                end
            end

            if tPrefab["Children"] then
                for sName, tData in pairs(tPrefab["Children"]) do
                    tPrefab["Children"][sName] = ACSEEntity_UnGroupComponents(tData, tComponentNames)
                end
            end

            return tPrefab
        end

        -- Get the components from ACSE after CallOnContent bootstrap
        local tCustomComponentNames = GameDatabase.GetLuaComponents()
        if table.count(tCustomComponentNames) > 0 then
            tPrefab = ACSEEntity_UnGroupComponents(tPrefab, tCustomComponentNames)
        end

        ret = tPrefab
    end
    ]]

    return ret
end

Entity.Api_CompilePrefab = function(self, _raw, tPrefab, sPrefabName)
    --api.debug.Trace("Entity CompilePrefab: " .. tostring(sPrefabName))

    ACSEEntity_GroupComponents = function(tPrefab, tComponentNames)
        local tComponents = {}

        if tPrefab['Components'] then 
            for sName, tData in pairs(tPrefab.Components) do
                if tComponentNames[sName] ~= nil then
                    tComponents[sName] = tData
                    tPrefab["Components"][sName] = nil
                end
            end
        end

        if table.count(tComponents) > 0 then
            tPrefab["Components"]["StandaloneScenerySerialisation"] = tComponents
        end

        if tPrefab["Children"] then
            for sName, tData in pairs(tPrefab["Children"]) do
                tPrefab["Children"][sName] = ACSEEntity_GroupComponents(tData, tComponentNames)
            end
        end

        return tPrefab
    end

    -- Get the components from ACSE after CallOnContent bootstrap
    local tCustomComponentNames = GameDatabase.GetLuaComponents()
    if table.count(tCustomComponentNames) > 0 then
        tPrefab = ACSEEntity_GroupComponents(tPrefab, tCustomComponentNames)
    end

    local ret = _raw.CompilePrefab(tPrefab, sPrefabName)
    if ret == nil then global.api.debug.Error("Error compiling prefab: " .. global.tostring(sPrefabName)) end
    return ret
end

Entity.Api_AddComponentsToEntity = function(self, _raw, nEntityId, tComponents, uToken)
    --api.debug.Trace("Entity AddComponentsToEntity: " .. tostring(nEntityId))
    return _raw.AddComponentsToEntity(nEntityId, tComponents, uToken)
end

Entity.Api_RemoveComponentsFromEntity = function(self, _raw, nEntityId, tComponents, uToken)
    --api.debug.Trace("Entity RemoveComponentsFromEntity: " .. tostring(nEntityId))
    return _raw.RemoveComponentsFromEntity(nEntityId, tComponents, uToken)
end

Entity.Api_InstantiatePrefab = function(self, _raw, sPrefab, sName, uToken, vTransform, nParent, bAttach, tProperties, nInstanceID)
    --api.debug.Trace("Entity InstantiatePrefab: " .. tostring(sPrefab))
    return _raw.InstantiatePrefab(sPrefab, sName, uToken, vTransform, nParent, bAttach, tProperties, nInstanceID)
end

Entity.Shutdown = function(self)
    api.entity = getmetatable(api.entity).__index
end
