-----------------------------------------------------------------------
--/  @file   ACSEDebug.ShellCommands.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the debug shell command interface
--/
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

global.loadfile("acse : ACSEDebug.ShellCommands.lua loaded")

local ShellCommands = module(..., Object.class)

ShellCommands.Init = function(self)

    local raw = api.debug

    self._tHandlers = {}

    self._tHandlers.RegisterShellCommand = api.debug.RegisterShellCommand
    api.debug.RegisterShellCommand    = function(...)
        return self:Api_RegisterShellCommand(raw, ...)
    end

    self._tHandlers.RunShellCommand = api.debug.RunShellCommand
    api.debug.RunShellCommand    = function(...)
        return self:Api_RunShellCommand(raw, ...)
    end

    self._tHandlers.UnregisterShellCommand = api.debug.UnregisterShellCommand
    api.debug.UnregisterShellCommand    = function(...)
        return self:Api_UnregisterShellCommand(raw, ...)
    end

    self.tShellCommands = {}
    self.tShellCommandsShort = {}

    api.acsedebug.shellcommands = ShellCommands
end

ShellCommands.Shutdown = function(self)
    -- api.debug = global.getmetatable(api.debug).__index
end

ShellCommands.Api_RegisterShellCommand = function(self, _raw, _fn, sCmd, sDesc)
    -- api.debug.Trace("RegisterShellCommand " .. sCmd)
    --/ Save the short command version

    -- @splits a string by spaces, respecting quoted strings
    function stringSplit(text)
        local tout = {}
        if text == nil then return tout end
        
        local e = 0
        while true do
            local b = e + 1
            b = text:find("%S", b)
            if b == nil then
                break
            end
            if text:sub(b, b) == "'" then
                e = text:find("'", b + 1)
                b = b + 1
            elseif text:sub(b, b) == '"' then
                e = text:find('"', b + 1)
                b = b + 1
            else
                e = text:find("%s", b + 1)
            end
            if e == nil then
                e = #text + 1
            end
            global.table.insert(tout, text:sub(b, e - 1))
        end
        return tout
    end

    -- @brief from &Time&Of&Day command string, returns tod
    function getCommandShortName(text)
        local tout = {}
        for match in text:gmatch("&(.)") do
            global.table.insert(tout, match:lower())
        end
        if #tout > 0 then
            return global.table.concat(tout)
        else
            return nil
        end
    end

    local shortcut = getCommandShortName(sCmd)

    --/ make a new command
    local command = {}
    command._fn = _fn
    command._sCmd = global.string.gsub(sCmd, "&", "") -- Remove case sensitivity marker
    command._sDesc = sDesc

    name = stringSplit(command._sCmd)[1]
    name = global.string.lower(name)

    --/ save the command and shortcut version
    self.tShellCommands[name] = command
    if shortcut then
        self.tShellCommandsShort[shortcut] = name
    end

    return self.tShellCommands[name]
end
    

-- @brief Runs a command
ShellCommands.Api_RunShellCommand = function(self, _raw, sCmd)
    -- Some commands will try to print/dump into the environment.output stream, it just needs
    -- to be initialised for the game not crash
    local tEnv = api.game.GetEnvironment()
    if tEnv.DebugUI then 
        tEnv.output = 1 -- Prevent writting to the UI if the UI is not initialised, default to log
    else 
        tEnv.output = 2
    end
    tEnv.error = 2  -- Log by default

    api.debug.WriteLine(tEnv.output, ">> " .. global.tostring(sCmd))
    -- this RunShellCommand will fail until we handle missing argument types (vector:3 etc..)
    -- @splits a string by spaces, respecting quoted strings
    function stringSplit(text)
        local tout = {}
        if text == nil then return tout end
        
        local e = 0
        while true do
            local b = e + 1
            b = text:find("%S", b)
            if b == nil then
                break
            end
            if text:sub(b, b) == "'" then
                e = text:find("'", b + 1)
                b = b + 1
            elseif text:sub(b, b) == '"' then
                e = text:find('"', b + 1)
                b = b + 1
            else
                e = text:find("%s", b + 1)
            end
            if e == nil then
                e = #text + 1
            end
            global.table.insert(tout, text:sub(b, e - 1))
        end
        return tout
    end

    tArgs = stringSplit(sCmd)
    name = tArgs[1]
    name = global.string.lower(name)
    global.table.remove(tArgs, 1)

    name = self.tShellCommandsShort[name] or name
    local cmd = self.tShellCommands[name]

    if cmd ~= nil then
        -- Convert Arg types
        tCArgs = stringSplit(cmd._sCmd)
        global.table.remove(tCArgs, 1)

        for i, v in global.pairs(tArgs) do
            if tCArgs[i] ~= nil then
                if global.string.match(tCArgs[i], "{string}") then
                end -- do nothing, for SetTweakable
                if global.string.match(tCArgs[i], "{value}") then
                end -- do nothing, for SetTweakable
                if global.string.match(tCArgs[i], "{float}") then
                    tArgs[i] = global.tonumber(tArgs[i])
                end
                if global.string.match(tCArgs[i], "{int32}") then
                    tArgs[i] = global.tonumber(tArgs[i])
                end
                if global.string.match(tCArgs[i], "{uint32}") then
                    tArgs[i] = global.tonumber(tArgs[i])
                end
                if global.string.match(tCArgs[i], "{uint64}") then
                    tArgs[i] = global.tonumber(tArgs[i])
                end
                -- Missing {notificationtype} {notificationcontexttype} {vector:3} and {vector:2}
                -- also missing optional args []
                local stringtoboolean = {["true"] = true, ["false"] = false}
                if global.string.match(tCArgs[i], "{bool}") then
                    tArgs[i] = stringtoboolean[tArgs[i] ]
                end
            end
        end

        local msgh = function(sError) 
            global.api.debug.WriteLine( tEnv.output, global.tostring(sError))
        end

        local bRet, bErr, sMsg = global.xpcall(cmd._fn, msgh, tEnv, tArgs)
        
        if sMsg ~= nil then
            global.api.debug.WriteLine( tEnv.output, global.tostring(sMsg))
        end
    end
end

ShellCommands.Api_UnregisterShellCommand = function(self, _raw, tCmd)
    -- api.debug.Trace("UnregisterShellCommand " .. global.tostring(tCmd._sCmd))
    -- @splits a string by spaces, respecting quoted strings
    function stringSplit(text)
        local tout = {}
        if text == nil then return tout end
        
        local e = 0
        while true do
            local b = e + 1
            b = text:find("%S", b)
            if b == nil then
                break
            end
            if text:sub(b, b) == "'" then
                e = text:find("'", b + 1)
                b = b + 1
            elseif text:sub(b, b) == '"' then
                e = text:find('"', b + 1)
                b = b + 1
            else
                e = text:find("%s", b + 1)
            end
            if e == nil then
                e = #text + 1
            end
            global.table.insert(tout, text:sub(b, e - 1))
        end
        return tout
    end

    name = stringSplit(tCmd._sCmd)[1]
    name = global.string.lower(name)
    self.tShellCommands[name] = nil
    return
end
