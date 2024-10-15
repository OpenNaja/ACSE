-----------------------------------------------------------------------
--/  @file   Components.JuvenileScale.lua
--/  @author Inaki
--/
--/  @brief  Scales a PZ animal based on its juvenile cycle.
--/
--/  Add the following Component to a juvenile prefab
--/
--/  JuvenileScale = {
--/      minScale = 0.3,
--/      maxScale = 1.1,
--/  }
--/
--/
--/  The default values for missing scale attributes are:
--/  minScale = 0.7
--/  maxScale = 1.0
--/
--/  This controller does not include save/loading of entities because the current juvenile
--/  size is calculated based on their attributes. In any case it will use the default
--/  value in its prefab's properties table if any, or the options during instance creation.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local Trace = api.debug.Trace
local coroutine = global.coroutine
local pairs = global.pairs
local ipairs = global.ipairs
local require = global.require
local table = require("Common.tableplus")
local type = global.type
local math = global.math
local Object = require("Common.object")
local Transform = require("Transform")
local Vector3 = require("Vector3")
local Vector2 = require("Vector2")
local TransformQ = require("TransformQ")
local mathUtils = require("Common.MathUtils")
local Base = require("LuaComponentManagerBase")
local JuvenileScale = module(..., Object.subclass(Base))
local TransformAPI = api.transform

local s_GlobalScaleMultiplier = api.debug.CreateDebugTweakable(
    api.debug.Tweakable_Float, 
    "JuvenileScale.GlobalScaleMultiplier", 
    1, 
    0, 
    10, 
    0.10
)

local s_GlobalScaleTimeStep = api.debug.CreateDebugTweakable(
    api.debug.Tweakable_Float, 
    "JuvenileScale.GlobalScaleTimeStep", 
    30, 
    0, 
    3000, 
    1
)

-- Mod debug levels and default log filter
JuvenileScale.DebugLevels = {
    Always  = 0,
    Error   = 1,
    Warning = 2,
    Info    = 3,
    Debug   = 4,
    Extra   = 5,
}
JuvenileScale.DebugLevel = JuvenileScale.DebugLevels.Info

JuvenileScale.Debug = function(self, nLevel, ...)
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

--//
--// @brief: List of our supported APIs, accessible through:
--// - api.juvenilescale:SetJuvenileScale(nVisualEntityID, tScaleData)
--// - api.juvenilescale:GetJuvenileScale(nVisualEntityID)
--//
JuvenileScale.tAPI = {
    "SetJuvenileScale", 
    "GetJuvenileScale"
}

--//
--// @brief: Called to initalize the component on environment start
--//
JuvenileScale.Init = function(self, _tWorldAPIs)
    self:Debug(self.DebugLevels.Always, "ExhibitManis:Init() version 0.102")

    self.tEntities = {}
    self._tWorldAPIs = _tWorldAPIs
    self.animalsAPI = self._tWorldAPIs.animals
    self.fLastUpdate = 0

    -- Register our own custom shell commands
    self.tShellCommands = {
        --
        -- Custom command to do change the animation speed of an entity through the debug console
        --
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 3 then
                    return false, "Requires a visual entity ID and two scale values (min and max)."
                end
                return self:SetJuvenileScale(tArgs[1], {minScale = tArgs[2], maxScale = tArgs[3]})
            end,
            "&Set&Juvenile&Scale {int32} {float} {float}",
            "Sets the juvenile scale data for the Entity ID.\n"
        )
    }
end

--//
--// @brief: Called after Init when the world is about to load
--//
JuvenileScale.Configure = function(self)
    self:Debug(self.DebugLevels.Extra, "ExhibitManis:Configure()")
end

--//
--// @brief: Called to clean up the component on environment shutdown
--//
JuvenileScale.Shutdown = function(self)
    self:Debug(self.DebugLevels.Always, "ExhibitManis:Shutdown()")

    self.tEntities = {}

    -- Remove custom commands
    for i, oCommand in global.ipairs(self.tShellCommands) do
        api.debug.UnregisterShellCommand(oCommand)
    end

    self.tShellCommands = {}
end

--//
--// @brief: Called to add the component to an array of entity ID with parameters
--//
JuvenileScale.AddComponentsToEntities = function(self, _tArrayOfEntityIDAndParams)
    self:Debug(self.DebugLevels.Debug, "JuvenileScale.AddComponentsToEntities()")
    --api.debug.Trace("JuvenileScale:AddComponentsToEntities()")

    for _, tEntry in ipairs(_tArrayOfEntityIDAndParams) do
        -- The game validates the prefab data using specdefs, but because this is a
        -- custom component without a specdef we need to validate the data we receive
        -- from the prefab
        self:Debug(self.DebugLevels.Extra, "Entity ID", tEntry.entityID)
        local scaleData = tEntry.tParams
        if global.type(scaleData) == "table" then
            local minScale = scaleData.minScale or 0.7
            local maxScale = scaleData.maxScale or 1.0
            self.tEntities[tEntry.entityID] = {
                minScale = mathUtils.Clamp(minScale, 0.0, 10.0),
                maxScale = mathUtils.Clamp(maxScale, 0.0, 10.0)
            }
        else
            -- Default component values
            self.tEntities[tEntry.entityID] = {
                minScale = 0.7,
                maxScale = 1.0
            }
        end
        self:Debug(self.DebugLevels.Extra, "Entity data", self.tEntities[tEntry.entityID])

        -- Apply already
        local fScale = self:CalculateScaleValue(tEntry.entityID)
        self:ApplyScaleValue(tEntry.entityID, fScale)
    end
    return true
