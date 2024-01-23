-----------------------------------------------------------------------
--/  @file   Database.ACSELuaDatabase.lua
--/  @author Inaki
--/
--/  @brief  Handles ACSE loading and database creation, it also bootstraps
--/          the missing Lua debug functionality.
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local pairs = global.pairs
local ipairs = global.ipairs
local type = global.type
local require = require
local table = require("Common.tableplus")
local ACSEDatabase = module(...)
local Vector3 = require("Vector3")
local Vector2 = require("Vector2")

global.api.debug.Trace("Database.ACSELuaDatabase.lua loaded")

-- @brief ACSE table setup
global.api.acse = {}
global.api.acse.versionNumber = 0.644
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

-- @brief allow registration of gameplay settings handlers
global.api.acse._tGameSettingsRegistrations = {}
global.api.acse.RegisterGameSettingsHandler = function( fGetItems, fHandleEvent, fApplyChanges)
    local tItem = {
        fGetItems     = fGetItems,
        fHandleEvent  = fHandleEvent,
        fApplyChanges = fApplyChanges,
    }
    table.append(global.api.acse._tGameSettingsRegistrations, tItem)
    return #global.api.acse._tGameSettingsRegistrations
end
global.api.acse.UnregisterGameSettingsHandler = function(nItem)
    table.remove(global.api.acse._tGameSettingsRegistrations, nItem)
end

-- @brief allow registration of sandbox settings handlers
global.api.acse._tSandboxSettingsRegistrations = {}
global.api.acse.RegisterSandboxSettingsHandler = function( fGetItems, fHandleEvent, fApplyChanges)
    local tItem = {
        fGetItems     = fGetItems,
        fHandleEvent  = fHandleEvent,
        fApplyChanges = fApplyChanges,
    }
    table.append(global.api.acse._tSandboxSettingsRegistrations, tItem)
    return #global.api.acse._tSandboxSettingsRegistrations
end
global.api.acse.UnregisterSandboxSettingsHandler = function(nItem)
    table.remove(global.api.acse._tSandboxSettingsRegistrations, nItem)
end

-- @brief allow registration of keyboard control settings handlers
global.api.acse._tControlsSettingsRegistrations = {}
global.api.acse.RegisterControlsSettingsHandler = function( fGetItems, fHandleEvent, fApplyChanges)
    local tItem = {
        fGetItems     = fGetItems,
        fHandleEvent  = fHandleEvent,
        fApplyChanges = fApplyChanges,
    }
    table.append(global.api.acse._tControlsSettingsRegistrations, tItem)
    return #global.api.acse._tControlsSettingsRegistrations
end
global.api.acse.UnregisterControlsSettingsHandler = function(nItem)
    table.remove(global.api.acse._tControlsSettingsRegistrations, nItem)
end

-- @brief setup a custom debug/trace system to use
global.api.acsedebug = {}

-- @brief logging/tracing functions. Export Trace as a CreateFile call for Frida console hooking
-- or can be viewed with procmon file system events
global.api.acsedebug.Trace = function(msg)
    global.loadfile("acse :" .. global.tostring(msg))
end

global.api.acsedebug.WriteLine = function(channel, msg)
    local tChannel = {"output", "error", "unknown"}
    global.api.debug.Trace(global.tostring(msg))
end
global.api.acsedebug.Print = function(msg, color)
    global.api.debug.Trace(global.tostring(msg))
end
global.api.acsedebug.Error = function(msg)
    global.api.debug.Trace("-Err- " .. global.tostring(msg))
end
global.api.acsedebug.Warning = function(msg)
    global.api.debug.Trace("-Wrn- " .. global.tostring(msg))
end

global.api.acsedebug.Assert = function(cond, msg)
    if global.type(cond) == 'bool' and cond == false then
        global.api.debug.Trace("-Assert- " .. global.tostring(msg))
    end
    return cond
end

-- Tweakable support
global.api.acsedebug.tTweakables = {}

global.api.acsedebug.GetTweakables = function()
    --api.debug.Trace("GetTweakables")
    return global.api.acsedebug.tTweakables
end

--/@brief make our own tweakables manager
global.api.acsedebug.CreateDebugTweakable = function(ttype, id, arg1, arg2, arg3, arg4)
    --/ Tweakable types: 22 boolean, 11 float, 8 integer64, 7 integer32
    --/ tweakable exists, return the original one
    --api.debug.Trace("CreateDebugTweakable")

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
    --api.debug.Trace("GetDebugTweakable")

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
    --api.debug.Trace("RegisterShellCommand")
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
    --api.debug.Trace("UndergisterShellCommand")
    name = stringSplit(tCmd._sCmd)[1]
    name = global.string.lower(name)
    global.api.acsedebug.tShellCommands[name] = nil
    return
end

