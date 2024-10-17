-----------------------------------------------------------------------
-- @file    Components.PlanetZoo.ExhibitManis.lua
-- @author  Inaki
--
-- @brief   Creates a game component.
--
-- @see     https://github.com/OpenNaja/ACSE
-- @version 1.0
-- @require ACSE >= 0.6 to work.
--
-- Note: This file has been created automatically with CobraModdingTool
-----------------------------------------------------------------------

--[[

Pose Definition {
    PoseName      = 'Brazilian_Wandering_Spider_Pose_01',
    Species       = 'BrazilianWanderingSpider',
    Anim1         = 'Brazilian_Wandering_Spider_Pose_01_BreathingLoop',
    Anim2         = 'Brazilian_Wandering_Spider_Pose_01_Flourish'
    ..
    Anim6         = nil
}

Animation definition {
    Name          = 'Lesser_Antillean_Iguana_Pose_01_BreathingLoop,
    MinLoopCount  = 2, 
    MaxLoopCount  = 3,
    CanRepeat     = true,
    PlayFrequency = 1,
    IsAToB        = false
}

Based on the pose, there is a weighted selection of the animation usingPlayFrequency. If the 
animation can repeat then a number of actions are queued based on the min/map loop count.

TODO: If there is only one animation defined it is set as a single looped animation.

Each entity will need a queue for the next action that will be checked. If the current entity popthrough
is 1.0 the next animation will be poped from the queue and played. If the queue is empty, a new animation
selection will happend.

To speed things up, we are only saving the current pose animations once on the entity and not all the 
options (the pose is expensive to calculate and doesn't change once the animal has been spawned.)

So, the component should only specify (optionally) a list of animations to be used during the queue
generation. This animations will be overriden by the pose definition. Playback rate allows for adjusting
animation speeds when the animal rig is scaled.

ExhibitManis = {
    Anim1 = nil,
    Anim2 = nil,
    Anim3 = nil,
    Anim4 = nil,
    Anim5 = nil,
    Anim6 = nil,
    MinRandomPlaybackRate  = 1.0,
    MaxnRandomPlaybackRate = 1.0,
}
]]

local global      = _G

local api         = global.api
local require     = global.require
local type        = global.type
local pairs       = global.pairs
local ipairs      = global.ipairs
local math        = global.math
local string      = global.string
local table       = require("Common.tableplus")
local Object      = require("Common.object")
local Base        = require("LuaComponentManagerBase")

--
-- @package Components
-- @class ExhibitManis
--
local ExhibitManis     = module(..., Object.subclass(Base))

-- Mod debug levels and default log filter
ExhibitManis.DebugLevels = {
    Always  = 0,
    Error   = 1,
    Warning = 2,
    Info    = 3,
    Debug   = 4,
    Extra   = 5,
}

ExhibitManis.DebugLevel = ExhibitManis.DebugLevels.Info

ExhibitManis.Debug = function(self, nLevel, ...)
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
-- - api.exhibitmanis:ApiExample1(nEntityID) 
-- 
-- If no more implementors are added, consider if this interface is actually necessary rather 
-- than just calling methods on the component manager directly.

-- .API Needs to exist
ExhibitManis.tAPI = {
    "ApiExample1", 
}

--
-- @brief Called to initalize the component on environment start
-- @param _tWorldAPIs (table) table of api methods available from the current environment.
--
ExhibitManis.Init = function(self, _tWorldAPIs)
    self:Debug(self.DebugLevels.Always, "ExhibitManis:Init()")

    -- api.debug.Trace(table.tostring(_tWorldAPIs, nil, nil, nil, true))
    self.tEntities = {}

    -- Register our own custom shell commands
    ExhibitManis.tShellCommands = {

        --
        -- Custom example command
        --
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 1 then
                    return false, "Requires an entityID."
                end
                api.debug.WriteLine(1, table.tostring(self.tEntities[ tArgs[1] ], nil, nil, nil, true))
                return true, nil
            end,
            "&ExhibitManis&Info {int32}",
            "Display exhibit manis information about this Entity ID.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                api.debug.WriteLine(1, table.tostring(self.tEntities, nil, nil, nil, true))
                return true, nil
            end,
            "&ExhibitManis&List",
            "Display a list of managed entities.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 1 then
                    return false, "Requires an entity ID."
                end
                self:GenerateQueue(tArgs[1])
                return true, "Queue regenerated for " .. table.tostring(tArgs[1])
            end,
            "&ExhibitManis&Regenerate&Queue {int32}",
            "Create a new animation queue for this visual entity id.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                api.debug.WriteLine(1, table.tostring(self.tPoseData, nil, nil, nil, true))
                return true, nil
            end,
            "&ExhibitManis&Poses",
            "Display a list of managed poses.\n"
        ),


    }

    -- Find exhibit species using manis by their component usage
    local tExhibitManisSpecies = self:FindExhibitSpeciesUsingManis()
    self:Debug(self.DebugLevels.Debug, "Species using Manis",  tExhibitManisSpecies)

    -- Cache fdb animation data, animations are not tied to an specific species
    self.tAnimationData = self:GetFDBAnimationData()

    -- Cache fdb pose data, filter by species
    self.tPoseData = self:GetFDBPoseData(tExhibitManisSpecies)
    self:Debug(self.DebugLevels.Debug, "Filtered Pose Data",  self.tPoseData)

    -- cache fdb presentation data, filter by species
    self.tPresentationData = self:GetFDBPresentationData(tExhibitManisSpecies)
    self:Debug(self.DebugLevels.Debug, "Filtered Presentation Data",  self.tPresentationData)

    -- Attach our prepared statement to the runtime database
    if not api.database.BindPreparedStatementCollection("Exhibits", "ExhibitManis") then
        self:Debug(self.DebugLevels.Always, "- Error binding ExhibitManis prepared statement collection.")
    end

    -- Clean ExhibitManis animation data
    self:CleanFDBPoseAnimations()
