-----------------------------------------------------------------------
--/  @file   Managers.ACSEParkManager.lua
--/  @author Inaki
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

-- @Brief Init function for this manager
ACSEParkManager.Init = function(self, _tProperties, _tEnvironment)
    api.debug.Trace("ACSEParkManager:Init()")
    self.tWorldAPIs = api.world.GetWorldAPIs()
    self.worldSerialisationAPI = self.tWorldAPIs.worldserialisation

    -- Our serialization client would store component and other related ACSE provided
    -- information. For now just creates the entry in the world serialization so we
    -- can initialize during loading.
    local fnSave = function(_tSave)
        --api.debug.Trace("ACSEParkManager:fnSave()")
        _tSave.tComponents = {}
        return
    end

    -- Implementing prefab compilation during de-serialization.
    local fnLoad = function(_tLoad, _nLoadedVersion)
        --api.debug.Trace("ACSEParkManager:fnLoad()")
        -- We need to make any required prefab available before the island is loading and
        -- other managers start instancing their entities.
        if not self.bInitOnSerialization then
            self:CompilePrefabs()
            self.bInitOnSerialization = true
        end
        return true
    end

    local fnCanLoadOldVersion = function(_nOldVersion)
        --api.debug.Trace("ACSEParkManager:fnCanLoadOldVersion()")
        return true
    end

    --/ Register our world serialization clients
    local serial = self.worldSerialisationAPI:RegisterWorldSerialisationClient("ACSE", 1, fnSave, fnLoad, fnCanLoadOldVersion)

end

-- @Brief Update function for this manager
ACSEParkManager.Advance = function(self, _nDeltaTime, _nUnscaledDeltaTime)
    --api.debug.Trace("ACSEParkManager:Advance()")
	if self.tWorldAPIs and self.tWorldAPIs.acsecustomcomponentmanager then
		self.tWorldAPIs.acsecustomcomponentmanager:Advance(_nDeltaTime, _nUnscaledDeltaTime)
	end
end

-- @Brief Activate function for this manager
ACSEParkManager.Activate = function(self)
    api.debug.Trace("ACSEParkManager:Activate()")
    --/ Initialize prefabs if they haven't been intialized during de-serialization
    if not self.bInitOnSerialization then
        self.bInitOnSerialization = true
        self:CompilePrefabs()
    end
end

-- @Brief Deactivate function for this manager
ACSEParkManager.Deactivate = function(self)
    api.debug.Trace("ACSEParkManager:Deactivate()")
end

-- @Brief Shutdown function for this manager
ACSEParkManager.Shutdown = function(self)
    api.debug.Trace("ACSEParkManager:Shutdown()")
    self.worldSerialisationAPI:UnregisterWorldSerialisationClient("ACSE")
    self.bInitOnSerialization = nil
end

-- @Brief Perform Lua compilation of prefabs
ACSEParkManager.CompilePrefabs = function(self)
    api.debug.Trace("ACSEParkManager:CompilePrefabs()")
    -- Compile all prefabs added to the ACSE database.
    if GameDatabase.BuildLuaPrefabs then
        GameDatabase.BuildLuaPrefabs()
    end
end

--/ Validate class methods and interfaces
Mutators.VerifyManagerModule(ACSEParkManager)
