-----------------------------------------------------------------------
--/  @file   Database.ACSELuaDatabase.lua
--/  @author My Self
--/
--/  @brief  Handles ACSE loading and database creation, it also bootstraps
--/          the missing Lua debug functionality.
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
local Vector3 = require("Vector3")
local Vector2 = require("Vector2")

global.api.debug.Trace("Database.ACSELuaDatabase.lua loaded")

-- @brief setup a custom debug/trace system to use
global.api.acse = {}
global.api.acse.versionNumber = 0.513
global.api.acse.GetACSEVersionString = function()
    return global.tostring(global.api.acse.versionNumber)
end

-- @brief logging/tracing functions
global.api.acse.Trace = function(msg)
    global.loadfile("acse :" .. msg)
end
global.api.acse.WriteLine = function(channel, msg)
    local tChannel = {'output', 'error', 'unknown'}
    global.api.debug.Trace(msg)
end
global.api.acse.Print = function(msg, color)
    global.api.debug.Trace(msg)
end
global.api.acse.Error = function(msg)
    global.api.debug.Trace("-Err- " .. msg)
end
global.api.acse.Warning = function(msg)
    global.api.debug.Trace("-Wrn- " .. msg)
end
global.api.acse.Assert = function(cond, msg)
    if cond == false then 
        global.api.debug.Trace("-Assert- " .. global.tostring(msg) )
    end
    return cond
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

-- @splits a string by spaces, respecting quoted strings
function stringSplit(text)
    local tout = {}
    local e = 0
    while true do
        local b = e+1
        b = text:find("%S",b)
        if b==nil then break end
        if text:sub(b,b)=="'" then
            e = text:find("'",b+1)
            b = b+1
        elseif text:sub(b,b)=='"' then
            e = text:find('"',b+1)
            b = b+1
        else
            e = text:find("%s",b+1)
        end
        if e==nil then e=#text+1 end
        global.table.insert(tout, text:sub(b,e-1))
    end
    return tout
end

-- @brief from &Time&Of&Day command string, returns tod
function getCommandShortName(text)
    local tout = {}
    for match in sStr:gmatch( "&(.)") do
        table.insert(tout, match:lower());
    end
    return global.table.concat(tout)
end


-- @brief adds a command to the list
global.api.acse.RegisterShellCommand = function(_fn, sCmd, sDesc)
    --/ make a new command
    local command = {}
    command._fn = _fn
    command._sCmd = global.string.gsub(sCmd,'&','') -- Remove case sensitivity marker
    command._sDesc = sDesc

    name = stringSplit(command._sCmd)[1]
    name = global.string.lower(name)

    --/ save the tweakable
    global.api.acse.tShellCommands[name] = command
    return global.api.acse.tShellCommands[name]
end

-- @brief Removes a command from the list
global.api.acse.UnregisterShellCommand = function(tCmd)
    name = stringSplit(tCmd._sCmd)[1]
    name = global.string.lower(name)
    global.api.acse.tShellCommands[name] = nil
    return
end

-- @brief Runs a command
global.api.acse.RunShellCommand = function(sCmd)

    -- this RunShellCommand will fail until we handle missing argument types (vector:3 etc..)
	tArgs = stringSplit(sCmd)
	name = tArgs[1]
    name = global.string.lower(name)
	global.table.remove(tArgs, 1)

    local cmd = global.api.acse.tShellCommands[name]
    if cmd ~= nil then

	    -- Convert Arg types
	   	tCArgs = stringSplit(cmd._sCmd)
	   	global.table.remove(tCArgs, 1)

        for i, v in global.pairs(tArgs) do
            if tCArgs[i] ~= nil then
                if global.string.match(tCArgs[i],"{string}") then end -- do nothing, for SetTweakable
                if global.string.match(tCArgs[i],"{value}") then end -- do nothing, for SetTweakable
                if global.string.match(tCArgs[i],"{float}") then tArgs[i] = global.tonumber(tArgs[i]) end
                if global.string.match(tCArgs[i],"{int32}") then tArgs[i] = global.tonumber(tArgs[i]) end
                if global.string.match(tCArgs[i],"{uint32}") then tArgs[i] = global.tonumber(tArgs[i]) end
                if global.string.match(tCArgs[i],"{uint64}") then tArgs[i] = global.tonumber(tArgs[i]) end
                -- Missing {notificationtype} {notificationcontexttype} {vector:3} and {vector:2}
                -- also missing optional args []
                local stringtoboolean={ ["true"]=true, ["false"]=false }
                if global.string.match(tCArgs[i],"{boolean}") then tArgs[i] = stringtoboolean[tArgs[i]] end
            end
        end

        -- Some commands will try to print/dump into the environment.output stream, it just needs 
        -- to be initialised for the game not crash
        local tEnv  = api.game.GetEnvironment()
        tEnv.output = 1
        tEnv.error  = 2

        local ret   = cmd._fn( api.game.GetEnvironment(), tArgs) -- Add args
    end
end



global.api.acseentity = {}
global.api.acseentity.rawFindPrefab = global.api.entity.FindPrefab
global.api.acseentity.rawCompilePrefab = global.api.entity.CompilePrefab
global.api.acseentity.rawInstantiatePrefab = global.api.entity.InstantiatePrefab
global.api.acseentity.rawAddComponentsToEntity = global.api.entity.AddComponentsToEntity

global.api.acseentity.FindPrefab = function(sPrefab)
    global.api.debug.Trace("*** entity.FindPrefab func called with " .. sPrefab)
    return global.api.acseentity.rawFindPrefab(sPrefab)
end
global.api.acseentity.CompilePrefab = function(tPrefab, sPrefab)
    global.api.debug.Trace("*** entity.CompilePrefab func called with " .. sPrefab)
    return global.api.acseentity.rawCompilePrefab(tPrefab, sPrefab)
end
global.api.acseentity.InstantiatePrefab = function(sPrefab, arg1, arg2, arg3, arg4, arg5, arg6)

    if sPrefab == "PhysicsWorld" then
        local GameDatabase = require("Database.GameDatabase")
        if GameDatabase.GetLuaPrefabs then
            for _sName, _tParams in pairs( GameDatabase.GetLuaPrefabs() ) do
                api.debug.Trace("ACSE compiling prefab: " .. global.tostring(_sName))
                local cPrefab = global.api.entity.CompilePrefab(_tParams, _sName)
                if cPrefab == nil then
                    api.debug.Trace("ACSE error compiling prefab: " .. _sName)
                end
            end
        end
    end


    local entityId = global.api.acseentity.rawInstantiatePrefab(sPrefab, arg1, arg2, arg3, arg4, arg5, arg6)
    global.api.debug.Trace("InstantitePrefab() of " .. sPrefab .. " with entityId : " .. entityId)
    return entityId
end
global.api.acseentity.AddComponentsToEntity = function(nEntityId, tComponents)
    local ret = global.api.acseentity.rawAddComponentsToEntity(nEntityId, tComponents)
    global.api.debug.Trace(
        "*** entity.AddComponentsToEntity " ..
            type(nEntityId) .. " " .. type(tComponents) .. " " .. type(ret) .. " "
    )
end

global.api.entity = global.setmetatable(global.api.acseentity, {__index = global.api.entity})
global.api.debug.Trace("+ api.entity patched")






-- @brief add our custom databases
ACSEDatabase.AddContentToCall = function(_tContentToCall)
	table.insert(_tContentToCall, require("Database.ACSE"))
end

