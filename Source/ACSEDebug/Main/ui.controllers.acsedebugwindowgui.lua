-----------------------------------------------------------------------
--/  @file   UI.Controllers.ACSEDebugWindow.lua
--/  @author My Self
--/
--/  @brief  Handles Flash-Lua movie interaction
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global     = _G
local require    = global.require
local Object     = require("Common.object")
local UIWrapper  = require("UIWrapper")

local sMovieName = "ACSEDebugWindow"

local ACSEDebugWindowGUI = module(..., Object.subclass(UIWrapper))

ACSEDebugWindowGUI.new = function(self, _tObjects)
  self = UIWrapper:new(self, sMovieName, _tObjects)
  return self
end

ACSEDebugWindowGUI.Show = function(self)
  self:Invoke("Show")
end

ACSEDebugWindowGUI.Hide = function(self)
  self:Invoke("Hide")
end

ACSEDebugWindowGUI.Close = function(self)
  UIWrapper.Close(self)
end

ACSEDebugWindowGUI.AddLog = function(self, _sData)
  self:Invoke("AddLog", _sData)
end

ACSEDebugWindowGUI.SetCommand = function(self, _sData)
  self:Invoke("SetCommand", _sData)
end

ACSEDebugWindowGUI.IncreaseScroll = function(self)
  self:Invoke("IncreaseScroll")
end

ACSEDebugWindowGUI.DecreaseScroll = function(self)
  self:Invoke("DecreaseScroll")
end

ACSEDebugWindowGUI.ClearLog = function(self)
  self:Invoke("ClearLog")
end

ACSEDebugWindowGUI.CopyLog = function(self)
  self:Invoke("CopyLog")
end
