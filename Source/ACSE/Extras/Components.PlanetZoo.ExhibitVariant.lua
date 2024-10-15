-----------------------------------------------------------------------
-- @file    Components.ExhibitVariant.lua
-- @author  Inaki
--
-- @brief   Creates a game component to handle color variation and pattern
--          for exhibit species.
--
-- @see     https://github.com/OpenNaja/ACSE
-- @version 1.0
-- @require ACSE >= 0.6 to work.
--
-- Note: This file has been created automatically with CobraModdingTool
-----------------------------------------------------------------------
local global      = _G

local api         = global.api
local require     = global.require
local type        = global.type
local pairs       = global.pairs
local ipairs      = global.ipairs
local math        = global.math
local table       = require("Common.tableplus")
local Object      = require("Common.object")
local Base        = require("LuaComponentManagerBase")

--
-- @package Components
-- @class ExhibitVariant
--
local ExhibitVariant  = module(..., Object.subclass(Base))

-- Mod debug levels and default log filter
ExhibitVariant.DebugLevels = {
    Always  = 0,
    Error   = 1,
    Warning = 2,
    Info    = 3,
    Debug   = 4,
    Extra   = 5,
}
ExhibitVariant.DebugLevel = ExhibitVariant.DebugLevels.Info

ExhibitVariant.Debug = function(self, nLevel, ...)
    if nLevel <= self.DebugLevel then
        local tArgs = {...}
        local sMsg = ''
        for _, v in ipairs(tArgs) do
            if global.type(v) ~= 'string' then
                sMsg = sMsg .. table.tostring(v, nil, nil, nil, true) .. " "
            else
                sMsg = sMsg .. v .. " "
            end
        end
        api.debug.Trace(sMsg)
        --api.debug.WriteLine(1, sMsg)
    end
end

--
-- @brief List of our supported APIs, accessible through:
-- api.ExhibitVariant:SetExhibitAnimalVisualData(nEntityID, 1.0, 1.0, 1.0, 1.0)  
-- 
-- If no more implementors are added, consider if this interface is actually necessary rather 
-- than just calling methods on the component manager directly.

-- API Needs to exist
ExhibitVariant.tAPI = {
    'SetExhibitAnimalVisualData',
    'GetExhibitAnimalVisualData',
    'SetExhibitAnimalVisualColour',
    'GetExhibitAnimalVisualColour',
    'SetExhibitAnimalVisualPattern',
    'GetExhibitAnimalVisualPattern',
    'SetExhibitAnimalVisualMorphInt',
    'GetExhibitAnimalVisualMorphInt',
}

--
-- @brief Called to initalize the component on environment start
-- @param _tWorldAPIs (table) table of api methods available from the current environment.
--
ExhibitVariant.Init = function(self, _tWorldAPIs)
    self:Debug(self.DebugLevels.Always, "ExhibitVariant:Init()")

    -- Save a copy of the world API, we'll need them later
    self.tWorldAPIs = _tWorldAPIs

    -- Get the fdb exhibit animal info, size and age
    self.animalSizeData = {} 
    self.animalAgesData = {}

    -- Register our own receivers
    ExhibitVariant.tMessageRecievers = {
        -- Exhibit Animal Added gets called a new animal is spawned in an Exhibit, including births
        [api.messaging.MsgType_ExhibitAnimalAddedMessage] = function(_tMessages)
            self:HandleMsgType_ExhibitAnimalAddedMessage(_tMessages)
        end,
        -- Exhibit Animal Added gets called a new animal is despawned in an Exhibit, including deaths
        [api.messaging.MsgType_ExhibitAnimalRemovedMessage] = function(_tMessages)
            self:HandleMsgType_ExhibitAnimalRemovedMessage(_tMessages)
        end,
    }
    for nMessageType,fnReceiver in pairs(ExhibitVariant.tMessageRecievers) do
        api.messaging.RegisterReceiver(nMessageType, fnReceiver)
    end

    -- Register our own custom shell commands
    ExhibitVariant.tShellCommands = {
        --
        -- Custom command to do change the scale data for an entity
        --
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 4 then
                    return false, "Requires a visual entity ID and a 4 float value (scale min/max, longevity min/max)."
                end
                return self:SetExhibitAnimalVisualData(tArgs[1], tArgs[2], tArgs[3], tArgs[4])
            end,
            "&Set&Exhibit&Animal&VisualData {int32} {float} {float} {int32}",
            "Sets the visual data for a game entity id: color, pattern, morph.\n"
        ),
        --
        -- Custom command to do change the scale data for an entity
        --
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                api.debug.Trace(table.tostring(self.tEntities))
                return true, nil
            end,
            "&List&Exhibit&Animal&VisualData",
            "List all exhibit visual data available.\n"
        )

    }

    -- For entities we can't update (incomplete), we need an array to track them
    -- Entities in this list require the addition of the InstaceScaleData component.
    self.tNewEntities = {}

    -- For entities we need to keep track while ageing
    self.tEntities = {}

    -- Last timestamp we have updated scaling for this game
    self.fLastUpdate = 0

    -- lazy purpose tasking
    self.tTasks = {}
