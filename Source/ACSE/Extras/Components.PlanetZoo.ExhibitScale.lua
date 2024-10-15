-----------------------------------------------------------------------
-- @file    Components.ExhibitScale.lua
-- @author  Inaki
--
-- @brief   Handles exhibit animal scale data from the Exhibits game fdb.
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

-- Define a tweakable to change the time scaling frequency
local s_ExhibitScaleTimeStep = api.debug.CreateDebugTweakable(
    api.debug.Tweakable_Float, 
    "ExhibitScale.ScaleTimeStep", 
    30,   -- Default value
    0,    -- Minimum value
    3000, -- Maximum value
    1     -- Step
)

--
-- @package Components
-- @class ExhibitScale
--
local ExhibitScale  = module(..., Object.subclass(Base))

-- Mod debug levels and default log filter
ExhibitScale.DebugLevels = {
    Always  = 0,
    Error   = 1,
    Warning = 2,
    Info    = 3,
    Debug   = 4,
    Extra   = 5,
}
ExhibitScale.DebugLevel = ExhibitScale.DebugLevels.Info

ExhibitScale.Debug = function(self, nLevel, ...)
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
-- api.exhibitscale:SetExhibitAnimalScaleData(nEntityID, 1.0, 1.0, 1.0, 1.0) 
-- 
-- If no more implementors are added, consider if this interface is actually necessary rather 
-- than just calling methods on the component manager directly.

-- API Needs to exist
ExhibitScale.tAPI = {
    'SetExhibitAnimalScaleData'
}

--
-- @brief Called to initalize the component on environment start
-- @param _tWorldAPIs (table) table of api methods available from the current environment.
--
ExhibitScale.Init = function(self, _tWorldAPIs)
    self:Debug(self.DebugLevels.Always, "ExhibitScale:Init()")

    -- Save a copy of the world API, we'll need them later
    self.tWorldAPIs = _tWorldAPIs

    -- Get the fdb exhibit animal info, size and age
    self.animalSizeData = self:_GetAllAnimalsExhibitSizeData()
    self.animalAgesData = self:_GetAllAnimalsExhibitAgesData()

    -- Register our own receivers
    ExhibitScale.tMessageRecievers = {
        -- Exhibit Animal Added gets called a new animal is spawned in an Exhibit, including births
        [api.messaging.MsgType_ExhibitAnimalAddedMessage] = function(_tMessages)
            self:HandleMsgType_ExhibitAnimalAddedMessage(_tMessages)
        end,
        -- Exhibit Animal Added gets called a new animal is despawned in an Exhibit, including deaths
        [api.messaging.MsgType_ExhibitAnimalRemovedMessage] = function(_tMessages)
            self:HandleMsgType_ExhibitAnimalRemovedMessage(_tMessages)
        end,
    }
    for nMessageType,fnReceiver in pairs(ExhibitScale.tMessageRecievers) do
        api.messaging.RegisterReceiver(nMessageType, fnReceiver)
    end

    -- Register our own custom shell commands
    ExhibitScale.tShellCommands = {
        --
        -- Custom command to do change the scale data for an entity
        --
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 5 then
                    return false, "Requires a visual entity ID and a 4 float value (scale min/max, longevity min/max)."
                end
                return self:SetExhibitAnimalScaleData(tArgs[1], tArgs[2], tArgs[3], tArgs[4], tArgs[5] )
            end,
            "&Set&Exhibit&Animal&ScaleData {int32} {float} {float} {float} {float}",
            "Sets the scale data for this exhibit animal game Entity ID.\n"
        ),
        --
        -- Custom command to do change the scale data for an entity
        --
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                api.debug.Trace(table.tostring(self.tEntities))
                return true, nil
            end,
            "&List&Exhibit&Animal&ScaleData",
            "List all exhibit scale data available.\n"
        )

    }

    -- For entities we can't update (incomplete), we need an array to track them
    -- Entities in this list require the addition of the InstaceScaleData component.
    self.tNewEntities = {}

    -- For entities we need to keep track while ageing
    self.tEntities = {}

    -- Last timestamp we have updated scaling for this game
    self.fLastUpdate = 0

end

