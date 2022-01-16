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
local type = global.type
local require = global.require
local ACSEDatabase = module(...)
local Vector3 = require("Vector3")
local Vector2 = require("Vector2")

global.api.debug.Trace("Database.ACSELuaDatabase.lua loaded")

-- @brief ACSE table setup
global.api.acse = {}
global.api.acse.versionNumber = 0.623
global.api.acse.GetACSEVersionString = function()
    return global.tostring(global.api.acse.versionNumber)
end

-- @brief ACSE dev file system used by loadfile, loadmodule, importmodule functions
global.api.acse.devpath = "dev/Lua/"
global.api.acse.devmodule = global.loadfile("dev/Lua/init.lua")

global.api.acse.GetACSEDevPath = function()
    return global.tostring(global.api.acse.devpath)
end
global.api.acse.SetACSEDevPath = function(_sPath)
    global.api.acse.devpath = _sPath
end

-- @brief setup a custom debug/trace system to use
global.api.acsedebug = {}

-- @brief logging/tracing functions. Export Trace as a CreateFile call for Frida console hooking
global.api.acsedebug.Trace = function(msg)
    global.loadfile("acse :" .. msg)
end
global.api.acsedebug.WriteLine = function(channel, msg)
    local tChannel = {"output", "error", "unknown"}
    global.api.debug.Trace(msg)
end
global.api.acsedebug.Print = function(msg, color)
    global.api.debug.Trace(msg)
end
global.api.acsedebug.Error = function(msg)
    global.api.debug.Trace("-Err- " .. msg)
end
global.api.acsedebug.Warning = function(msg)
    global.api.debug.Trace("-Wrn- " .. msg)
end
global.api.acsedebug.Assert = function(cond, msg)
    if cond == false then
        global.api.debug.Trace("-Assert- " .. global.tostring(msg))
    end
    return cond
end

-- Tweakable support
global.api.acsedebug.tTweakables = {}

global.api.acsedebug.GetTweakables = function()
    return global.api.acsedebug.tTweakables
end

--/@brief make our own tweakables manager
global.api.acsedebug.CreateDebugTweakable = function(ttype, id, arg1, arg2, arg3, arg4)
    --/ Tweakable types: 22 boolean, 11 float, 8 integer64, 7 integer32
    --/ tweakable exists, return the original one

    local nid = global.string.lower(id)

    if global.api.acsedebug.tTweakables[nid] then
        return global.api.acsedebug.tTweakables[nid]
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
    global.api.acsedebug.tTweakables[nid] = tweakable
    return tweakable
end

--/@brief retrieve a tweakable object from the list if exists.
global.api.acsedebug.GetDebugTweakable = function(id)
    local nid = global.string.lower(id)

    if global.api.acsedebug.tTweakables[nid] then
        return global.api.acsedebug.tTweakables[nid]
    end

    return nil
end

-- // Shell commands support
global.api.acsedebug.tShellCommands = {}
global.api.acsedebug.tShellCommandsShort = {}

-- @brief splits a string by ' ' character
function Split(s, delimiter)
    result = {}
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-- @splits a string by spaces, respecting quoted strings
function stringSplit(text)
    local tout = {}
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

-- @brief adds a command to the list
global.api.acsedebug.RegisterShellCommand = function(_fn, sCmd, sDesc)
    --/ Save the short command version
    local shortcut = getCommandShortName(sCmd)

    --/ make a new command
    local command = {}
    command._fn = _fn
    command._sCmd = global.string.gsub(sCmd, "&", "") -- Remove case sensitivity marker
    command._sDesc = sDesc

    name = stringSplit(command._sCmd)[1]
    name = global.string.lower(name)

    --/ save the command and shortcut version
    global.api.acsedebug.tShellCommands[name] = command
    if shortcut then
        global.api.acsedebug.tShellCommandsShort[shortcut] = name
    end

    return global.api.acsedebug.tShellCommands[name]
end

-- @brief Removes a command from the list
global.api.acsedebug.UnregisterShellCommand = function(tCmd)
    name = stringSplit(tCmd._sCmd)[1]
    name = global.string.lower(name)
    global.api.acsedebug.tShellCommands[name] = nil
    return
end