end

--
-- @brief Called after Init when the world is about to load
--
ExhibitVariant.Configure = function(self)
    self:Debug(self.DebugLevels.Extra, "ExhibitVariant:Configure()")
    -- Nothing really..
end


--
-- @brief Called to clean up the component on environment shutdown
--
ExhibitVariant.Shutdown = function(self)
    self:Debug(self.DebugLevels.Always, "ExhibitVariant:Shutdown()")
    self.tNewEntities = {}

    -- Remove custom receivers
    for nMessageType, fnReceiver in pairs(ExhibitVariant.tMessageRecievers) do
        api.messaging.UnregisterReceiver(nMessageType, fnReceiver)
    end
    ExhibitVariant.tMessageRecievers = nil

    -- Remove custom commands
    for _, oCommand in ipairs(ExhibitVariant.tShellCommands) do
        api.debug.UnregisterShellCommand(oCommand)
    end
    ExhibitVariant.tShellCommands = nil

    self.animalSizeData = nil
    self.animalAgesData = nil
    self.fLastUpdate    = nil    
end

ExhibitVariant.HandleMsgType_ExhibitAnimalAddedMessage = function(self, _tMessages)
    self:Debug(self.DebugLevels.Debug, "Exhibit Animal added")
    for _, tMessage in ipairs(_tMessages) do
        self:Debug(self.DebugLevels.Debug, "game entity ID", tMessage.nAnimalID)
        
        --
        --  NOTE NOTE NOTE 
        --
        --  nVisualEntity is not always available when spawning an animal in the park
        --  nVisualEntity is mostly available when loading a saved park
        --
        local tData = {
            nVisualEntity = self.tWorldAPIs.exhibits:GetAnimalVisual(tMessage.nAnimalID),
            nUID = self.tWorldAPIs.exhibits:ExhibitAnimalEntityIDToUID(tMessage.nAnimalID),
            nMorphInt = self.tWorldAPIs.exhibits:GetExhibitColourMorphInt(tMessage.nAnimalID),
            visualParams = {
            }
        }

        math.randomseed(tData.nUID)
        local nColour  = math.random(100)/100
        local nPattern = math.random(100)/100

        tData.visualParams = {
            GameEntity = tMessage.nAnimalID,
            VisualPatternValue = nPattern,
            VisualColourValue = nColour,
            IsAlbino = tData.nMorphInt == 0,
            IsErythristic = tData.nMorphInt == 1,
            IsLeucistic = tData.nMorphInt == 2,
            IsMelanistic = tData.nMorphInt == 3,
            IsXanthic = tData.nMorphInt == 4,
            IsPiebald = tData.nMorphInt == 5,
        }

        --self:ExhibitAnimalVisual_remove(tData.nVisualEntity)

        -- Create an entry in the table that will later be processed when the visual entityID is available.
        -- when spawning an animal (not loading a zoo) the visual entity is added later and might take one or two 
        -- frames to update.
        self.tNewEntities[tMessage.nAnimalID] = tData
        self.tEntities[tMessage.nAnimalID]    = nil
        self:Debug(self.DebugLevels.Extra, "Visual params", self.tNewEntities[tMessage.nAnimalID])
    end
end

ExhibitVariant.HandleMsgType_ExhibitAnimalRemovedMessage = function(self, _tMessages)
    self:Debug(self.DebugLevels.Debug, "Exhibit Animal Removed")
    for _, tMessage in ipairs(_tMessages) do
    self:Debug(self.DebugLevels.Debug, "Entity id", tMessage.nAnimalID)
        self.tNewEntities[tMessage.nAnimalID] = nil
        self.tEntities[tMessage.nAnimalID]    = nil
    end
