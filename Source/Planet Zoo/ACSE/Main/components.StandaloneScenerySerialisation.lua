-----------------------------------------------------------------------
--/  @file   Components/StandaloneScenerySerialisation.lua
--/  @author My Self
--/
--/  @brief  Manager for Custom Component Scripts
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local coroutine = global.coroutine
local pairs = global.pairs
local ipairs = global.ipairs
local require = global.require
local table = require("Common.tableplus")
local string = global.string
local type = global.type
local Object = require("Common.object")
local Base = require("LuaComponentManagerBase")
local GameDatabase = require("Database.GameDatabase")
local ACSEComponentManager = module(..., (Object.subclass)(Base))

--global.api.debug.Trace("LOADING ACSEComponentManager")

ACSEComponentManager.tAPI = {"GetComponentNames", "CompleteWorldSerialisationLoad"}

-- Construct is defined by the parent class LuaComponentManagerBase, but
-- will initialize all sub components with the same ComponentManagerID
ACSEComponentManager.Construct = function(self, _nComponentManagerID)
    --global.api.debug.Trace("ACSEComponentManager:Construct()")
    -- Take over the default ComponentManagerBase constructor
    Base.Construct(self, _nComponentManagerID)

    -- Component manager Init
    self.Components = {}
    if GameDatabase.GetLuaComponents then
        for _sName, _tParams in pairs(GameDatabase.GetLuaComponents()) do
            api.debug.Trace("ACSE Adding Component: " .. _sName)
            local fComponent = require(_tParams)
            local Component = fComponent:new()
            Component:Construct(self.nComponentManagerID)
            self.Components[_sName] = Component
        end
    end
end

ACSEComponentManager.Configure = function(self)
    --global.api.debug.Trace("ACSEComponentManager:Configure()")
    --We are not providing any feature, we don't require any feature
    for sName, Component in pairs(self.Components) do
        Component:Configure()
    end
end

ACSEComponentManager.Init = function(self, _tWorldAPIs)
    global.api.debug.Trace("ACSEComponentManager:Init()")

    -- Custom component init
    local tWorldAPIs = api.world.GetWorldAPIs()
    self.worldserialisation = tWorldAPIs.worldserialisation
    self.transformAPI = tWorldAPIs.transform
    local fnSave = function(_tSave)
        return self:WorldSerialisationClient_Save(_tSave)
    end
    local fnLoad = function(_tLoad, _nLoadedVersion)
        return self:WorldSerialisationClient_Load(_tLoad, _nLoadedVersion)
    end
    local fnCanLoadOldVersion = function(_nOldVersion)
        return true
    end
    self.worldserialisation:RegisterWorldSerialisationClient(
        "StandaloneScenerySerialisation",
        1,
        fnSave,
        fnLoad,
        fnCanLoadOldVersion
    )
    self.tEntities = {}

    -- Component manager init
    for sName, Component in pairs(self.Components) do
        Component:Init(_tWorldAPIs)

        -- Expose component API to World APIs
        if #Component.tAPI > 0 then
            global.api.debug.Assert(global.api.sName == nil, "Component already exists in WorldAPIs()")
            global.api[string.lower(sName)] = Component
            _tWorldAPIs[string.lower(sName)] = Component
        end
    end

    -- Expose our custom API as well
    global.api.acsecomponentmanager = self
    _tWorldAPIs.acsecomponentmanager = self
end

ACSEComponentManager.Shutdown = function(self)
    global.api.debug.Trace("ACSEComponentManager:Shutdown()")
    -- component manager shutdown
    for sName, Component in pairs(self.Components) do
        Component:Shutdown()
    end

    -- original component shutdown
    self.worldserialisation:UnregisterWorldSerialisationClient("StandaloneScenerySerialisation")
    self.tEntities = {}
end