--
-- @brief Called after Init when the world is about to load
--
ExhibitScale.Configure = function(self)
    self:Debug(self.DebugLevels.Extra, "ExhibitScale:Configure()")
end


--
-- @brief Called to clean up the component on environment shutdown
--
ExhibitScale.Shutdown = function(self)
    self:Debug(self.DebugLevels.Always, "ExhibitScale:Shutdown()")

    self.tNewEntities = {}

    -- Remove custom receivers
    for nMessageType, fnReceiver in pairs(ExhibitScale.tMessageRecievers) do
        api.messaging.UnregisterReceiver(nMessageType, fnReceiver)
    end
    ExhibitScale.tMessageRecievers = nil

    -- Remove custom commands
    for _, oCommand in ipairs(ExhibitScale.tShellCommands) do
        api.debug.UnregisterShellCommand(oCommand)
    end
    ExhibitScale.tShellCommands = nil

    self.animalSizeData = nil
    self.animalAgesData = nil
    self.fLastUpdate    = nil    
end


--
-- @brief Returns the content of ExhibitAnimalSizeData table in Exhibits database
--
ExhibitScale._GetAllAnimalsExhibitSizeData = function(self)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale._GetAllAnimalsExhibitSizeData()")
    local database = global.api.database
    local dbresult = nil
    local sizedata = {}

    local cPSInstance = database.GetPreparedStatementInstance("Exhibits", "GetAnimalSizeData")
    if cPSInstance ~= nil then
        database.BindComplete(cPSInstance)
        database.Step(cPSInstance)
        dbresult = database.GetAllResults(cPSInstance, false)
    end
    self:Debug(self.DebugLevels.Extra, "SQL animal size: ", dbresult)

    --[[ 
    Convert this:
    [1] = 
    {
        [1] = "BrazilianWanderingSpider",
        [2] = 0.85,
        [3] = 1.05,
        [4] = 0.9,
        [5] = 1.1,
        [6] = 0.25,
        [7] = 0.14,
        [8] = 0.25
    },
    into this:
    ["BrazilianWanderingSpider"] = {
        { -- Male
            0.85, 
            1.05
        },
        { -- Female
            0.9, 
            1.1
        }
    }
    ]]

    for _, _tData in ipairs(dbresult) do
        sizedata[ _tData[1] ] = {
            {
                _tData[2] * 100,
                _tData[3] * 100,
            },
            {
                _tData[4] * 100,
                _tData[5] * 100,
            }
        }
    end

    return sizedata
end


--
-- @brief Returns the content of ExhibitAnimalLogevityData table in Exhibits database
--
ExhibitScale._GetAllAnimalsExhibitAgesData = function(self)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale._GetAllAnimalsExhibitAgesData()")
    local database = global.api.database
    local dbresult = nil
    local agesdata = {}

    local cPSInstance = database.GetPreparedStatementInstance("Exhibits", "GetAnimallLongevityData")
    if cPSInstance ~= nil then
        database.BindComplete(cPSInstance)
        database.Step(cPSInstance)
        dbresult = database.GetAllResults(cPSInstance, false)
    end
    self:Debug(self.DebugLevels.Debug, "SQL animal age", dbresult)

    --[[ 
    Convert this:
    [1] = 
    {
        [1] = "BrazilianWanderingSpider",
        [2] = 1.617,
        [3] = 6.312,
        [4] = 0.25,
    },
    into this:
    ["BrazilianWanderingSpider"] = {
        1.617, 
        6.312
    }
    ]]

    for _, _tData in ipairs(dbresult) do
        agesdata[ _tData[1] ] = {
            _tData[2],
            _tData[3],
        }
    end

    return agesdata
end

ExhibitScale.HandleMsgType_ExhibitAnimalAddedMessage = function(self, _tMessages)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale.HandleMsgType_ExhibitAnimalAddedMessage exhibit animal added")
    for _, tMessage in ipairs(_tMessages) do
        self:Debug(self.DebugLevels.Extra, "Exhibit animal ID", tMessage.nAnimalID)
        
        -- Create an entry in the table that will later be processed when the visual entityID is available.
        -- when spawning an animal (not loading a zoo) the visual entity is added later and might take one or two 
        -- frames to update.
        self.tNewEntities[tMessage.nAnimalID] = self:_GetAnimalAgeScaleData(tMessage.nAnimalID)
        self.tEntities[tMessage.nAnimalID]    = nil
        self:Debug(self.DebugLevels.Extra, "Exhibit scaling information", self.tNewEntities[tMessage.nAnimalID])
    end