end

--
-- @brief Called to add the component to an array of entity ID with parameters
-- @param _tArrayOfEntityIDAndParams (table) list of entities spawning with this 
--        component defined in their prefab
-- @Note  we are not managing the entity with this hook
--
ExhibitVariant.AddComponentsToEntities = function(self, _tArrayOfEntityIDAndParams)
    self:Debug(self.DebugLevels.Extra, "ExhibitVariant:AddComponentsToEntities()")

    for _, tEntry in ipairs(_tArrayOfEntityIDAndParams) do
        -- save the entity in the table with whatever initialization you need
        self:Debug(self.DebugLevels.Extra, "Component added to entity ID", tEntry.entityID)
        -- self.tNewEntities[tEntry.entityID] = {}
    end

    return true
end

--
-- @brief Called to remove the component from an array of entities
-- @param _tEntitiesArray (table) list of entities despawning that have this
--        component defined in their prefabs.
-- @Note  we are not managing the entity with this hook
--
ExhibitVariant.RemoveComponentFromEntities = function(self, _tEntitiesArray)
    self:Debug(self.DebugLevels.Extra, "ExhibitVariant:RemoveComponentFromEntities()")
    for _, entityID in ipairs(_tEntitiesArray) do
        -- self.tNewEntities[entityID] = nil
    end
end

--
-- @brief called when the world has been activated
--
ExhibitVariant.OnWorldActivation = function(self)
    self:Debug(self.DebugLevels.Extra, "ExhibitVariant:OnWorldActivation()")
end

--
-- @brief called when the world has been deactivated
--
ExhibitVariant.OnWorldDeactivation = function(self)
    self:Debug(self.DebugLevels.Extra, "ExhibitVariant:OnWorldDeactivation()")
end

--
-- @brief Can be used to Update the entity information
-- @param _nDeltaTime (number) time in milisecs since the last update, affected by
--        the current simulation speed.
-- @param _nUnscaledDeltaTime (number) time in milisecs since the last update.
--
ExhibitVariant.Advance = function(self, _nDeltaTime, _nUnscaledDeltaTime)
    --api.debug.Trace("ExhibitVariant:Advance() " .. global.tostring(_nDeltaTime) )

    -- Process the list of newly created entities to ensure scaling is enabled and a 
    -- default scale value is applied. Do this after updating all visuals to allow
    -- an intermediate frame between adding the component and scaling the animal
    for entityID, tData in pairs(self.tNewEntities) do
        if self:_CanUpdateAnimalVisuals(entityID, tData) then
            self.tEntities[entityID]    = tData
            self.tNewEntities[entityID] = nil
            self:ExhibitAnimalVisual_remove(tData.nVisualEntity)
            self:QueueTask(function()  
                self:ExhibitAnimalVisual_add(tData.nVisualEntity, entityID, tData.visualParams.VisualColourValue, tData.visualParams.VisualPatternValue, tData.nMorphInt)
            end)
        end
    end

    local task = self:UnqueueTask()
    if global.type(task) == 'function' then
        return task()
    end    
end

--
-- @brief Queues a task to avoid excesive hang up times
-- @param _fnTask (function) function to execute the next frame
-- @note  replace with an appropriate threated version
ExhibitVariant.QueueTask = function(self, _fnTask)
    self:Debug(self.DebugLevels.Extra, "ExhibitVariant:QueueTask()")
    table.insert(self.tTasks, _fnTask)
end

--
-- @brief Unqueues a task this happens automatically each frame.
--
ExhibitVariant.UnqueueTask = function(self)
    self:Debug(self.DebugLevels.Extra, "ExhibitVariant:UnqueueTask()")
    return table.remove(self.tTasks, 1)
end

ExhibitVariant.ExhibitAnimalVisual_remove = function(self, nEntityID)
    self:Debug(self.DebugLevels.Debug, "ExhibitVariant.ExhibitAnimalVisual_remove() for", nEntityID)
    local ExhibitAnimalVisual = api.componentmanager.LookupComponentManagerID("ExhibitAnimalVisual")
    local GameGPUInstanceData = api.componentmanager.LookupComponentManagerID("GameGPUInstanceData")
    api.entity.RemoveComponentsFromEntity(
        nEntityID, 
        {
            ExhibitAnimalVisual,
        },
        nil
    )
end

