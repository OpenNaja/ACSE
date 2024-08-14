-----------------------------------------------------------------------
--/  @file   ACSEDebug.Debug.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes some of the debugging features disabled
--/          in the release version to improve debugging while modding the
--/          game.
--/
--/          Initializes a default log system.
--/          TODO: initializes an output console system.
--/  @Note   This module doesn't have a Shutdown function to close the current
--/          file descriptors used to log information, the process will do.
--/  @TODO   Handle file system limits in the dll
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local string       = global.string
local require      = global.require
local package      = global.package
local tostring     = global.tostring
local table        = require("Common.tableplus")
local Object       = require("Common.object")

global.loadfile("acse : ACSEDebug.debug.lua loaded")

local Debug = module(..., Object.class)

Debug.Init = function(self)

    local raw               = api.debug
    self.CreateLog          = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnCreateLog')
    self.WriteLog           = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnWriteLog')
    self.WriteLogNF         = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnWriteLogNoFlush')
    self.CloseLog           = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnCloseLog')
    self.MessageBox         = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnMessageBox')
    self.Print              = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnPrint')
    self.ClearScreen        = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnPrintReset')

    self.WriteStringToFile  = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnWriteStringToFile')
    self.ReadStringFromFile = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnReadStringFromFile')

    self.CreateConsole      = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnCreateConsole')
    self.WriteConsole       = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnWriteConsole')
    self.CloseConsole       = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnCloseConsole')
    self.ClearConsole       = package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnClearConsole')

    self.sLogFile           = nil
    self.sConsole           = nil

    -- This is the only module we can't mangle with their metatable, because we are in the middle
    -- of a function that will change it within API.Debug.lua
    self._tHandlers = {}

    self._tHandlers.CreateLog = api.debug.CreateLog
    api.debug.CreateLog = function(...)
        return self:Api_CreateLog(raw, ...)
    end

    self._tHandlers.WriteLog = api.debug.WriteLog
    api.debug.WriteLog = function(...)
        return self:Api_WriteLog(raw, ...)
    end

    self._tHandlers.CloseLog = api.debug.CloseLog
    api.debug.CloseLog = function(...)
        return self:Api_CloseLog(raw, ...)
    end

    self._tHandlers.Trace = api.debug.Trace
    api.debug.Trace    = function(...)
        return self:Api_Trace(raw, ...)
    end

    self._tHandlers.Warning = api.debug.Warning
    api.debug.Warning  = function(...)
        return self:Api_Warning(raw, ...)
    end

    self._tHandlers.Error = api.debug.Error
    api.debug.Error    = function(...)
        return self:Api_Error(raw, ...)
    end

    self._tHandlers.Assert = api.debug.Assert
    api.debug.Assert    = function(...)
        return self:Api_Assert(raw, ...)
    end

    self._tHandlers.Print = api.debug.Print
    api.debug.Print    = function(...)
        return self:Api_Print(raw, ...)
    end

    self._tHandlers.WriteLine = api.debug.WriteLine
    api.debug.WriteLine    = function(...)
        return self:Api_WriteLine(raw, ...)
    end

    self._tHandlers.WriteStringToFile = api.debug.WriteStringToFile
    api.debug.WriteStringToFile = function(...)
        return self:Api_WriteStringToFile(raw, ...)
    end

    self._tHandlers.ReadStringFromFile = api.debug.ReadStringFromFile
    api.debug.ReadStringFromFile = function(...)
        return self:Api_ReadStringFromFile(raw, ...)
    end

    api.debug.CreateConsole = function(...)
        return self:Api_CreateConsole(raw, ...)
    end

    api.debug.WriteConsole = function(...)
        return self:Api_WriteConsole(raw, ...)
    end

    api.debug.WriteToCommandConsole = function(...)
        return self:Api_WriteToCommandConsole(raw, ...)
    end

    api.debug.CloseConsole = function(...)
        return self:Api_CloseConsole(raw, ...)
    end

    api.debug.ClearConsole = function(...)
        return self:Api_ClearConsole(raw, ...)
    end

    api.debug.ClearScreen = function(...)
        return self:Api_ClearScreen(raw, ...)
    end


    -- Special functions
    api.debug.TraceNoFlush = function(...)
        return self:Api_TraceNoFlush(raw, ...)
    end

    -- For tracing time
    self.nStartTime = api.time.GetPerformanceTimer()

    api.acsedebug.debug = Debug
end

Debug.Api_CreateLog = function(self, _raw, sFileName)
    self.sLogFile = sFileName
    self.CreateLog(sFileName)
end

Debug.Api_WriteLog = function(self, _raw, sText)
    if self.sLogFile then 
        self.WriteLog(sText)
    end
end

Debug.Api_CloseLog = function(self, _raw)
    if self.sLogFile then 
        self.CloseLog()
        self.sLogFile = nil
    end