end

ExhibitScale.HandleMsgType_ExhibitAnimalRemovedMessage = function(self, _tMessages)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale.HandleMsgType_ExhibitAnimalAddedMessage exhibit animal removed")
    global.api.debug.Trace(table.tostring(_tMessages, nil,nil,nil,true))
    for _, tMessage in ipairs(_tMessages) do
        self:Debug(self.DebugLevels.Extra, "Exhibit animal ID", tMessage.nAnimalID)
        self.tNewEntities[tMessage.nAnimalID] = nil
        self.tEntities[tMessage.nAnimalID]    = nil
    end
end

--
-- @brief Called to add the component to an array of entity ID with parameters
-- @param _tArrayOfEntityIDAndParams (table) list of entities spawning with this 
--        component defined in their prefab
-- @Note  not used, we are not managing entities using this hook
ExhibitScale.AddComponentsToEntities = function(self, _tArrayOfEntityIDAndParams)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale:AddComponentsToEntities()")

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
--
-- @Note  not used, we are not managing entities using this hook
ExhibitScale.RemoveComponentFromEntities = function(self, _tEntitiesArray)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale:RemoveComponentFromEntities()")
    for _, entityID in ipairs(_tEntitiesArray) do
        self:Debug(self.DebugLevels.Extra, "Component removed from entity ID", entityID)
        -- self.tNewEntities[entityID] = nil
    end
end

--
-- @brief called when the world has been activated
--
ExhibitScale.OnWorldActivation = function(self)
    self:Debug(self.DebugLevels.Extra, "ExhibitScale:OnWorldActivation()")
end

--
-- @brief called when the world has been deactivated
--
ExhibitScale.OnWorldDeactivation = function(self)
    self:Debug(self.DebugLevels.Extra, "ExhibitScale:OnWorldDeactivation()")
end

--
-- @brief Can be used to Update the entity information
-- @param _nDeltaTime (number) time in milisecs since the last update, affected by
--        the current simulation speed.
-- @param _nUnscaledDeltaTime (number) time in milisecs since the last update.
--
ExhibitScale.Advance = function(self, _nDeltaTime, _nUnscaledDeltaTime)
    --api.debug.Trace("ExhibitScale:Advance() " .. global.tostring(_nDeltaTime) )

    -- time scale feature
    local ftime = api.time.GetTotalTime()
    local fTimeStep = s_ExhibitScaleTimeStep:GetValue()

    if ftime > (self.fLastUpdate + fTimeStep) then
        self:Debug(self.DebugLevels.Debug, "ExhibitScale:Advance()", self.fLastUpdate )
        self.fLastUpdate = ftime
        for entityID, tData in pairs(self.tEntities) do
            self:_UpdateAnimalAgeScale(entityID)
        end
    end

    -- Process the list of newly created entities to ensure scaling is enabled and a 
    -- default scale value is applied. Do this after updating all visuals to allow
    -- an intermediate frame between adding the component and scaling the animal
    for entityID, tData in pairs(self.tNewEntities) do
        if self:_TryUpdateAnimalScale(entityID) then
            -- Remove the entity from the table once it has been updated
            self.tNewEntities[entityID] = nil

            -- Add entity to the table for updating scale with age
            self.tEntities[entityID]    = self:_GetAnimalAgeScaleData(entityID)
        end
    end

end