ExhibitVariant.ExhibitAnimalVisual_add = function(self, nEntityID, nGameEntity, nColour, nPattern, nMorphInt)
    self:Debug(self.DebugLevels.Debug, "ExhibitVariant.ExhibitAnimalVisual_add() for", nEntityID)
    local ExhibitAnimalVisual = api.componentmanager.LookupComponentManagerID("ExhibitAnimalVisual")
    local GameGPUInstanceData = api.componentmanager.LookupComponentManagerID("GameGPUInstanceData")

    global.api.entity.AddComponentsToEntity(
        nEntityID,
        {
            {
                id = ExhibitAnimalVisual,
                tParams = {
                    GameEntity = nGameEntity,
                    VisualPatternValue = nPattern,
                    VisualColourValue = nColour,
                    IsAlbino = nMorphInt == 0,
                    IsErythristic = nMorphInt == 1,
                    IsLeucistic = nMorphInt == 2,
                    IsMelanistic = nMorphInt == 3,
                    IsXanthic = nMorphInt == 4,
                    IsPiebald = nMorphInt == 5,
                }
            }
        },
        nil
    )
end


ExhibitVariant._CanUpdateAnimalVisuals = function(self, nEntityID, tData)
    self:Debug(self.DebugLevels.Extra, "ExhibitVariant._CanUpdateAnimalVisuals for game entity", nEntityID)
    if tData.nVisualEntity then return true end

    if self.tWorldAPIs.exhibits:EntityIsExhibitAnimal(nEntityID) == false then return false end

    local visualEntityID = self.tWorldAPIs.exhibits:GetAnimalVisual(nEntityID)
    if visualEntityID == nil then return false end
    self:Debug(self.DebugLevels.Extra, "Got visual entity id", nEntityID)
    self.tNewEntities[nEntityID].nVisualEntity = visualEntityID

    return false
end


--
-- @brief Does a transform Scale based on the current age of the exhibit animal entity ID
-- @note  Requires the self.tEntities data created for it
--
ExhibitVariant._GetAnimalAgeScaleData = function(self, nEntityID)
    self:Debug(self.DebugLevels.Debug, "ExhibitVariant._GetAnimalAgeScaleData for game entity", nEntityID)

    local tData = {
        minSize     = 1.0,
        maxSize     = 1.0,
        minLifeSpan = 1.0,
        maxLifeSpan = 1.0
    }

    --if self.tWorldAPIs.exhibits:EntityIsExhibitAnimal(nEntityID) == false then return tData end
    local animaldata  = self.tWorldAPIs.exhibits:GetExhibitAnimalData(nEntityID)
    local speciessize = self.animalSizeData[ animaldata['Species'] ] 
    local datasize    = speciessize[ animaldata['GenderNum'] + 1 ]
    local speciesage  = self.animalAgesData[ animaldata['Species'] ] 

    tData.minSize     = datasize[1]
    tData.maxSize     = datasize[2]
    tData.minLifeSpan = speciesage[1]
    tData.maxLifeSpan = speciesage[2]

    return tData
end

--//
--//
--// Component API
--//

--//
--// @brief: allows setting the animation speed for a specific entity
--// usage: api.ExhibitVariant:SetExhibitAnimalScale(nEntityID, 1.0) 
--//
ExhibitVariant.SetExhibitAnimalVisualData = function(self, nEntityID, fColourValue, fPatternValue, nMorphInt)
    self:Debug(self.DebugLevels.Debug, "ExhibitVariant.SetExhibitAnimalVisualData() for ", nEntityID)

    if self.tEntities[nEntityID] then

        self.tEntities[nEntityID].visualParams.VisualColourValue = fColourValue
        self.tEntities[nEntityID].visualParams.VisualPatternValue = fPatternValue
        self.tEntities[nEntityID].nMorphInt = nMorphInt

        local tData = self.tEntities[nEntityID]
        if self:_CanUpdateAnimalVisuals(nEntityID, tData) then
            self.tEntities[nEntityID]    = tData
            self:ExhibitAnimalVisual_remove(tData.nVisualEntity)
            self:QueueTask(function()  
                self:ExhibitAnimalVisual_add(tData.nVisualEntity, nEntityID, tData.visualParams.VisualColourValue, tData.visualParams.VisualPatternValue, tData.nMorphInt)
            end)
        end
    else
        self:Debug(self.DebugLevels.Error, "SetExhibitAnimalVisualData() entity not found", true)
    end
end