end

--
-- Returns a table of species names using ExhibitManis Component 
-- TODO: ACSE ERROR UNGROUPING CUSTOM COMPONENTS, need to find StandaloneScenerySerialisation first.
--
ExhibitManis.FindExhibitSpeciesUsingManis = function(self)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.FindExhibitSpeciesUsingManis()")
    local tSpecies = {}

    local oPreparedStatement = api.database.GetPreparedStatementInstance("Exhibits", 'GetAnimalPrefabNames')
    if oPreparedStatement == nil then return {} end
    api.database.BindComplete(oPreparedStatement)
    api.database.Step(oPreparedStatement)
    local tResult = api.database.GetAllResults(oPreparedStatement, false)

    for _, tSpeciesData in ipairs(tResult) do
        -- Skip female prefab, if male has manis, female should have too.
        local sSpeciesName    = tSpeciesData[1]
        local sMalePrefabName = tSpeciesData[3]
        local tPrefab = api.entity.FindPrefab(sMalePrefabName)
        --api.debug.WriteLine(1, table.tostring(sMalePrefabName, nil, nil, nil, true))
        --api.debug.Trace("ExhibitManisSpecies " .. table.tostring(sSpeciesName) .. " Prefab " ..  table.tostring(tPrefab, nil, nil, nil, true))

        if tPrefab and tPrefab.Components and tPrefab.Components.StandaloneScenerySerialisation and tPrefab.Components.StandaloneScenerySerialisation.ExhibitManis then
            --api.debug.WriteLine(1, "Species  " .. table.tostring(sSpeciesName) .. " using exhibit manis with " .. table.tostring(tSpeciesData))
            table.insert(tSpecies, tSpeciesData[1])
        else
            self:Debug(self.DebugLevels.Error, "Species missing prefab",  sMalePrefabName)
        end
    end

    return tSpecies
end

