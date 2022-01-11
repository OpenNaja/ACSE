-----------------------------------------------------------------------
--/  @file   Managers.ACSEParkManager.lua
--/  @author My Self
--/
--/  @brief  Boilerplate template for the park manager script
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local pairs = global.pairs
local require = global.require
local module = global.module
local Vector3 = require("vector3")
local table = require("Common.tableplus")
local Object = require("Common.object")
local Mutators = require("Environment.ModuleMutators")
local GameDatabase = require("Database.GameDatabase")
local ACSEParkManager = module(..., Mutators.Manager())

global.api.debug.Trace("ACSEParkManager loaded")

-- @Brief identify if we have initialized during island de-serialization
ACSEParkManager.bInitOnSerialization = false

-- @Brief Init function for this manager
ACSEParkManager.Init = function(self, _tProperties, _tEnvironment)
    api.debug.Trace("ACSEParkManager:Init()")
    local tWorldAPIs = ((api.world).GetWorldAPIs)()
    self.worldSerialisationAPI = tWorldAPIs.worldserialisation

    -- Our serialization client would store component and other related ACSE provided
    -- information. For now just creates the entry in the world serialization so we
    -- can initialize during loading.
    local fnSave = function(_tSave, _tParams)
        if _tParams.SerialisationType ~= (self.worldSerialisationAPI).Type_Island then
            -- All island type, better ignore this one
            return
        end
        _tSave.tComponents = {}
        return
    end

    -- Implementing prefab compilation during de-serialization.
    local fnLoad = function(_tLoad, _nLoadedVersion, _tParams)
        -- We need to make any required prefab available before the island is loading and
        -- other managers start instancing their entities.
        if ACSEParkManager.bInitOnSerialization == false then
            self:CompilePrefabs()
            ACSEParkManager.bInitOnSerialization = true
        end
        return true
    end

    local fnCanLoadOldVersion = function(_nOldVersion)
        return true
    end

    --/ Register our world serialization clients
    self.worldSerialisationAPI:RegisterWorldSerialisationClient("ACSE", 1, fnSave, fnLoad, fnCanLoadOldVersion)
    self.bInitOnSerialization = false
end

-- @Brief Update function for this manager, responsible to provide Advance to custom components
ACSEParkManager.Advance = function(self, _nDeltaTime, _nUnscaledDeltaTime)
    local tWorldAPIs = api.world.GetWorldAPIs()
	if tWorldAPIs.acsecomponentmanager then
		tWorldAPIs.acsecomponentmanager:Advance(_nDeltaTime, _nUnscaledDeltaTime)
	end
end

-- @Brief Activate function for this manager
ACSEParkManager.Activate = function(self)
    --/ Initialize prefabs if they haven't been intialized during de-serialization
    if ACSEParkManager.bInitOnSerialization == false then
        ACSEParkManager.bInitOnSerialization = true
        self:CompilePrefabs()
    end
end

-- @Brief Deactivate function for this manager
ACSEParkManager.Deactivate = function(self)
end

-- @Brief Shutdown function for this manager
ACSEParkManager.Shutdown = function(self)
    api.debug.Trace("ACSEParkManager:Shutdown()")
    self.worldSerialisationAPI:UnregisterWorldSerialisationClient("ACSE")
    self.bInitOnSerialization = false
end

-- @Brief Perform Lua compilation of prefabs
ACSEParkManager.CompilePrefabs = function(self)
    api.debug.Trace("ACSEParkManager:CompilePrefabs()")
    -- Compile all prefabs added to the ACSE database.
    if GameDatabase.GetLuaPrefabs then
        GameDatabase.BuildLuaPrefabs()
    end
end

--/ Validate class methods and interfaces
(Mutators.VerifyManagerModule)(ACSEParkManager)