ExhibitScale._TryUpdateAnimalScale = function(self, nEntityID, nScale)
    if self.tWorldAPIs.exhibits:EntityIsExhibitAnimal(nEntityID) == false then return false end

    local visualEntityID = self.tWorldAPIs.exhibits:GetAnimalVisual(nEntityID)
    if visualEntityID == nil then return false end

    local fScale = self:_CalculateAgeScale(nEntityID, self.tNewEntities[nEntityID])

    -- Add scaling component 
    api.entity.AddComponentsToEntity(
      visualEntityID,
      {{
          id = api.componentmanager.LookupComponentManagerID("InstanceScaleData"),
          tParams = { Scale = fScale }
      }},
      nil
    )
    self:Debug(self.DebugLevels.Debug, "ExhibitScale:_TryUpdateAnimalScale() for EntityID",nEntityID, "nScale", fScale )
    api.transform.SetScale(nEntityID, fScale)

    return true
end


--
-- @brief Does a transform Scale based on the current age of the exhibit animal entity ID
-- @note  Requires the self.tEntities data created for it
--
ExhibitScale._GetAnimalAgeScaleData = function(self, nEntityID)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale._GetAnimalAgeScaleData for Entity ID", nEntityID)
    local tData = {
        minSize     = 100.0,
        maxSize     = 100.0,
        minLifeSpan = 1.0,
        maxLifeSpan = 1.0
    }

    --if not self.tWorldAPIs.exhibits:EntityIsExhibitAnimal(nEntityID) then return tData end
    local animaldata  = self.tWorldAPIs.exhibits:GetExhibitAnimalData(nEntityID)
    local speciessize = self.animalSizeData[ animaldata['Species'] ] 
    if speciessize then 
        local datasize    = speciessize[ animaldata['GenderNum'] + 1 ]
        local speciesage  = self.animalAgesData[ animaldata['Species'] ] 

        tData.minSize     = datasize[1]
        tData.maxSize     = datasize[2]
        tData.minLifeSpan = speciesage[1]
        tData.maxLifeSpan = speciesage[2]
    end
    self:Debug(self.DebugLevels.Debug, "AgeScaleData for EntityID", nEntityID, "Species", animaldata['Species'] )
    self:Debug(self.DebugLevels.Extra, "Scaling data", tData)
    return tData
end


--
-- @brief Does a transform Scale based on the current age of the exhibit animal entity ID
-- @note  Requires the self.tEntities data created for it
--
ExhibitScale._UpdateAnimalAgeScale = function(self, nEntityID)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale._UpdateAnimalAgeScale()")
    if self.tWorldAPIs.exhibits:EntityIsExhibitAnimal(nEntityID) then
        local fScale = self:_CalculateAgeScale(nEntityID, self.tEntities[nEntityID])
        self:Debug(self.DebugLevels.Extra, "ExhibitScale._UpdateAnimalAgeScale(", nEntityID, ") = ", fScale)
        api.transform.SetScale(nEntityID, fScale)
    end
end

--
-- @brief Calculates the scale factor to achieve Max Size at Min Life Span
-- @return float   scale factor
-- @note  Requires the self.tEntities data created for it
-- 
ExhibitScale._CalculateAgeScale = function(self, nEntityID, tData)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale._CalculateAgeScale()")
    if tData.maxSize == tData.minSize then return tData.maxSize/100.0 end
    local ageProps = self.tWorldAPIs.exhibits:GetExhibitAnimalAgeProps(nEntityID)
    local rate = ageProps.nCurrent * tData.maxLifeSpan / tData.minLifeSpan
    local fScalefactor = math.max(0.0, math.min(1.0, rate)) 
    return (tData.minSize + (tData.maxSize - tData.minSize) * fScalefactor) / 100.0
end

--//
--//
--// Component API
--//

--//
--// @brief: allows setting the animation speed for a specific entity
--// usage: api.ExhibitScale:SetExhibitAnimalScale(nEntityID, 1.0) 
--//
ExhibitScale.SetExhibitAnimalScaleData = function(self, nEntityID, fMinSize, fMaxSize, fMinLifeSpan, fMaxLifeSpan)
    self:Debug(self.DebugLevels.Debug, "ExhibitScale.SetExhibitAnimalScaleData()")

    if self.tEntities[nEntityID] then
        self.tEntities[nEntityID] = {
            minSize     = fMinSize,
            maxSize     = fMaxSize,
            minLifeSpan = fMinLifeSpan,
            maxLifeSpan = fMaxLifeSpan
        }
    end
end