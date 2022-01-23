-----------------------------------------------------------------------
--/  @file   Managers.ACSEStartScreenManager.lua
--/  @author My Self
--/
--/  @brief  Boilerplate template for the starting screen manager script
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local pairs = global.pairs
local require = global.require
local module = global.module
local table = require("Common.tableplus")
local Object = require("Common.object")
local Mutators = require("Environment.ModuleMutators")
local ACSEStartScreenManager= module(..., Mutators.Manager())

-- @Brief Init function for this manager
ACSEStartScreenManager.Init = function(self, _tProperties, _tEnvironment)
	api.debug.Trace("ACSEStartScreenManager:Init()")
end

-- @Brief Activate function for this manager
ACSEStartScreenManager.Activate = function(self)
end

-- @Brief Update function for this manager
ACSEStartScreenManager.Advance = function(self, _nDeltaTime)

    --// boolean if else then to track when to inject settings in the menu or the version
    --// in the UI. Can't do this on Activate since the world is the last to activate and
    --// will override any change.
    if self.worldScript then
    else
        if global.api.world.GetActive() then
            self.worldScript = global.api.world.GetScript(global.api.world.GetActive())
            self:_attachACSEVersionString()
        end
    end

	--// Advance our custom component manager
    local tWorldAPIs = api.world.GetWorldAPIs()
	if tWorldAPIs.acsecustomcomponentmanager then
		tWorldAPIs.acsecustomcomponentmanager:Advance(_nDeltaTime, _nUnscaledDeltaTime)
	end

end

-- @Brief Deactivate function for this manager
ACSEStartScreenManager.Deactivate = function(self)
end

-- @Brief Shutdown function for this manager
ACSEStartScreenManager.Shutdown = function(self)
	api.debug.Trace("ACSEStartScreenManager:Shutdown()")
end

-- @Brief Display ACSE is enabled in the frontend version string
ACSEStartScreenManager._attachACSEVersionString = function(self)
    api.debug.Trace("ACSEStartScreenManager:_attachACSEVersionString()")

    local versionString = global.api.game.GetVersionString()
    local endpointString = global.api.game.GetEndpointTypeString()
    local acseString = global.api.acse.GetACSEVersionString()
    local uiContext = global.api.ui.GetDataStoreContext("ui")

    api.ui.SetDataStoreElement(
        uiContext,
        "versionNumber",
        versionString .. endpointString .. "\n" .. "ACSE " .. acseString
    )
end

--/ Validate class methods and interfaces
(Mutators.VerifyManagerModule)(ACSEStartScreenManager)