end

--//
--// @brief: Calculate the currect scale value of a juvenile based on their game entity data
--//
JuvenileScale.CalculateScaleValue = function(self, nEntityID)
    self:Debug(self.DebugLevels.Extra, "JuvenileScale.CalculateScaleValue()")

    --api.debug.Trace("JuvenileScale.CalculateScaleValue()")
    local gameEntityID = self.animalsAPI:GetGameEntityFromVisualEntity(nEntityID)
    if not gameEntityID then
        return 1.0
    end

    local tAgeProps = self.animalsAPI:GetAgeProps(gameEntityID)
    local fJuvenilePercent = tAgeProps.nCurrent / tAgeProps.nAdult
    local fScaleDiff = self.tEntities[nEntityID].maxScale - self.tEntities[nEntityID].minScale

    -- return the variance from min to max scale values depending on the juvenile percentage
    return self.tEntities[nEntityID].minScale + fJuvenilePercent * fScaleDiff
end

--//
--// @brief: Apply the desired Scale value to a visual entity
--//
JuvenileScale.ApplyScaleValue = function(self, nEntityID, fScale)
    self:Debug(self.DebugLevels.Extra, "JuvenileScale.ApplyScaleValue()")

    if not fScale then
        fScale = self:CalculateScaleValue(nEntityID)
    end
    api.transform.SetScale(nEntityID, fScale * s_GlobalScaleMultiplier:GetValue())
end

--//
--// @brief: Called to remove the component from an array of entities
--//
JuvenileScale.RemoveComponentFromEntities = function(self, _tEntitiesArray)
    self:Debug(self.DebugLevels.Debug, "JuvenileScale.RemoveComponentFromEntities()")
    for _, entityID in ipairs(_tEntitiesArray) do
        self:Debug(self.DebugLevels.Extra, "entity ID", entityID)
        if self.tEntities[entityID] ~= nil then
            self.tEntities[entityID] = nil
        end
    end
end

--//
--// @brief: Updates the rotation of each animated entity
--//
JuvenileScale.Advance = function(self, _nDeltaTime, _nUnscaledDeltaTime)
    --api.debug.Trace("JuvenileScale:Advance() " .. global.tostring(_nDeltaTime) )

    -- this is time scaled
    local ftime = api.time.GetTotalTime()
    local fTimeStep = s_GlobalScaleTimeStep:GetValue()

    if ftime > (self.fLastUpdate + fTimeStep) then
        self.fLastUpdate = ftime
        self:Debug(self.DebugLevels.Extra, "JuvenileScale.Advance()", self.fLastUpdate)

        for entityID, tData in pairs(self.tEntities) do
            self:ApplyScaleValue(entityID)
        end
    end
end

--//
--// @brief: Activates Advance()
--// Called when the world is ready
--//
JuvenileScale.OnWorldActivation = function(self)
    self:Debug(self.DebugLevels.Extra, "JuvenileScale.OnWorldActivation()")
end

--//
--// @brief: Deactivates Advance()
--// Called when the world is not ready
--//
JuvenileScale.OnWorldDeactivation = function(self)
    self:Debug(self.DebugLevels.Debug, "JuvenileScale.OnWorldDeactivation()")
end

--//
--//
--// Component API
--//

--//
--// @brief: allows setting the animation speed for a specific entity
--// usage: global.api.JuvenileScale:SetJuvenileScale( 35321, { minScale = 0.2, maxScale = 0.8 })
--//
JuvenileScale.SetJuvenileScale = function(self, nEntityID, tData)
    self:Debug(self.DebugLevels.Debug, "JuvenileScale.SetJuvenileScale() for entity id", nEntityID)
    if self.tEntities[nEntityID] then
        self.tEntities[nEntityID].minScale = mathUtils.Clamp(tData.minScale, 0.0, 10.0)
        self.tEntities[nEntityID].maxScale = mathUtils.Clamp(tData.maxScale, 0.0, 10.0)
    end
end

--//
--// @brief: allows getting the juvenile scale data for a specific entity
--// usage: local tScaleData = global.api.JuvenileScale:GetJuvenileScale( 35321 )
--//
JuvenileScale.GetJuvenileScale = function(self, nEntityID)
    self:Debug(self.DebugLevels.Debug, "JuvenileScale.GetJuvenileScale() for entity id", nEntityID)
    return self.tEntities[nEntityID]
end