--
-- @brief Sets animations for an indidivual pose data in the fdb, used to clear and restore manis information
--
ExhibitManis.SetFDBPoseData = function(self, sPoseName, sAnim1, sAnim2, sAnim3, sAnim4, sAnim5, sAnim6)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.SetFDBPoseData() Saving new FDB  data for pose: ",  sPoseName)

    api.database.SetReadOnly("Exhibits", false)
    local oPreparedStatement = api.database.GetPreparedStatementInstance("Exhibits", "UpdatePoseDataForSpecies")
    if oPreparedStatement == nil then return {} end
    api.database.BindParameter(oPreparedStatement, 1, sAnim1 or "NULL") 
    api.database.BindParameter(oPreparedStatement, 2, sAnim2 or "NULL") 
    api.database.BindParameter(oPreparedStatement, 3, sAnim3 or "NULL") 
    api.database.BindParameter(oPreparedStatement, 4, sAnim4 or "NULL") 
    api.database.BindParameter(oPreparedStatement, 5, sAnim5 or "NULL") 
    api.database.BindParameter(oPreparedStatement, 6, sAnim5 or "NULL") 
    api.database.BindParameter(oPreparedStatement, 7, sPoseName) 
    api.database.BindComplete(oPreparedStatement)
    api.database.Step(oPreparedStatement)
    local tResult = api.database.GetAllResults(oPreparedStatement, false)
    api.database.SetReadOnly("Exhibits", true)
end

--
-- @brief Retrieve animation information from fdb
--
ExhibitManis.GetFDBAnimationData = function(self)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.GetFDBAnimationData()")
    local oPreparedStatement = api.database.GetPreparedStatementInstance("Exhibits", 'GetExhibitBaniData')
    if oPreparedStatement == nil then return {} end
    api.database.BindComplete(oPreparedStatement)
    api.database.Step(oPreparedStatement)
    local tResult = api.database.GetAllResults(oPreparedStatement, false)

    local tAnimations = {}
    --api.debug.WriteLine(1, table.tostring(tResult, nil, nil, nil, true))
    for _, tSpeciesData in ipairs(tResult) do
        tAnimations[ tSpeciesData[1] ] = { -- Animation name
            minLoop = tSpeciesData[2],
            maxLoop = tSpeciesData[3],
            canLoop = tSpeciesData[4],
            weight  = tSpeciesData[5],
            AToB    = tSpeciesData[6],
        }
    end
    return tAnimations
end

--
-- @brief Retrieve presentation pose names from fdb, allow filter to a selected list of species
--
ExhibitManis.GetFDBPresentationData = function(self, tSpecies)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.GetFDBAnimationData()")
    local oPreparedStatement = api.database.GetPreparedStatementInstance("Exhibits", 'GetAnimalPresentationData')
    if oPreparedStatement == nil then return {} end
    api.database.BindComplete(oPreparedStatement)
    api.database.Step(oPreparedStatement)
    local tResult = api.database.GetAllResults(oPreparedStatement, false)

    local tPoses = {}
    --api.debug.WriteLine(1, table.tostring(tResult, nil, nil, nil, true))
    for _, tSpeciesData in ipairs(tResult) do
        tPoses[ tSpeciesData[1] ] = {    -- Species Data
            sPoseName = tSpeciesData[4], -- Animation Name
        }
    end

    -- tPoses has all poses now, should we filter?
    local tFilteredPoses = {}
    if tSpecies then
        for _, key in ipairs(tSpecies) do
            tFilteredPoses[key] = tPoses[key]
        end
    else 
        tFilteredPoses = tPoses
    end

    return tFilteredPoses
end


--
-- Remove animation data from fdb for exhibitmanis poses
--
ExhibitManis.CleanFDBPoseAnimations = function(self)
    self:Debug(self.DebugLevels.Always, "ExhibitManis.CleanFDBPoseAnimations()")
    for sSpecies, tPoses in pairs(self.tPoseData) do
        self:Debug(self.DebugLevels.Debug, 'Species ', sSpecies)
        for sPoseName, tPoseData in pairs(tPoses) do
            self:Debug(self.DebugLevels.Debug, 'Pose ', sPoseName)
            self:SetFDBPoseData(sPoseName, nil, nil, nil, nil, nil, nil)
        end
    end