-- @brief Runs a command
global.api.acsedebug.RunShellCommand = function(sCmd)
    --api.debug.Trace("cmd: " .. global.tostring(_sCmd))
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
                    tArgs[i] = stringtoboolean[tArgs[i] ]
                end
            end
        end

        -- Some commands will try to print/dump into the environment.output stream, it just needs
        -- to be initialised for the game not crash
        local tEnv = api.game.GetEnvironment()
        tEnv.output = 1
        tEnv.error = 2

        local bRet, sMsg = cmd._fn(api.game.GetEnvironment(), tArgs) 
        if sMsg ~= nil then
            global.api.debug.Trace(global.tostring(sMsg))
        end
    end
end


--// 
--// Provides ACSE API component manager support
--// 
global.api.acsecomponentmanager = {}
global.api.acsecomponentmanager.rawLookupComponentManagerID = global.api.componentmanager.LookupComponentManagerID
global.api.acsecomponentmanager.rawGetComponentManagerNameFromID = global.api.componentmanager.GetComponentManagerNameFromID

global.api.acsecomponentmanager.LookupComponentManagerID = function(_sName)
    local ret = api.componentmanager.rawLookupComponentManagerID(_sName)
    if not ret then 
        ret = global.api.acsecustomcomponentmanager:GetComponentIDFromName(_sName)
    end
    return ret
end

global.api.acsecomponentmanager.GetComponentManagerNameFromID = function(_nID)
    local ret = api.componentmanager.rawGetComponentManagerNameFromID(_nID)
    if not ret then 
        ret = global.api.acsecustomcomponentmanager:GetComponentNameFromID(_nID)
    end
    return ret
end


--// 
--// Provides ACSE API entity support
--// 
global.api.acseentity = {}
global.api.acseentity.tLoadedEntities = {} -- Keep track of loaded entities for their options table
global.api.acseentity.rawFindPrefab = global.api.entity.FindPrefab
global.api.acseentity.rawCompilePrefab = global.api.entity.CompilePrefab
global.api.acseentity.rawInstantiatePrefab = global.api.entity.InstantiatePrefab
global.api.acseentity.rawAddComponentsToEntity = global.api.entity.AddComponentsToEntity
global.api.acseentity.rawRemoveComponentsFromEntity = global.api.entity.RemoveComponentsFromEntity
global.api.acseentity.rawInstantiateDesc = global.api.entity.InstantiateDesc
global.api.acseentity.rawCreateEntity = global.api.entity.CreateEntity
--global.api.acseentity.rawDestroyPrefab = global.api.entity.DestroyPrefab

--// @todo: consider adding CreateEntity and DestroyEntity hooks

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
    local ret = global.api.acseentity.rawCompilePrefab(tPrefab, sPrefab)
    if ret == nil then global.api.debug.Error("Error compiling prefab: " .. global.tostring(sPrefab)) end
    return ret
end

--/
--/ InstantiatePrefab arguments:
--/ - prefab: table, or string, or lua prefab
--/ - name: string
--/ - token: userdata generated token
--/ - transform
--/ - parent: int entity ID of parent
--/ - attach: boolean attach to parent entity, I've seen nill with parent too so nope
--/ - properties: table 
--/ - entityID: int, if not null then entity ID for this instance
--/
global.api.acseentity.InstantiatePrefab = function(sPrefab, sName, uToken, vTransform, nParent, bAttach, tProperties, nInstanceID)
    --/ Physics world is the first prefab being instantiated in any game,
    --/ at this moment the entity component is ready so we will rebuild
    --/ the rest of prefabs defined by other mods. This piece in particular
    --/ will come handy for prefabs required early in the loading process.

    --/ Game default physics entity is PhysicsWorld, however in Planet Zoo this is renamed to MainPhysicsWorld
    local sPyhsicsPrefab = 'PhysicsWorld'
    if global.api.game.GetGameName() == "Planet Zoo" then sPyhsicsPrefab = 'MainPhysicsWorld' end

    if sPrefab == sPyhsicsPrefab then
        local GameDatabase = require("Database.GameDatabase")
        if GameDatabase.BuildLuaPrefabs then
            GameDatabase.BuildLuaPrefabs()
        end
    end

    local entityId = global.api.acseentity.rawInstantiatePrefab(sPrefab, sName, uToken, vTransform, nParent, bAttach, tProperties, nInstanceID)
    if entityId then
        -- we can use the API to get the rest of the data from the Instance ID, this is used by our 
        -- custom component manager to store the tProperties data when adding components to entities
        -- based on properties.
        global.api.acseentity.tLoadedEntities[entityId] = { sPrefab = sPrefab, tProperties = tProperties}
    end

    global.api.debug.Trace(
        "Entity.InstantitePrefab() of " .. global.tostring(sPrefab) .. " with entityId : " .. entityId
    )

    return entityId
end

--// Changes are this is to instantiate a descendant of a prefab by name
--// this seems to be obsolete, replaced by the prefabs list in the world file. 
global.api.acseentity.InstantiateDesc = function(...)
    local arg = {...}
    for i,v in global.ipairs(arg) do
        global.api.debug.Trace("arg : " .. global.tostring(v))
    end

    local descResult = global.api.acseentity.rawInstantiateDesc(...)
    global.api.debug.Trace(
        "Entity.InstantiteDesc() with entityId : " .. global.tostring(descResult)
    )

    return descResult