end

Debug.Api_Trace = function(self, _raw, sText)
    local nNewTime = api.time.GetPerformanceTimer()
    local nDiff    = api.time.DiffPerformanceTimers(nNewTime, self.nStartTime)
    local nDiffMs  = api.time.PerformanceTimeToMilliseconds(nDiff)
    local sTimeStr = string.format("[%012.3f] ", nDiffMs/1000)
    -- global.loadfile("acse : " .. sTimeStr .. tostring(sText) )
    if sText and global.string.len(sText) == 0 then return end
    global.api.debug.WriteLog(sTimeStr .. tostring(sText) .. "\n")
    return -- self._tHandlers.Trace(sText)
end

Debug.Api_TraceNoFlush = function(self, _raw, sText)
    local nNewTime = api.time.GetPerformanceTimer()
    local nDiff    = api.time.DiffPerformanceTimers(nNewTime, self.nStartTime)
    local nDiffMs  = api.time.PerformanceTimeToMilliseconds(nDiff)
    local sTimeStr = string.format("[%012.3f] ", nDiffMs/1000)
    if sText and global.string.len(sText) == 0 then return end
    self.WriteLogNF(sTimeStr .. tostring(sText) .. "\n")
    return 
end


Debug.Api_Warning = function(self, _raw, sText)
    if sText and global.string.len(sText) == 0 then sText = ' ' end
    global.api.debug.Trace("Warning: " .. tostring(sText))
    return self._tHandlers.Warning(sText)
end

Debug.Api_Error = function(self, _raw, sText)
    if sText and global.string.len(sText) == 0 then return end
    global.api.debug.Trace("Error: " .. tostring(sText))
    return self._tHandlers.Error(sText)
end

Debug.Api_Assert = function(self, _raw, bCondition, sText)
    local result = nil
    if global.type(bCondition) == 'boolean' and bCondition == false and sText ~= nil then
        global.api.debug.Trace("Assert: " .. tostring(sText))
        result = self.MessageBox("Assert error" , tostring(sText))
    end
    -- return self._tHandlers.Assert(bCondition, sText)
    return bCondition, result
end

Debug.Api_Print = function(self, _raw, sText, sColour)
    if api.acsedebug.acsedebugglobal.disableprint == false then
        if sText and global.string.len(sText) == 0 then return end

        if sText and global.type(sText) == 'string' then
            self.Print(sText);
        end
    end
    --self.WriteConsole(tostring(sText))
    return 
end

Debug.Api_WriteLine = function(self, _raw, nDescriptor, sText)
    -- api.debug.Trace("Api_WriteLine " .. global.tostring(nDescriptor) .. ": '" .. global.tostring(sText) .. "'")
    if nDescriptor == 1 then
        global.api.acsedebugcomponent:WriteLine(tostring(sText))
    else
        global.api.debug.Trace(tostring(sText))
    end
    return -- self._tHandlers.WriteLine(nDescriptor, sText)
end

Debug.Api_WriteStringToFile = function(self, _raw, sFileName, sFileContent, bFlags)
    if global.type(sFileName) == 'string' and sFileName  ~= nil then
        api.debug.Trace("Saving file: " .. tostring(sFileName))
        local append = 'CREATE'
        if bFlags == true then append = 'APPEND' end
        return self.WriteStringToFile(sFileName, sFileContent, append)
    end
    return -- self._tHandlers.WriteStringToFile(sFilename, sFileContent, bFlags)
end

Debug.Api_ReadStringFromFile = function(self, _raw, sFileName)
    if global.type(sFileName) == 'string' and sFileName  ~= nil then
        api.debug.Trace("Reading file: " .. tostring(sFileName))
        return self.ReadStringFromFile(sFileName)
    end
    return -- self._tHandlers.ReadStringFromFile(sFilename)
end

Debug.Api_CreateConsole = function(self, _raw)
    self.CreateConsole()
end

Debug.Api_CloseConsole = function(self, _raw)
    self.CloseConsole()
end

Debug.Api_ClearConsole = function(self, _raw)
    self.ClearConsole()
end

Debug.Api_WriteConsole = function(self, _raw, sText)
    --if self.sConsole == nil then
        api.debug.WriteLine(1, tostring(sText))
        api.debug.Trace(tostring(sText))
    --else
    --    self.WriteConsole(sText)
    --end
end

Debug.Api_WriteToCommandConsole = function(self, _raw, sText)
    --if self.sConsole == nil then
        api.debug.WriteLine(1, tostring(sText))
        api.debug.Trace(tostring(sText))
    --else
    --    self.WriteConsole(sText)
    --end
end

Debug.Api_ClearScreen = function(self, _raw)
    self.ClearScreen()
end

Debug.Shutdown = function(self)
    -- api.debug = global.getmetatable(api.debug).__index
end