ACSEComponentManager.AddComponentsToEntities = function(self, _tArrayOfEntityIDAndParams, uToken)
    global.api.debug.Trace("ACSEComponentManager:AddComponentsToEntities()")

    -- Original component AddToEntities, only consider entities with PrefabName defined
    for _, tEntry in ipairs(_tArrayOfEntityIDAndParams) do
        if tEntry.tParams.PrefabName ~= nil then
            self.tEntities[tEntry.entityID] = {sPrefab = tEntry.tParams.PrefabName}
        end
    end

    -- Component manager AddToEntities
    for _, v in ipairs(_tArrayOfEntityIDAndParams) do
        --api.debug.Trace("ACSEEntityData: " .. table.tostring(v.entityID) .. " " .. table.tostring(v.tParams))
        
        -- tParams is the actual table in the prefab structure, if we modify it here we will end up affecting 
        -- all the future instances of this prefab, this is why it is important to make a copy of the original
        -- and work with this one.
        local tDataTable = table.copy(v.tParams)

        for key, value in pairs(tDataTable) do
            if global.type(key) == "string" and global.type(value) == "table" then
                if self.Components[key] ~= nil then

                    -- get parent Id in case we are a descendant prefab if we want to have access to the 
                    -- instantiated information. Anyway, there should only be one entity loaded in acseentity 
                    -- becuase we are cleaning up all each entities right after adding the components
                    
                    -- counts instances of a character in a string, gets the current entity path to know what 
                    -- position in the hierarchy are we, then request the top root parent ID
                    function repeats(s,c) local _,n = s:gsub(c,"") return n end
                    local instancedID = api.transform.GetParent(v.entityID) or v.entityID
                    local hierCount = repeats(api.entity.GetEntityPath(ventityID), "/")
                    for _=1,hierCount do instancedID = api.transform.GetParent(instancedID) end

                    -- If there is information about this entity, use it to populate the properties array
                    if global.api.entity.tLoadedEntities[instancedID] then

                        -- Recursively populate options array with prefab properties from outer layer to inner
                        local buildProperties = function (prefab, options)
                            if global.type(prefab) == "string" then prefab = global.api.entity.FindPrefab(prefab) end 
                            if prefab ~= "table" then return options end
                            if prefab.Properties then
                                for k,v in pairs(prefab.Properties) do if not options[k] then options[k] = v.Default or nil end end        
                            end
                            if prefab.Children then
                                for k,v in pairs(prefab.Children) do options = buildProperties(v, options) end
                            end
                            if prefab.Prefab then options = buildProperties(prefab.Prefab, options) end
                            return options
                        end

                        --/ No need a copy of this properties table, because we are only instacing this once
                        local tProperties = buildProperties(
                            global.api.entity.tLoadedEntities[instancedID].sPrefab,
                            global.api.entity.tLoadedEntities[instancedID].tProperties or {}
                        )
                        --global.api.debug.Trace("Options: " .. table.tostring(tProperties))

                        -- Recursively apply options array with prefab properties to the Data of this component
                        local applyProperties = function(data, options)
                            for k,v in global.pairs(data) do
                                if global.type(v) == 'table' then 
                                    if v.__property then 
                                        global.api.debug.Assert(options[v.__property], "Component requires a property but none provided for " .. k)
                                        data[k] = options[v.__property]
                                    else data[k] = applyProperties(v, options) end
                                end
                            end
                            return data
                        end
                        value = applyProperties(value, tProperties)

                    end

                    self.Components[key]:AddComponentsToEntities(
                        {
                            {entityID = v.entityID, tParams = value}
                        }
                    )

                    -- clean up acseentity table, since we don't know how many children this entity has
                    -- we can't assume we are the last one loading so we will leave it loaded in memory
                    -- it is a weak table reference and does not take any resources.
                    -- api.debug.Trace("ACSEEntityData: removing acseentity data")
                    -- global.api.entity.tLoadedEntities[v.entityID] = nil

                end
            end
        end
    end


    return true
end

ACSEComponentManager.RemoveComponentFromEntities = function(self, _tEntitiesArray)
    -- global.api.debug.Trace("ACSEComponentManager:RemoveComponentFromEntities()")

    -- Component manager remove from entities
    for sName, Component in pairs(self.Components) do
        -- Leave each component decide what entities need removal.
        Component:RemoveComponentFromEntities(_tEntitiesArray)
    end

    -- original component remove from entities
    for _, entityID in ipairs(_tEntitiesArray) do
        self.tEntities[entityID] = nil
    end
end

ACSEComponentManager.Advance = function(self, _nDeltaTime, _nUnscaledDeltaTime)
    --global.api.debug.Trace("ACSEComponentManager:Advance() " .. global.tostring(_nDeltaTime) )
    for sName, Component in pairs(self.Components) do
        if Component.Advance then
            Component:Advance(_nDeltaTime, _nUnscaledDeltaTime)
        end
    end
end

ACSEComponentManager.WorldSerialisationClient_Save = function(self, _tSave)
    -- Original component
    local transformAPI = self.transformAPI
    local worldserialisation = self.worldserialisation
    _tSave.tEntities = {}
    for entityID, tEntityData in table.orderedpairs(self.tEntities) do
        local serialisedEntityID = self.worldserialisation:SaveEntityID(entityID)
        local parentEntityID = transformAPI:GetParent(entityID)
        if parentEntityID then
            local serialisedParentEntityID = self.worldserialisation:SaveEntityID(parentEntityID)
        end
        table.insert(
            _tSave.tEntities,
            {
                entity = serialisedEntityID,
                sPrefab = tEntityData.sPrefab,
                transformQ = transformAPI:GetTransform(entityID),
                parent = serialisedParentEntityID
            }
        )
    end
end

ACSEComponentManager.WorldSerialisationClient_Load = function(self, _tLoad, _nLoadedVersion)
    -- Original component
    local worldserialisation = self.worldserialisation
    api.debug.Assert(self.loadCompletionToken == nil, "Completion token is nil")
    self.loadCompletionToken = api.entity.CreateRequestCompletionToken()
    local tEntities = _tLoad.tEntities
    for i = 1, #tEntities do
        local tLoadData = tEntities[i]
        local entityID = worldserialisation:LoadEntityID(tLoadData.entity)
        if tLoadData.parent then
            local parentEntityID = worldserialisation:LoadEntityID(tLoadData.parent)
        end
        api.entity.InstantiatePrefab(
            tLoadData.sPrefab,
            nil,
            self.loadCompletionToken,
            tLoadData.transformQ,
            parentEntityID,
            not parentEntityID or true,
            nil,
            entityID
        )
    end
    return true
end

-- Required for Planet Zoo, expects this component
ACSEComponentManager.CompleteWorldSerialisationLoad = function(self)
    -- Original component
    local ret = self.loadCompletionToken
    self.loadCompletionToken = nil
    return ret
end

--
-- Component Manager API
--
ACSEComponentManager.GetComponentNames = function(self)
    --global.api.debug.Trace("ACSEComponentManager:GetComponentNames()")
    local tNames = {}
    for sName, Component in pairs(self.Components) do
        table.append(tNames, sName)
    end
    return tNames
end
