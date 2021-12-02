-----------------------------------------------------------------------
--/  @file   ACSELuaDatabase.lua
--/  @author My Self
--/
--/  @brief  Handles ACSE loading and database creation
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local table = global.table
local pairs = global.pairs
local ipairs = global.ipairs
local type  = global.type
local require = require
local ACSEDatabase = module(...)

global.api.debug.Trace("Database.ACSELuaDatabase.lua loaded")

-- @brief setup a custom debug/trace system to use
global.api.acse = {}
global.api.acse.versionNumber = 0.513
global.api.acse.GetACSEVersionString = function()
    return global.tostring(global.api.acse.versionNumber)
end

-- Tweakable support
global.api.acse.tTweakables = {}

global.api.acse.GetTweakables = function()
    return global.api.acse.tTweakables
end

--/@brief make our own tweakables manager
global.api.acse.CreateDebugTweakable = function(ttype, id, arg1, arg2, arg3, arg4)
    --/ Tweakable types: 22 boolean, 11 float, 8 integer64, 7 integer32
    --/ tweakable exists, return the original one

    local nid = global.string.lower(id)
    -- global.api.debug.Trace("Creating Tweakable : " .. global.tostring(nid)  )

    if global.api.acse.tTweakables[nid] then
        return global.api.acse.tTweakables[nid]
    end

    --/ make a new tweakable
    local tweakable = {}
    tweakable.index = {}
    tweakable.metatable = {__index = tweakable.index}
    tweakable.id = id
    tweakable.type = ttype
    tweakable.value = arg1
    tweakable.min = arg2
    tweakable.max = arg3
    tweakable.step = arg4
    tweakable.GetValue = function(self)
        return self.value
    end
    tweakable.SetValue = function(self, newValue)
        self.value = newValue
    end

    --/ save the tweakable
    global.api.acse.tTweakables[nid] = tweakable
    return tweakable
end

--/@brief retrieve a tweakable object from the list if exists.
global.api.acse.GetDebugTweakable = function(id)
    local nid = global.string.lower(id)

    if global.api.acse.tTweakables[nid] then
        return global.api.acse.tTweakables[nid]
    end

    return nil
end

-- // Shell commands support
global.api.acse.tShellCommands = {}

-- @brief splits a string by ' ' character
function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

-- @brief adds a command to the list
global.api.acse.RegisterShellCommand = function(_fn, sCmd, sDesc)
    -- global.api.debug.Trace("Creating shell command: " .. sCmd  )

    --/ make a new command
    local command = {}
    command._fn = _fn
    command._sCmd = sCmd
    command._sDesc = sDesc

    name = Split(sCmd, " ")[1]

    --/ save the tweakable
    global.api.acse.tShellCommands[name] = command
    return global.api.acse.tShellCommands[name]
end

-- @brief Removes a command from the list
global.api.acse.UnregisterShellCommand = function(tCmd)
    -- global.loadfile("acse : Removing shell command: " .. tCmd._sCmd  )
    name = Split(tCmd._sCmd, " ")[1]
    global.api.acse.tShellCommands[name] = nil
    -- global.api.debug.Trace("acse : Removed shell command " )
    return
end

-- @brief Runs a command
global.api.acse.RunShellCommand = function(sCmd)

    -- this RunShellCommand will fail until we
    --/TODO fix the sCmd string format check for command syntax
    -- and extract args from the sCmd string

	tArgs = Split(sCmd, " ")
	name = tArgs[1]
	global.table.remove(tArgs, 1)

    local cmd = global.api.acse.tShellCommands[name]
    if cmd ~= nil then

	    -- Convert Arg types
	   	tCArgs = Split(cmd._sCmd, " ")
	   	global.table.remove(tCArgs, 1)

	   	if #tArgs ~= #tCArgs then
    		global.api.debug.Trace("Wrong number of arguments")
	   	end

	   	for i, v in global.ipairs(tCArgs) do
	   		if v == "{string}" then end	-- do nothing, for SetTweakable
	   		if v == "{number}" then end	-- do nothing, for SetTweakable
	   		if v == "{float}" then tArgs[i] = global.tonumber(tArgs[i]) end
	   		if v == "{int32}" then tArgs[i] = global.tonumber(tArgs[i]) end
		   	if v == "{int64}" then tArgs[i] = global.tonumber(tArgs[i]) end
	   		local stringtoboolean={ ["true"]=true, ["false"]=false }
	   		if v == "{boolean}" then tArgs[i] = stringtoboolean[tArgs[i]] end
	   	end

        local ret = cmd._fn( api.game.GetEnvironment(), tArgs) -- Add args
    end
end



global.api.acse.Trace = function(msg)
	global.loadfile("acse :" .. msg)
end
global.api.acse.Error = function(msg)
	global.api.acse.Trace("acse : -Err- " .. msg)
end

--global.api.debug.Trace = global.api.acse.Trace
--global.api.debug.Error = global.api.acse.Error


-- @brief add our custom databases
ACSEDatabase.AddContentToCall = function(_tContentToCall)
	table.insert(_tContentToCall, require("Database.ACSE"))
end

