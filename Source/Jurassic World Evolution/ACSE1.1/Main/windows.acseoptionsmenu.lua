-- Decompiled using luadec 2.2 rev:  for Lua 5.3 from https://github.com/viruscamp/luadec
-- Command line: C:\Users\ilo\AppData\Local\Temp\windows.ACSEOptionsMenu.lua.bin

-- params : ...
-- function num : 0 , upvalues : _ENV
local global = _G
local api = api
local pairs = pairs
local ipairs = ipairs
local string = string
local tonumber = tonumber
local Object = require("Common.Object")
local OptionsGUI = require("UI.Controllers.OptionsGUI")
local table = require("Common.tableplus")
local ACSEOptionsMenu = module(..., Object.class)

api.asec.trace("acse ACSEOptionsMenu loaded")


ACSEOptionsMenu.Init = function(self, _GUIWrapper, _tData, _tSettingsMenuData)

  api.asec.trace("acse ACSEOptionsMenu Init")

  self.guiWrapper = _GUIWrapper
  self.bHasUnAppliedChanges = false
  local tWorldAPIs = ((api.world).GetWorldAPIs)()
  self.GameAudioAPI = tWorldAPIs.gameaudio
  self.tOptionValues = (self.GameAudioAPI):GetConfig()
  self.tOptionValuesOnOpen = self.tOptionValues
  api.asec.trace("acse ACSEOptionsMenu Init before _tSettingsMenuData")
  _tSettingsMenuData.items[#_tSettingsMenuData.items + 1] = {id = "acsesettings", label = "[OptionsMenu_ACSE]", streamedIcon = "OptionsMenuIconSettings"}

  api.asec.trace("acse ACSEOptionsMenu Init end")
end

ACSEOptionsMenu.GetMenuCategories = function(self)
  return {}
end

ACSEOptionsMenu.GetItems = function(self, _tSettingsMenuItemsData)
  api.asec.trace("acse ACSEOptionsMenu GetItems")

  -- function num : 0_2 , upvalues : OptionsGUI
  _tSettingsMenuItemsData.items = {
{id = "acse.generalheader", label = "[OptionsMenu_ACSEHeader]", itemRendererClass = OptionsGUI.SUBHEADER},
{id = "acse.customslider", label = "[OptionsMenu_ACSECustomSlider]", itemRendererClass = OptionsGUI.SLIDER, minValue = 0, maxValue = 150, currValue = (self.tOptionValues).nCurrentMasterVolume, incrementValue = "5"},
{id = "acse.customcheckbox", label = "[OptionsMenu_ACSECustomCheckbox]", itemRendererClass = OptionsGUI.CHECKBOX, toggled = (self.tOptionValues).bMuteCarRadio}
}
end

ACSEOptionsMenu.Shutdown = function(self)
  -- function num : 0_3
  self.guiWrapper = nil
  self:ApplyChanges()
end

ACSEOptionsMenu.HandleEvent = function(self, _sID, _arg)
  api.asec.trace("acse ACSEOptionsMenu handling change event")
  -- function num : 0_4
  if _sID == "acsesettings" then
    return true
  else
    if _sID == "acse.customslider" then
	  (self.tOptionValues).nCurrentMasterVolume = _arg
	  self:ApplyChangesTemp()
	  return true
	else
      if _sID == "acse.customcheckbox" then
		  (self.tOptionValues).bMuteCarRadio = _arg
		  self:ApplyChangesTemp()
		  return true
      end
    end
  end
  return false
end

ACSEOptionsMenu.ApplyChangesTemp = function(self)
  api.asec.trace("acse ACSEOptionsMenu apply changes temp")
  -- function num : 0_5 , upvalues : api
  local worldAPIs = ((api.world).GetWorldAPIs)()
  (self.GameAudioAPI):SetConfig(self.tOptionValues)
  return false
end

ACSEOptionsMenu.ApplyChanges = function(self)
  api.asec.trace("acse ACSEOptionsMenu apply changes")
  -- function num : 0_6 , upvalues : api
  self.bHasUnAppliedChanges = false
  local worldAPIs = ((api.world).GetWorldAPIs)()
  ;
  (self.GameAudioAPI):SetConfig(self.tOptionValues)
  return false
end

ACSEOptionsMenu.Reset = function(self)
  api.asec.trace("acse ACSEOptionsMenu reset settings")
  -- function num : 0_7
  self.tOptionValues = (self.GameAudioAPI):GetDefaultValues()

  (self.GameAudioAPI):SetConfig(self.tOptionValues)
  local tTabData = {}
  self:GetItems(tTabData)

  (self.guiWrapper):SetDataOnIds(tTabData.items)
end

ACSEOptionsMenu.RevertUnAppliedChanges = function(self)
  -- function num : 0_8
  self.tOptionValues = self.tOptionValuesOnOpen
  self:ApplyChanges()
end

ACSEOptionsMenu.ConfirmUnsafeChanges = function(self)
  -- function num : 0_9
end

ACSEOptionsMenu.RevertUnsafeChanges = function(self)
  -- function num : 0_10
end