end

global.api.acseentity.CreateEntity = function(...)
    local arg = {...}
    for i,v in global.ipairs(arg) do
        global.api.debug.Trace("arg : " .. global.tostring(v))
    end
    local entityId = global.api.acseentity.rawCreateEntity(...)
    global.api.debug.Trace(
        "Entity.CreateEntity()  with entityId : " .. global.tostring(entityId)
    )

    return entityId
end

global.api.acseentity.AddComponentsToEntity = function(nEntityId, tComponents, uToken)

    -- Modify the tComponents array to ensure we conform the standalonesceneryserialization schema
    local StandaloneScenerySerialisationID = global.api.componentmanager.LookupComponentManagerID('StandaloneScenerySerialisation')
    for _, v in global.ipairs(tComponents) do

        --/ Replace custom component IDs and rebuild the components table to use the StandaloneScenerySerialisation schema
        --/ @todo: move this to a function
        if v.id >= 10000 then
            local sName = global.api.acsecustomcomponentmanager:GetComponentNameFromID(v.id)
            if sName then
                v.id = StandaloneScenerySerialisationID
                v.tParams = { [sName]  = v.tParams }
            end
        end
    end

    return global.api.acseentity.rawAddComponentsToEntity(nEntityId, tComponents, uToken)
end

global.api.acseentity.RemoveComponentsFromEntity = function(nEntityId, tComponents, uToken)
    --global.api.debug.Trace("ComponentManager:RemoveComponentsFromEntity()")
    --global.api.debug.Trace("Entities array: " .. table.tostring(tComponents, nil, nil, nil, true))
    -- We are getting an array of IDs of components to remove, but we can't propagate these IDs to 
    -- out custom component manager because they can't have any data attached. 

    -- This loop will remove any Custom component ID and create a new table with them
    local tNewComponentsTable = {}
    local tCustomComponents   = {}
    for _, v in global.ipairs(tComponents) do
        if v >= 10000 then 
            table.append(tCustomComponents, v)
        else
            table.append(tNewComponentsTable, v)
        end
    end
    tComponents = tNewComponentsTable

    -- If we have subcomponents to handle, we remove them differently calling ourselves to the 
    -- custom controller manager. If we try using the standalonesceneryserialisation ID  
    -- we won't be able to remove any other subcomponent because the game will only propagate the call once.
    if table.count(tCustomComponents) > 0 then
        global.api.acsecustomcomponentmanager:RemoveCustomComponentsFromEntity(nEntityId, tCustomComponents, uToken)
    end

    -- dont call the original removecomponents if the final array is empty.
    return global.api.acseentity.rawRemoveComponentsFromEntity(nEntityId, tComponents, uToken)
end


--//
--// Provide debug database support
--//
global.api.acsedatabase = {}
global.api.acsedatabase.tDatabases = {} -- Keep track of databases and prepared statements
global.api.acsedatabase.rawCreateEmptyNamedDatabase = global.api.database.CreateEmptyNamedDatabase
global.api.acsedatabase.rawLoadAndNameDatabase      = global.api.database.LoadAndNameDatabase
global.api.acsedatabase.rawUnloadNamedDatabase      = global.api.database.UnloadNamedDatabase
global.api.acsedatabase.rawDiscardDatabaseResources = global.api.database.DiscardDatabaseResources
global.api.acsedatabase.rawMergeChildDatabase       = global.api.database.MergeChildDatabase

global.api.acsedatabase.CreateEmptyNamedDatabase = function(sName, ...)
    local ret = global.api.acsedatabase.rawCreateEmptyNamedDatabase(sName, ...)
    if ret then global.api.acsedatabase.tDatabases[sName] = {} end
    return ret
end

global.api.acsedatabase.LoadAndNameDatabase = function(sSymbol, sName, ...)
    local ret = global.api.acsedatabase.rawLoadAndNameDatabase(sSymbol, sName, ...)
    if ret then global.api.acsedatabase.tDatabases[sName] = {} end
    return ret
end

global.api.acsedatabase.UnloadNamedDatabase = function(sName, ...)
    local ret = global.api.acsedatabase.rawUnloadNamedDatabase(sName, ...)
    global.api.acsedatabase.tDatabases[sName] = nil
    return ret
end

--[[ Found not to be necessary
global.api.acsedatabase.DiscardDatabaseResources = function(sName, ...)
    local ret = global.api.acsedatabase.rawDiscardDatabaseResources(sName, ...)
    return ret
end

global.api.acsedatabase.MergeChildDatabase = function(sMainName, sContentName, sMergeRule)
    local ret = global.api.acsedatabase.rawMergeChildDatabase(sMainName, sContentName, sMergeRule)
    return ret
end
]]


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
