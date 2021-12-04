-----------------------------------------------------------------------
--/  @file   UI.Controllers.ACSEDebugWindow.lua
--/  @author My Self
--/
--/  @brief  Handles Flash-Lua movie interaction
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local string = global.string
local math = global.math
local ipairs = global.ipairs
local table = global.table
local Object = require("Common.object")
local UIWrapper = require("UIWrapper")
local ACSEDebugWindowGUI = module(..., (Object.subclass)(UIWrapper))
local sMovieName = "ACSEDebugWindow"
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
  -- function num : 0_4
  self:Invoke("AddLog", _sData)
end

ACSEDebugWindowGUI.SetCommand = function(self, _sData)
  -- function num : 0_4
  self:Invoke("SetCommand", _sData)
end

ACSEDebugWindowGUI.IncreaseScroll = function(self)
  -- function num : 0_4
  self:Invoke("IncreaseScroll")
end

ACSEDebugWindowGUI.DecreaseScroll = function(self)
  -- function num : 0_4
  self:Invoke("DecreaseScroll")
end

ACSEDebugWindowGUI.ClearLog = function(self)
  -- function num : 0_4
  self:Invoke("ClearLog")
end

ACSEDebugWindowGUI.CopyLog = function(self)
  -- function num : 0_4
  self:Invoke("CopyLog")
end
