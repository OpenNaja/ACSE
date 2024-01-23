-----------------------------------------------------------------------
--/  @file   Managers.ACSEStartScreenManager.lua
--/  @author Inaki
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
local ACSEStartScreenManager = module(..., Mutators.Manager())

-- @Brief Init function for this manager
ACSEStartScreenManager.Init = function(self, _tProperties, _tEnvironment)
    api.debug.Trace("ACSEStartScreenManager:Init()")

    --/ Force load of startscreen.shared.startscreenhud.lua to display ACSE version
    local modname = "startscreen.shared.startscreenhud"
    global.require(modname)

    --/ Required module will be in the package loaded table.
    local tstartscreenhud = global.package.preload[modname] or global.package.loaded[modname]
    global.api.debug.Assert(tstartscreenhud ~= nil, "Can't find startscreenhud resource")

    if not tstartscreenhud.OnGlobePopulateCompleteOld then
        tstartscreenhud.OnGlobePopulateCompleteOld = tstartscreenhud.OnGlobePopulateComplete
        tstartscreenhud.OnGlobePopulateComplete = function(self, _tGlobePinData, _fnSetPeepVisible, _fnSetPeepInvisible)
            global.api.debug.Trace("StartScreenHUD:OnGlobePopulateComplete()")
            self.tCachedGlobePinData = _tGlobePinData
            self.fnSetPeepVisible = _fnSetPeepVisible
            self.fnSetPeepInvisible = _fnSetPeepInvisible
            local allUnownedDLC = ((api.content).GetUnownedMask)((api.content).DLC_AllStoreContent)
            local releasedUnownedDLC = ((api.content).FilterAvailable)(allUnownedDLC)
            local bHasDLCItems = releasedUnownedDLC ~= 0
            local tFilterTypes = {nFilterType_All}
            local tFilters = {
                {id = "filter_globe_all", streamedIcon = "SteamList_All", toolTip = "[FrontEndMenu_GlobeFilter_All]"}
            }
            local tFilterIndices = {}
            (table.map)(
                tFilterTypes,
                function(k, v)
                    tFilterIndices[v] = k - 1
                end
            )
            local tListItems, firstItemToSelect = self:GetListItemsFromPlayerData(_tGlobePinData)
            local bUseLargeItems = false
            self:SetGlobeItemsList(tListItems, bUseLargeItems)
            if self.uiMenu then
                self.uiMenu:SetSelectedGlobeListItem(firstItemToSelect)
				self.uiMenu:SetGlobeItemsFilterData(
                    {
					  items = tFilters,
					  selectedIndex = tFilterIndices[self.nFilterType] or 0
					}
                )
            end
            self:SetupNewsletterData()
            self:CheckNewsletterRewardFanfare()
            local uiVersionString = ((api.ui).EscapeString)(((api.game).GetVersionString)())
            if ((api.steam).IsOnline)() then
                --local sVersionString = "[HUD_SettingsMenu_Version:Version='" .. uiVersionString .. "']
				local sVersionString = "[STRING_LITERAL:Value='" .. uiVersionString .. "\nACSE: ".. global.api.acse.GetACSEVersionString() .. "']"
                if self.uiMenu then
                    (self.uiMenu):SetConnectionStatusData(
                        {label = sVersionString, connectionState = "Connected"}
                    )
                end
                self:ShowConnectionStatus()
            else
                --local sVersionString = "[FrontEndMenu_Disconnected:Version='" .. uiVersionString .. "']
				local sVersionString = "[STRING_LITERAL:Value='" .. uiVersionString .. "\nACSE: ".. global.api.acse.GetACSEVersionString() .. "']"
                if self.uiMenu then
                    (self.uiMenu):SetConnectionStatusData(
                        {label = sVersionString, connectionState = "Disconnected"}
                    )
                end
                self:ShowConnectionStatus()
            end
            if self.bPlayButtonsShown then
                self:ShowGlobeItemsList()
            end
        end

        --/ We move the resource to the preload table, so Lua wont need to load it again and
        --/ will return our changes
        global.package.preload[modname] = tstartscreenhud
    end
    api.debug.Trace("ACSEStartScreenManager:Init()")
end

-- @Brief Activate function for this manager
ACSEStartScreenManager.Activate = function(self)
    api.debug.Trace("ACSEStartScreenManager:Activate()")
end

-- @Brief Update function for this manager
ACSEStartScreenManager.Advance = function(self, _nDeltaTime, _nUnscaledDeltaTime)
	--// Advance our custom component manager
    local tWorldAPIs = api.world.GetWorldAPIs()
	if tWorldAPIs.acsecustomcomponentmanager then
		tWorldAPIs.acsecustomcomponentmanager:Advance(_nDeltaTime, _nUnscaledDeltaTime)
	end
end

-- @Brief Deactivate function for this manager
ACSEStartScreenManager.Deactivate = function(self)
    api.debug.Trace("ACSEStartScreenManager:Activate()")
end

-- @Brief Shutdown function for this manager
ACSEStartScreenManager.Shutdown = function(self)
    api.debug.Trace("ACSEStartScreenManager:Shutdown()")
end

--/ Validate class methods and interfaces
Mutators.VerifyManagerModule(ACSEStartScreenManager)