-- @brief Runs a command
global.api.acsedebug.RunShellCommand = function(sCmd)
    -- this RunShellCommand will fail until we handle missing argument types (vector:3 etc..)
    tArgs = stringSplit(sCmd)
    name = tArgs[1]
    name = global.string.lower(name)
    global.table.remove(tArgs, 1)

    name = global.api.acsedebug.tShellCommandsShort[name] or name
    local cmd = global.api.acsedebug.tShellCommands[name]

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
                    tArgs[i] = stringtoboolean[tArgs[i]]
                end
            end
        end

        -- Some commands will try to print/dump into the environment.output stream, it just needs
        -- to be initialised for the game not crash
        local tEnv = api.game.GetEnvironment()
        tEnv.output = 1
        tEnv.error = 2

        local bRet, sMsg = cmd._fn(api.game.GetEnvironment(), tArgs) 
        if bRet == false then
            global.api.debug.Trace(sMsg)
        end
    end
end

global.api.acseentity = {}
global.api.acseentity.rawFindPrefab = global.api.entity.FindPrefab
global.api.acseentity.rawCompilePrefab = global.api.entity.CompilePrefab
global.api.acseentity.rawInstantiatePrefab = global.api.entity.InstantiatePrefab
global.api.acseentity.rawAddComponentsToEntity = global.api.entity.AddComponentsToEntity

global.api.acseentity.FindPrefab = function(sPrefab)
    local tPrefab = global.api.acseentity.rawFindPrefab(sPrefab)
    -- Return recursive changes to Components StandaloneScenerySerialization
    return tPrefab
end

function tablelength(T)
    local count = 0
    for _ in global.pairs(T) do
        count = count + 1
    end
    return count
end

function groupComponents(tPrefab, tComponentNames)
    local tComponents = {}
    if tPrefab['Components'] then 
        for sName, tData in pairs(tPrefab.Components) do
            if tComponentNames[sName] ~= nil then
                tComponents[sName] = tData
                tPrefab["Components"][sName] = nil
            end
        end
    end

    if tablelength(tComponents) > 0 then
        tPrefab["Components"]["StandaloneScenerySerialisation"] = tComponents
    end
    if tPrefab["Children"] then
        for sName, tData in pairs(tPrefab["Children"]) do
            tPrefab["Children"][sName] = groupComponents(tData, tComponentNames)
        end
    end
    return tPrefab
end

global.api.acseentity.CompilePrefab = function(tPrefab, sPrefab)
    -- global.api.debug.Trace("*** entity.CompilePrefab func called with " .. sPrefab)
    -- Process recursively and move custom components to the 
    -- StandaloneScenerySerialisation component
    local GameDatabase = require("Database.GameDatabase")
    tCustomComponentNames = GameDatabase.GetLuaComponents()
    if tablelength(tCustomComponentNames) > 0 then
        tPrefab = groupComponents(tPrefab, tCustomComponentNames)
    end
    return global.api.acseentity.rawCompilePrefab(tPrefab, sPrefab)
end

global.api.acseentity.InstantiatePrefab = function(sPrefab, ...)
    --/ Physics world is the first prefab being instantiated in any game,
    --/ at this moment the entity component is ready so we will rebuild
    --/ the rest of prefabs defined by other mods. This piece in particular
    --/ will come handy for prefabs required early in the loading process.
    if sPrefab == "PhysicsWorld" then
        local GameDatabase = require("Database.GameDatabase")
        if GameDatabase.GetLuaPrefabs then
            GameDatabase.BuildLuaPrefabs()
        end
    end

    local entityId = global.api.acseentity.rawInstantiatePrefab(sPrefab, ...)
    global.api.debug.Trace(
        "Entity.InstantitePrefab() of " .. global.tostring(sPrefab) .. " with entityId : " .. entityId
    )
    return entityId
end

global.api.acseentity.AddComponentsToEntity = function(nEntityId, tComponents)
    local ret = global.api.acseentity.rawAddComponentsToEntity(nEntityId, tComponents)
    global.api.debug.Trace(
        "Entity.AddComponentsToEntity() " .. type(nEntityId) .. " " .. type(tComponents) .. " " .. type(ret) .. " "
    )
end

-- @brief add our custom databases
ACSEDatabase.AddContentToCall = function(_tContentToCall)
    table.insert(_tContentToCall, require("Database.ACSE"))
    if global.api.acse.devmodule ~= nil then 
        global.package.preload['acsedev'] = global.api.acse.devmodule
        local devmod = require('acsedev')
        global.package.preload['acsedev'] = nil
        if devmod then table.insert(_tContentToCall, devmod ) end 
    end
end