end

--
-- Restore animation data from fdb for exhibitmanis poses
--
ExhibitManis.RestoreFDBPoseAnimations = function(self)
    self:Debug(self.DebugLevels.Always, "ExhibitManis.RestoreFDBPoseAnimations()")
    for sSpecies, tPoses in pairs(self.tPoseData) do
        self:Debug(self.DebugLevels.Debug, 'Species ', sSpecies)
        for sPoseName, tPoseData in pairs(tPoses) do
            self:Debug(self.DebugLevels.Debug, 'Pose ', sPoseName)
            self:SetFDBPoseData(sPoseName, tPoseData.Anim1, tPoseData.Anim2, tPoseData.Anim3, tPoseData.Anim4, tPoseData.Anim5, tPoseData.Anim6)
        end
    end
end

--
-- @brief Retrieve restpoint pose data from fdb 
--
ExhibitManis.GetFDBPoseData = function(self, tSpecies)
    local oPreparedStatement = api.database.GetPreparedStatementInstance("Exhibits", 'GetAnimalPoseData')
    if oPreparedStatement == nil then return {} end
    api.database.BindComplete(oPreparedStatement)
    api.database.Step(oPreparedStatement)
    local tResult = api.database.GetAllResults(oPreparedStatement, false)
    self:Debug(self.DebugLevels.Extra, 'GetFDBPoseData Result', tResult)

    local tPoseData = {}
    for _, tSpeciesData in ipairs(tResult) do

        local sSpeciesName = tSpeciesData[1]
        if not tPoseData[sSpeciesName] then
            tPoseData[sSpeciesName] = {}
        end

        local sPoseName = tSpeciesData[2]
        
        tPoseData[sSpeciesName][sPoseName] = {
            Anim1 = tSpeciesData[3] or nil,
            Anim2 = tSpeciesData[4] or nil,
            Anim3 = tSpeciesData[5] or nil,
            Anim4 = tSpeciesData[6] or nil,
            Anim5 = tSpeciesData[7] or nil,
            Anim6 = tSpeciesData[8] or nil
        }
    end
    self:Debug(self.DebugLevels.Extra, 'GetFDBPoseData organized Result', tPoseData)
    -- tPoseData has all poses now, should we filter
    local tFilteredPoses = {}
    if tSpecies then
        for _, key in ipairs(tSpecies) do
            api.debug.Trace('Key ' .. table.tostring(key, nil, nil, nil, true))
            tFilteredPoses[key] = tPoseData[key]
        end
    else 
        tFilteredPoses = tPoseData
    end
    return tFilteredPoses
end



--
-- @brief Called after Init when the world is about to load
--
ExhibitManis.Configure = function(self)
    self:Debug(self.DebugLevels.Debug, 'ExhibitManis:Configure()')
    -- Nothing really..
end


--
-- @brief Called to clean up the component on environment shutdown
--
ExhibitManis.Shutdown = function(self)
    self:Debug(self.DebugLevels.Always, "ExhibitManis:Shutdown()")

    -- Clean up our tracking table
    self.tEntities = {}

    -- Remove custom commands
    for i, oCommand in global.ipairs(ExhibitManis.tShellCommands) do
        api.debug.UnregisterShellCommand(oCommand)
    end

    ExhibitManis.tShellCommands = {}

    -- Restore the animation data for the next run
    self:RestoreFDBPoseAnimations()
end

ExhibitManis.FindEntityPoseAnims = function(self, nAnimalVisualEntityID)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.FindEntityPoseAnims() for ", nAnimalVisualEntityID)

    local path = {}

    local tWorldAPIs   = api.world.GetWorldAPIs()
    local exhibitsAPI  = tWorldAPIs.exhibits
    local animationAPI = tWorldAPIs.animation

    local nParentID    = api.transform.GetParent(nAnimalVisualEntityID)
    self:Debug(self.DebugLevels.Extra, "nParentID: ", nParentID)

    local nEntityID   = exhibitsAPI:GetRestingPointOfAnimal( nParentID )
    self:Debug(self.DebugLevels.Extra, "RestingID: ", nEntityID)

    if nEntityID == nil then 
        self:Debug(self.DebugLevels.Info, "exhibit animal spawned without Resting ID: using presentation data for", nEntityID)
        if self.tEntities[nAnimalVisualEntityID].SpeciesName then 
            return {self.tPresentationData[ self.tEntities[nAnimalVisualEntityID].SpeciesName ].sPoseName }
        else
            self:Debug(self.DebugLevels.Error, "Missing species in ExhibitManis component, no pose selected, using prefab defined anims")
            return {}
        end
    end

    local sName = api.entity.GetEntityName( nParentID )
    self:Debug(self.DebugLevels.Extra, "Parent entity name: ", sName)
    local sDebugName = api.entity.GetEntityDebugName( nParentID )
    self:Debug(self.DebugLevels.Extra, "Parent debug name: ", sDebugName)

    local sSpeciesName = exhibitsAPI:GetAnimalSpecies(nParentID)
    self:Debug(self.DebugLevels.Debug, "Exhibit species: ", sSpeciesName)

    -- If no restindID = presenter pose
    -- if restingID then
    -- [00000039.063] nParentID  : 17534
    -- [00000039.064] RestingID  : 17511
    -- [00000039.066] sName  : "RF_Spiders_Arboreal_Base_Resting_Point_23"
    -- [00000039.070] sName  : "_Prefab RF_Spiders_Arboreal_Base 13633"
    -- [00000039.072] sName  : "_Prefab EX_Exhibit_Game 13527"
    -- [00000039.075] sName  : "_Prefab StaticEntityCullingCell 13626"
    -- [00000039.077] sName  : "_Prefab StaticEntityCullingCell 13625"
    -- [00000039.079] sName  : "_Prefab StaticEntityCullingCell 13624"
    -- [00000039.082] sName  : "_Prefab StaticEntityCullingCell 13623"
    -- [00000039.084] sName  : "StaticEntityCullingManager"


    local startswith = function(str, start)
        return string.sub(str, 1, #start) == start
    end

    while nEntityID ~= nil do
        local sName = api.entity.GetEntityName( nEntityID )
        --api.debug.WriteLine(1, "sName  : " .. table.tostring(sName))
        --api.debug.Trace("sName  : " .. table.tostring(sName))

        if not startswith(sName, "_Prefab ") then
            table.insert(path, 1, sName)
        else
            local words = {} 
            for word in sName:gmatch("%S+") do table.insert(words, word) end
            local sPrefabName = words[2]
            --api.debug.WriteLine(1, "Found prefab " .. table.tostring(sPrefabName))

            local tPrefab = api.entity.FindPrefab(sPrefabName)
            for _, sChildrenName in ipairs(path) do
                tPrefab = tPrefab['Children'][sChildrenName]
            end

            -- Found the resting point definition, now to find valid poses for this species
            if tPrefab['Components'] and tPrefab['Components']['ExhibitRestingPoint'] then

                local tInput = tPrefab['Components']['ExhibitRestingPoint']['ValidPosePrefabs']
                local tOut   = {}
                for _, k in ipairs(tInput) do
                    if self.tPoseData[sSpeciesName][k] then
                        table.insert(tOut, k)
                    end
                end
                return tOut
                -- return tPrefab['Components']['ExhibitRestingPoint']['ValidPosePrefabs'] or {}
            end

            return {}
        end
        nEntityID = api.transform.GetParent(nEntityID)
    end
    return {}
end

--
-- Return the species name based on the visual entity id,
-- Currently unused due to talking point not being full animals
--
ExhibitManis.GetVisualSpeciesName = function(self, nEntityID)
    local nParent      = api.transform.GetParent(nEntityID)
    local tWorldAPIs   = api.world.GetWorldAPIs()
    local exhibitsAPI  = tWorldAPIs.exhibits
    local sSpeciesName = exhibitsAPI:GetAnimalSpecies(nParent)
    return sSpeciesName
end

--
-- @brief Called to add the component to an array of entity ID with parameters
-- @param _tArrayOfEntityIDAndParams (table) list of entities spawning with this 
--        component defined in their prefab
--
ExhibitManis.AddComponentsToEntities = function(self, _tArrayOfEntityIDAndParams)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.AddComponentsToEntities()")

    for _, tEntry in ipairs(_tArrayOfEntityIDAndParams) do
        -- The game validates the prefab data using specdefs, but because this is a 
        -- custom component without a specdef, we need to validate the data we receive
        -- from the prefab. Validate that tEntry.tParams has all your initialization 
        -- requirements here and add the missing elements with default values
        -- api.debug.Trace("tParams " .. table.tostring(tEntry))

        -- save the entity in the table with whatever initialization you need
        self:Debug(self.DebugLevels.Extra, "Adding entity ID:", tEntry.entityID)

        -- Setup entity information
        self.tEntities[tEntry.entityID] = {
            Anim1                  = nil,
            Anim2                  = nil,
            Anim3                  = nil,
            Anim4                  = nil,
            Anim5                  = nil,
            Anim6                  = nil,
            MinRandomPlaybackRate  = 1.0,
            MaxRandomPlaybackRate  = 1.0,
            tQueue                 = { },
            sCurrentAnimation      = nil
        }
        table.mergeinplace(self.tEntities[tEntry.entityID], tEntry.tParams)
        self:Debug(self.DebugLevels.Extra, "Merged params:", self.tEntities[tEntry.entityID])

        -- Override params from current pose if any. We get a list of valid poses.. just pick a random one from that list
        local tPoses = self:FindEntityPoseAnims(tEntry.entityID)
        self:Debug(self.DebugLevels.Extra, "Valid poses:", tPoses)
        local idx, sPoseName = table.random(tPoses)

        self:Debug(self.DebugLevels.Extra, "Selected pose:", sPoseName)

        -- Set entity animation from the POSE
        if sPoseName then

            local sSpeciesName = tEntry.tParams.SpeciesName --self:GetVisualSpeciesName(tEntry.entityID)
            if self.tPoseData[sSpeciesName][sPoseName] then

                local tPose = self.tPoseData[sSpeciesName][sPoseName]
                self:Debug(self.DebugLevels.Extra, "Overide prefab data with:", tPose)
                self.tEntities[tEntry.entityID].Anim1 = tPose.Anim1 or nil
                self.tEntities[tEntry.entityID].Anim2 = tPose.Anim2 or nil
                self.tEntities[tEntry.entityID].Anim3 = tPose.Anim3 or nil
                self.tEntities[tEntry.entityID].Anim4 = tPose.Anim4 or nil
                self.tEntities[tEntry.entityID].Anim5 = tPose.Anim5 or nil
                self.tEntities[tEntry.entityID].Anim6 = tPose.Anim6 or nil
            end
        end
        self:Debug(self.DebugLevels.Extra, "Final params based on pose: ", self.tEntities[tEntry.entityID])

        -- Generate animation queue
        self:GenerateQueue(tEntry.entityID)
        self:Debug(self.DebugLevels.Extra, "New entity queue: ", self.tEntities[tEntry.entityID].tQueue)

        -- Pop first animation
        if table.count(self.tEntities[tEntry.entityID].tQueue) then
            self.tEntities[tEntry.entityID].sCurrentAnimation = table.remove(self.tEntities[tEntry.entityID].tQueue, 1)
        end

    end
    return true
end

--
-- @brief Called to remove the component from an array of entities
-- @param _tEntitiesArray (table) list of entities despawning that have this
--        component defined in their prefabs.
--
ExhibitManis.RemoveComponentFromEntities = function(self, _tEntitiesArray)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.RemoveComponentFromEntities()")
    for _, entityID in global.ipairs(_tEntitiesArray) do
        self:Debug(self.DebugLevels.Extra, "Removing ", entityID)
        self.tEntities[entityID] = nil
    end
end

--
-- Try forcing the start of the last de-queued animation
--
ExhibitManis.StartAnimation = function(self, nEntityID)
  self:Debug(self.DebugLevels.Extra, "ExhibitManis.StartAnimation()", self.tEntities[nEntityID].sCurrentAnimation, "for", nEntityID)
  if not self.tEntities[nEntityID].sCurrentAnimation then return end

  local tWorldAPIs   = api.world.GetWorldAPIs()
  local exhibitsAPI  = tWorldAPIs.exhibits
  local animationAPI = tWorldAPIs.animation

  local bLoop        = false
  local bReverse     = false
  local PlayBackRate = math.random(
    math.floor(self.tEntities[nEntityID].MinRandomPlaybackRate * 100),
    math.ceil(self.tEntities[nEntityID].MinRandomPlaybackRate * 100)
  ) / 100

  self:Debug(self.DebugLevels.Extra, "Playback Rate", PlayBackRate)
  animationAPI:PlayAnimation(nEntityID, self.tEntities[nEntityID].sCurrentAnimation, bLoop, 1.0, 0.001, bReverse)
end

--
-- Populate the entity tQueue table with a few animations based on weight and repetition
--
ExhibitManis.GenerateQueue = function(self, nEntityID)
  self:Debug(self.DebugLevels.Extra, "ExhibitManis.GenerateQueue() for ", nEntityID)

  -- Clean up current queue
  self.tEntities[nEntityID].tQueue = {}

  local tQueuePossibilities = {}

  self:Debug(self.DebugLevels.Extra, "Entity Data", self.tEntities[nEntityID])

  if self.tEntities[nEntityID].Anim1 then
    --api.debug.Trace("anim1")
    --table.insert(self.tEntities[nEntityID].tQueue, self.tEntities[nEntityID].Anim1)
    tQueuePossibilities[self.tEntities[nEntityID].Anim1] = self.tAnimationData[ self.tEntities[nEntityID].Anim1 ]
  end
  if self.tEntities[nEntityID].Anim2 then
    --api.debug.Trace("anim2")
    --table.insert(self.tEntities[nEntityID].tQueue, self.tEntities[nEntityID].Anim2)
    tQueuePossibilities[self.tEntities[nEntityID].Anim2] = self.tAnimationData[ self.tEntities[nEntityID].Anim2 ]
  end
  if self.tEntities[nEntityID].Anim3 then
    --api.debug.Trace("anim3")
    --table.insert(self.tEntities[nEntityID].tQueue, self.tEntities[nEntityID].Anim3)
    tQueuePossibilities[self.tEntities[nEntityID].Anim3] = self.tAnimationData[ self.tEntities[nEntityID].Anim3 ]
  end
  if self.tEntities[nEntityID].Anim4 then
    --api.debug.Trace("anim4")
    --table.insert(self.tEntities[nEntityID].tQueue, self.tEntities[nEntityID].Anim4)
    tQueuePossibilities[self.tEntities[nEntityID].Anim4] = self.tAnimationData[ self.tEntities[nEntityID].Anim4 ]
  end
  if self.tEntities[nEntityID].Anim5 then
    --api.debug.Trace("anim5")
    --table.insert(self.tEntities[nEntityID].tQueue, self.tEntities[nEntityID].Anim5)
    tQueuePossibilities[self.tEntities[nEntityID].Anim5] = self.tAnimationData[ self.tEntities[nEntityID].Anim5 ]
  end
  if self.tEntities[nEntityID].Anim6 then
    --api.debug.Trace("anim6")
    --table.insert(self.tEntities[nEntityID].tQueue, self.tEntities[nEntityID].Anim6)
    tQueuePossibilities[self.tEntities[nEntityID].Anim6] = self.tAnimationData[ self.tEntities[nEntityID].Anim6 ]
  end
 
  self:Debug(self.DebugLevels.Extra, "Current animation poll", tQueuePossibilities)

  --[[ This introduces weighted randomization but removes the possibility of chained animations
  while table.count(tQueuePossibilities) > 0 do
    local idx, tAnimData = table.weightedRandom(tQueuePossibilities)
    tQueuePossibilities[idx] = nil -- Remove this entry 
    
    if tAnimData.canLoop then
        local count = math.random( math.floor(tAnimData.minLoop),  math.ceil(tAnimData.maxLoop))
        --api.debug.Trace("can loop times: " .. table.tostring(count))
        for i = 1, count do
            table.insert(self.tEntities[nEntityID].tQueue, idx)
        end
    else 
        --api.debug.Trace("Can't loop")
        table.insert(self.tEntities[nEntityID].tQueue, idx)
    end
  end
  ]]

  -- Make a chained animation 
  for i=1, 6 do
    local key = 'Anim' .. global.tostring(i)
    if self.tEntities[nEntityID][key] then
        local tAnimData = self.tAnimationData[ self.tEntities[nEntityID][key] ]
        if tAnimData.canLoop then
            local count = math.random( math.floor(tAnimData.minLoop),  math.ceil(tAnimData.maxLoop))
            for i = 1, count do
                table.insert(self.tEntities[nEntityID].tQueue, self.tEntities[nEntityID][key])
            end
        else 
            --api.debug.Trace("Can't loop")
            table.insert(self.tEntities[nEntityID].tQueue, self.tEntities[nEntityID][key])
        end
    end
  end

end

--
-- @brief called when the world has been activated
--
ExhibitManis.OnWorldActivation = function(self)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.OnWorldActivation()")
end

--
-- @brief called when the world has been deactivated
--
ExhibitManis.OnWorldDeactivation = function(self)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.OnWorldDeactivation()")
end

--
-- @brief Can be used to Update the entity information
-- @param _nDeltaTime (number) time in milisecs since the last update, affected by
--        the current simulation speed.
-- @param _nUnscaledDeltaTime (number) time in milisecs since the last update.
--
ExhibitManis.Advance = function(self, _nDeltaTime, _nUnscaledDeltaTime)
    --api.debug.Trace("ExhibitManis:Advance() " .. global.tostring(_nDeltaTime) )
    local tWorldAPIs   = api.world.GetWorldAPIs()
    local animationAPI = tWorldAPIs.animation

    -- Maintain animation queue
    for entityID, tData in pairs(self.tEntities) do
        if table.count(tData.tQueue) == 0 then
            self:GenerateQueue(entityID)
            -- Generate new animation queue
        end
        
        if tWorldAPIs.animation:GetPropThrough(entityID) == 0.0 then
            -- animation stalled, kick it again using tData.sCurrentAnimation
            self:StartAnimation(entityID)
        end

        if tWorldAPIs.animation:GetPropThrough(entityID) == 1.0 then
            -- Current animation is finished
            self.tEntities[entityID].sCurrentAnimation = nil

            --if table.count(self.tEntities[nEntityID].tQueue) == 0 then
            --    -- regenerate queue if empty
            --    self:GenerateQueue(entityID)
            --else
            if table.count(tData.tQueue) then
                -- Pop next animation from the queue
                self:Debug(self.DebugLevels.Extra, "ExhibitManis.Advance Animation finished, pop next for ", entityID)
                self.tEntities[entityID].sCurrentAnimation = table.remove(tData.tQueue, 1)
                self:StartAnimation(entityID)
            end
        end
    end

end

--
-- @brief Allows setting the animation speed for a specific entity
-- @param nEntityID (number) game entity ID number
-- @usage global.api.exhibitmanis:ApiExample1( 35321 )
--
ExhibitManis.ApiExample1 = function(self, nEntityID)
    self:Debug(self.DebugLevels.Debug, "ExhibitManis.ApiExample1() for", nEntityID)
    if self.tEntities[nEntityID] ~= nil then
        return true, "Entity ID found"
    else 
        return false, "Entity ID not found" 
    end
end