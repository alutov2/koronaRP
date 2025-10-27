--[[ EventBase Class ]]--
--- @class EventBase
EventBase = {}
local __instance = {
    __index = EventBase,
    __type = "EventBase"
} -- Metatable for instances

--- Return a new instance of EventBase.
---
--- @return EventBase
function EventBase.New()
    local self = setmetatable({}, __instance)

    self.listeners = {}

    return self
end

-- remove listener without mutating preventing us from emitting in reversal order or doing mutex way
function EventBase:removeListener(name, fn)
    if not self.listeners[name] then
        return
    end

    local listeners = self.listeners[name]
    local _listeners, _count = { idTracker = listeners.idTracker }, 0

    for i = 1, #listeners do
        local listener = listeners[i]

        if listener.fn ~= fn then
            _count += 1
            _listeners[_count] = listener
        end
    end

    self.listeners[name] = _listeners

    return self
end

function EventBase:removeListeners(name)
    self.listeners[name] = nil
    return self
end

function EventBase:removeAllListeners()
    self.listeners = {}
    return self
end

local function eventBaseOnInternal(self, name, fn)
    local listeners = self.listeners[name]
    if not listeners then
        listeners = { idTracker = 0 }
        self.listeners[name] = listeners
    end

    listeners.idTracker = listeners.idTracker < 0xFFFF and listeners.idTracker + 1 or 1
    local id = listeners.idTracker

    local listener = { id = id, fn = fn }
    listeners[#listeners + 1] = listener

    return listener
end

function EventBase:on(name, fn)
    eventBaseOnInternal(self, name, fn)
    return self
end

function EventBase:once(name, fn)
    eventBaseOnInternal(self, name, fn).once = true
    return self
end

function EventBase:emitSync(name, ...)
    if not self.listeners[name] then
        return
    end

    local listeners = self.listeners[name]

    for i = 1, #listeners do
        local listener = listeners[i]

        if listener.once then
            self:removeListener(name, listener.fn)
        end

        listener.fn(...)
    end

    return self
end

local function removeListenersInternal(self, listeners, fns)
    local _listeners, _count = { idTracker = listeners.idTracker }, 0

    for i = 1, #listeners do
        local listener = listeners[i]

        if not fns[listener.fn] then
            _count += 1
            _listeners[_count] = listener
        end
    end

    return _listeners
end

function EventBase:emit(name, ...)
    if not self.listeners[name] then
        return
    end

    local listeners = self.listeners[name]
    local hadFnsToDelete = false
    local fnsToDelete = {}
    local args = { ... }

    for i = 1, #listeners do
        Citizen.CreateThreadNow(function()
            local listener = listeners[i]

            if listener.once then
                hadFnsToDelete = true
                fnsToDelete[listener.fn] = true
            end

            listener.fn(table.unpack(args))
        end)
    end

    if hadFnsToDelete then
        self.listeners[name] = removeListenersInternal(self, listeners, fnsToDelete)
    end

    return self
end

setmetatable(EventBase, {
    __call = function(self, ...)
        return EventBase.New(...)
    end
})

--[[ Collection Class ]]--
---@class Collection
Collection = {}
local __instance = {
    __index = Collection,
    __type = "Collection"
} -- Metatable for instances

--- Return a new instance of Collection.
---
---@param entries table
function Collection.New(entries)
    local self = setmetatable({}, __instance)

    entries = entries or {}
    local size = #entries

    local valuesByKey = {}
    local keys = {}
    local values = {}

    for i = 1, size do
        local entry = entries[i]
        local key, value = entry[1], entry[2]

        valuesByKey[key] = value
        keys[i] = key
        values[i] = value
    end

    self.__entries = entries
    self.size = size

    self.__valuesByKey = valuesByKey
    self.__keys = keys
    self.__values = values

    return self
end

function Collection:clear()
    table.wipe(self.__entries)
    self.size = 0

    table.wipe(self.__valuesByKey)
    table.wipe(self.__keys)
    table.wipe(self.__values)
end

---@param key any
function Collection:delete(key)
    if self.__valuesByKey[key] == nil then
        return false
    end

    self.size = self.size - 1

    self.__valuesByKey[key] = nil

    for i = 1, self.size do
        if self.__keys[i] == key then
            table.remove(self.__entries, i)
            table.remove(self.__keys, i)
            table.remove(self.__values, i)
            break
        end
    end

    return true
end

function Collection:entries()
    return self.__entries
end

---@param key any
function Collection:get(key)
    return self.__valuesByKey[key]
end

---@param key any
function Collection:has(key)
    return self.__valuesByKey[key] ~= nil
end

function Collection:keys()
    return self.__keys
end

---@param key any
---@param value any
function Collection:set(key, value)
    if self.__valuesByKey[key] ~= nil then
        self.__valuesByKey[key] = value

        for i = 1, self.size do
            if self.__keys[i] == key then
                self.__entries[i][2] = value
                self.__values[i] = value
                break
            end
        end
    else
        local idx = self.size + 1

        self.__entries[idx] = { key, value }

        self.__valuesByKey[key] = value
        self.__keys[idx] = key
        self.__values[idx] = value

        self.size = idx
    end
end

function Collection:values()
    return self.__values
end

---@param index any
function Collection:at(index)
    return self.__values[index]
end

---@param index any
function Collection:keyAt(index)
    return self.__keys[index]
end

if DEV then
    function Collection:__debug()
        return ('[%u], entries: %s, valuesByKey: %s, keys: %s, values: %s'):format(
            self.size,
            Utils.StringSerializer(self.__entries),
            Utils.StringSerializer(self.__valuesByKey),
            Utils.StringSerializer(self.__keys),
            Utils.StringSerializer(self.__values)
        )
    end
end

setmetatable(Collection, {
    __call = function(self, ...)
        return Collection.New(...)
    end
})

IID = {}

local IID_Factory = {}
local __instance = {
    __index = IID_Factory,
    __type = "IID_Factory"
} -- Metatable for instances

function IID.NewFactory(min, max)
    local self = setmetatable({}, __instance)
    self.min = min or 1
    self.max = max or 0xFFFF
    self.idTracker = self.min - 1
    return self
end

function IID_Factory:NextId()
    self.idTracker = self.idTracker < self.max and self.idTracker + 1 or self.min
    return self.idTracker
end

IO = {}

local LOG_LEVELS <const> = {
    FATAL = -2,
    ERROR = -1,
    WARN = 0, -- you are not supposed to go below WARN
    INFO = 1,
    DEBUG = 2,
    TRACE = 3
}

local DEFAULT_LOG_LEVEL <const> = LOG_LEVELS.INFO

local function getLogLevel()
    return GetConvarInt('seed_logLevel', DEFAULT_LOG_LEVEL)
end

if IsDuplicityVersion() and getLogLevel() == DEFAULT_LOG_LEVEL then
    SetConvar('seed_logLevel', DEFAULT_LOG_LEVEL)
end

local function formatConsoleMsg(args)
    for i = 1, #args do
        if args[i] ~= nil then
            args[i] = ("%s%s%s"):format(DefaultColor(), args[i], DefaultColor())
        end
    end

    return table.unpack(args)
end

function IO.Trace(...)
    if getLogLevel() >= LOG_LEVELS.TRACE then
        local args = { ... }
        args[1] = ("[%sTRACE%s] %s"):format(Color("Purple"), DefaultColor(), args[1])
        print(formatConsoleMsg(args))
    end
end
Trace = IO.Trace

function IO.Debug(...)
    if getLogLevel() >= LOG_LEVELS.DEBUG then
        local args = { ... }
        args[1] = ("[%sDEBUG%s] %s"):format(Color("Purple"), DefaultColor(), args[1])
        print(formatConsoleMsg(args))
    end
end
Debug = IO.Debug

function IO.Info(...)
    if getLogLevel() >= LOG_LEVELS.INFO then
        local args = { ... }
        args[1] = ("[%sINFO%s] %s"):format(Color("Cyan"), DefaultColor(), args[1])
        print(formatConsoleMsg(args))
    end
end
Info = IO.Info

function IO.Warn(...)
    if getLogLevel() >= LOG_LEVELS.WARN then
        local args = { ... }
        args[1] = ("[%sWARN%s] %s"):format(Color("Yellow"), DefaultColor(), args[1])
        print(formatConsoleMsg(args))
    end
end
Warn = IO.Warn

function IO.Error(...)
    if getLogLevel() >= LOG_LEVELS.ERROR then
        local args = { ... }
        args[1] = ("[%sERROR%s] %s"):format(Color("Red"), DefaultColor(), args[1])
        error(formatConsoleMsg(args))
    end
end
Error = IO.Error

function IO.Fatal(...)
    if getLogLevel() >= LOG_LEVELS.FATAL then
        local args = { ... }
        args[1] = ("[%sFATAL%s] %s"):format(Color("Red"), DefaultColor(), args[1])
        error(formatConsoleMsg(args))
    end
end
Fatal = IO.Fatal

--[[
	Title : Lua Module Handler
	Description : A lua Module handler created to allow modularity between a single resource // Build on top of FiveM
	Author : Korioz
]]

--[[ Module Class ]]--
--- @class Module : EventBase
local Module = {}
local __instance = {
    __index = function(t, k)
        if Module[k] then
            return Module[k]
        end

        return t:Get(k)
    end,
    __newindex = function(t, k, v)
        if type(v) == 'function' then
            rawset(t, k, v)
            return
        end

        t:Set(k, v)
    end,
    __type = "Module"
} -- Metatable for instances

--- Creates a new Module value.
---
--- @param name string
--- @return Module
function Module.New(name, path)
    local self = {}

    self.__vars__ = {}
    self.eventManager = EventBase()

    self.name = name
    self.path = path
    self.description = "Undefined"
    self.author = "Unknown"
    self.version = "1.0.0"
    self.dependencies = {}
    self.state = "uninitialized"

    setmetatable(self, __instance)

    return self
end

--- Get Module Name
---
--- @param self table
--- @return string
function Module:GetName()
    return self.name
end

--- Set Module Description
---
--- @param self table
--- @param description string
--- @return Module
function Module:Description(description)
    assert(type(description) == "string", "Module:Description expects 'description' as a 'string'")
    self.description = description
    return self
end

--- Set Module Author
---
--- @param self table
--- @param author string
--- @return Module
function Module:Author(author)
    assert(type(author) == "string", "Module:Author expects 'author' as a 'string'")
    self.author = author
    return self
end

--- Set Module Version
---
--- @param self table
--- @param version string
--- @return Module
function Module:Version(version)
    assert(type(version) == "string", "Module:Version expects 'version' as a 'string'")
    self.version = version
    return self
end

--- Add Module Dependency
---
--- @param self table
--- @param name string
--- @return Module|boolean
function Module:Dependency(name)
    assert(type(name) == "string", "Module:Dependency expects 'name' as a 'string'")
    local foundIndex = Utils.Table.IndexOf(self.dependencies, name)

    if foundIndex ~= -1 then
        IO.Warn(("Can't register Module '%s' dependency '%s' cause it's already registered"):format(self.name, name))
        return false
    end

    table.insert(self.dependencies, name)
    return self
end

--- @param self table
--- @return Module
function Module:Start()
    if self.state == "started" or self.state == "starting" then
        return self
    end

    CreateThread(function()
        while self.state == "stopping" do
            Wait(0)
        end

        self.state = "starting"
        IO.Debug(("Module '%s' starting..."):format(self.name))
        TriggerEvent(("seed:%s:start"):format(self.name))
        self.state = "started"
        TriggerEvent(("seed:%s:started"):format(self.name))
    end)

    return self
end

--- @param self table
--- @return Module
function Module:Stop()
    if self.state == "stopped" or self.state == "stopping" or self.state == "uninitialized" then
        return self
    end
end

--- @param self table
--- @param cb function
--- @return Module
function Module:OnStart(cb)
    AddEventHandler(("seed:%s:start"):format(self.name), cb)
    return self
end

--- @param self table
--- @param cb function
--- @return Module
function Module:OnStarted(cb)
    AddEventHandler(("seed:%s:started"):format(self.name), cb)
    return self
end

--- @param self table
--- @param cb function
--- @return Module
function Module:OnStop(cb)
    AddEventHandler(("seed:%s:stop"):format(self.name), cb)
    return self
end

--- @param self table
--- @param cb function
--- @return Module
function Module:OnStopped(cb)
    AddEventHandler(("seed:%s:stopped"):format(self.name), cb)
    return self
end

function Module:GetPath()
    return self.path
end

function Module:GetCfxNuiPath()
    return ("https://cfx-nui-%s/%s"):format(GetCurrentResourceName(), self:GetPath())
end

function Module:LoadDataFile(file)
    return Utils.EvalFile(GetCurrentResourceName(), ("%s/data/%s"):format(self:GetPath(), file), { vector3 = vector3, Hash = Hash })
end

function Module:EventFormatter(eventName, withoutPrefix)
    return withoutPrefix and ("%s:%s"):format(self.name, eventName) or ("seed:%s:%s"):format(self.name, eventName)
end

-- Cfx.re --
--- @param self table
--- @param threadFunction function
--- @return Module
function Module:Thread(threadFunction)
    if not threadFunction then
        IO.Error(("Module '%s' #Thread expects 'threadFunction' as a 'function'"):format(self.name))
        return self
    end

    CreateThread(threadFunction)
    return self
end

--- @param self table
--- @param threadFunction function
--- @return Module
function Module:ThreadNow(threadFunction)
    if not threadFunction then
        IO.Error(("Module '%s' #Thread expects 'threadFunction' as a 'function'"):format(self.name))
        return self
    end

    Citizen.CreateThreadNow(threadFunction)
    return self
end

--- @param self table
--- @param eventName string
--- @param fn function
--- @return Module
function Module:RemoveListener(eventName, fn)
    self.eventManager:removeListener(eventName, fn)
    return self
end

--- @param self table
--- @param eventName string
--- @return Module
function Module:RemoveListeners(eventName)
    self.eventManager:removeListeners(eventName)
    return self
end

--- @param self table
--- @param eventName string
--- @param eventRoutine function
--- @return any
function Module:On(eventName, eventRoutine)
    return self.eventManager:on(eventName, eventRoutine)
end

--- @param self table
--- @param eventName string
--- @param eventRoutine function
--- @return any
function Module:Once(eventName, eventRoutine)
    return self.eventManager:once(eventName, eventRoutine)
end

--- @param self table
--- @param eventName string
--- @return Module
function Module:EmitSync(eventName, ...)
    self.eventManager:emitSync(eventName, ...)
    return self
end

--- @param self table
--- @param eventName string
--- @return Module
function Module:Emit(eventName, ...)
    self.eventManager:emit(eventName, ...)
    return self
end

--- @param self table
--- @param eventName string
--- @param eventRoutine function
--- @return Module
function Module:OnNet(eventName, eventRoutine)
    RegisterNetEvent(self:EventFormatter(eventName), eventRoutine)
    return self
end

if IS_SERVER then
    --- @param self table
    --- @param eventName string
    --- @param playerId number
    --- @return Module
    function Module:EmitClient(eventName, playerId, ...)
        local _eventName = self:EventFormatter(eventName)
        IO.Debug("EmitClient [S->C]", _eventName, playerId)
        TriggerClientEvent(_eventName, playerId, ...)
        return self
    end

    --- @param self table
    --- @param eventName string
    --- @param playerId number
    --- @param bps number
    function Module:EmitLatentClient(eventName, playerId, bps, ...)
        local _eventName = self:EventFormatter(eventName)
        IO.Debug("EmitLatentClient [S->C]", _eventName, playerId, bps)
        TriggerLatentClientEvent(_eventName, playerId, bps, ...)
    end

    local msgpack_pack_args = msgpack.pack_args
    local strlen = string.len

    --- @param self table
    --- @param eventName string
    --- @param playersId table
    function Module:EmitClients(eventName, playersId, ...)
        local _eventName = self:EventFormatter(eventName)
        local _TriggerClientEventInternal = TriggerClientEventInternal
        local payload = msgpack_pack_args(...)
        local payloadLen = strlen(payload)

        IO.Debug("EmitClients [S->C]", _eventName, playersId)

        for i = 1, #playersId do
            _TriggerClientEventInternal(_eventName, playersId[i], payload, payloadLen)
        end
    end

    --- @param self table
    --- @param eventName string
    --- @param playersId table
    --- @param bps number
    function Module:EmitLatentClients(eventName, playersId, bps, ...)
        local _eventName = self:EventFormatter(eventName)
        local _bps = tonumber(bps)
        local _TriggerLatentClientEventInternal = TriggerLatentClientEventInternal
        local payload = msgpack_pack_args(...)
        local payloadLen = strlen(payload)

        IO.Debug("EmitLatentClients [S->C]", _eventName, playersId, bps)

        for i = 1, #playersId do
            _TriggerLatentClientEventInternal(_eventName, playersId[i], payload, payloadLen, _bps)
        end
    end

    --- @param eventName string
    --- @param cb fun(playerServerId: number, cb: function, ...)
    --- @return Module
    function Module:RegisterServerCallback(eventName, cb)
        IMPOSTEUR.RegisterServerCallback(self:EventFormatter(eventName, true), cb)
        return self
    end
else
    --- @param self table
    --- @param eventName string
    --- @return Module
    function Module:EmitServer(eventName, ...)
        local _eventName = self:EventFormatter(eventName)
        IO.Debug("EmitServer [C->S]", _eventName)
        TriggerServerEvent(_eventName, ...)
        return self
    end

    --- @param self table
    --- @param eventName string
    --- @param cb function
    --- @return Module
    function Module:TriggerServerCallback(eventName, cb, ...)
        local _eventName = self:EventFormatter(eventName, true)
        IO.Debug("TriggerServerCallback [C->S]", _eventName)
        IMPOSTEUR.TriggerServerCallback(_eventName, cb, ...)
        return self
    end
end

function Module:Get(k)
    return self.__vars__[k]
end

function Module:Set(k, v)
    self.__vars__[k] = v
end

function Module:CFG(v)
    if v == nil then
        return self:Get("CFG")
    end

    self:Set("CFG", v)
end

function Module:Destroy()
    table.wipe(self)
end

Modules = {}
Modules.ListByName = {}
Modules.List = {}

--- @param name string
--- @return Module
function Modules.Get(name)
    assert(type(name) == "string", "Modules.Get expects 'name' as a 'string'")
    local module = Modules.ListByName[name]

    if not module then
        IO.Debug(("Modules.Get / Can't get Module '%s' cause it's not registered"):format(name))
        return nil
    end

    return module
end

--- @param name string
--- @return Module
function Modules.iAm(name)
    assert(type(name) == "string", "Modules.iAm expects 'name' as a 'string'")
    local module = Modules.ListByName[name]

    if not module then
        IO.Warn(("Modules.iAm / Can't get Module '%s' cause it's not registered"):format(name))
        return nil
    end

    return module
end

iAm = Modules.iAm

function Modules.Register(name, path)
    assert(type(name) == "string", "Modules.Register expects 'name' as a 'string'")
    assert(type(path) == "string", "Modules.Register expects 'path' as a 'string'")

    if Modules.ListByName[name] then
        IO.Warn(("Modules.Register / Can't register Module '%s' cause it's already registered"):format(name))
        return nil
    end

    local module = Module.New(name, path)

    Modules.List[#Modules.List + 1] = module
    Modules.ListByName[name] = module

    IO.Debug(("Module '%s' successfully registered"):format(name))

    return module
end

function Modules.Unregister(name)
    assert(type(name) == "string", "Modules.Unregister expects 'name' as a 'string'")
    local moduleIdx = -1

    for i = 1, #Modules.List do
        if Modules.List[i].name == name then
            moduleIdx = i
            break
        end
    end

    if moduleIdx == -1 then
        IO.Warn(("Modules.Unregister / Can't unregister Module '%s' cause it's not registered"):format(name))
        return false
    end

    table.remove(Modules.List, moduleIdx)
    Modules.ListByName[name] = nil

    local module = Modules.List[moduleIdx]
    module:Destroy()
    IO.Debug(("Module '%s' successfully unregistered"):format(name))

    return true
end

function Modules.GetList()
    return Modules.List
end

setmetatable(Modules, {
    __call = function(self, ...)
        return Modules.Register(...)
    end
})

--[[
	Title : Utils Functions
	Description : Extends lua possibilites and allow dumb people to stop redundancy
	Author : Korioz & SmallDick N'gadi
]]

Utils = {}
Utils.String = {}
Utils.Math = {}
Utils.Table = {}

local baseSets = { "number", "upper", "lower" }

local charsets = {
    number = {},
    upper = {},
    lower = {},
    base58 = {},
    readableId = {}
}

for i = 48, 57 do charsets.number[#charsets.number + 1] = string.char(i) end
for i = 65, 90 do charsets.upper[#charsets.upper + 1] = string.char(i) end
for i = 97, 122 do charsets.lower[#charsets.lower + 1] = string.char(i) end

do
    local base58 <const> = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    for i = 1, #base58 do charsets.base58[i] = base58:sub(i, i) end
end

do
    local readableId <const> = "123456789ABCDEFGHJKLMNOPQRSTUVWXYZ"
    for i = 1, #readableId do charsets.readableId[i] = readableId:sub(i, i) end
end

function Utils.EvalFile(resource, file, env)
    env = env or {}
    env._G = env

    local code = LoadResourceFile(resource, file)
    load(code, code, "t", env)()

    return env
end

function Utils.LoadJsonFile(resource, file)
    local jsonData = LoadResourceFile(resource, file)
    return json.decode(jsonData)
end

function Utils.Vector(...)
    local args = { ... }

    if #args > 0 then
        if type(args[1]) == "vector3" then
            return args[1]
        end

        if type(args[1]) == "table" then
            return vector3(args[1].x, args[1].y, args[1].z)
        end

        if type(args[1]) == "number" and type(args[2]) == "number" and type(args[3]) == "number" then
            return vector3(args[1], args[2], args[3])
        end
    end

    return vector3(0.0, 0.0, 0.0)
end

function Utils.RGB(value)
    return value.r, value.g, value.b
end

function Utils.RGBA(value)
    return value.r, value.g, value.b, value.a
end

function Utils.HexToRGB(hex)
    hex = hex:gsub('#', '')

    if hex:len() == 3 then
        return tonumber(hex:sub(1, 1), 16) * 17, tonumber(hex:sub(2, 2), 16) * 17, tonumber(hex:sub(3, 3), 16) * 17
    elseif hex:len() == 6 then
        return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
    end

    return 0, 0, 0
end

function Utils.RGBToHex(r, g, b)
    return ('#%02x%02x%02x'):format(r, g, b)
end

-- no subdomain will default to true
-- true allow any subdomain or none, false disallow any subdomain
-- a string subdomain will force the url to contain it
function Utils.IsValidUrl(url, protocol, domain, subdomain)
    protocol = ('%s://'):format(protocol)
    local protocolLen = protocol:len()
    if not url or url:sub(1, protocolLen) ~= protocol then
        return false
    end

    local nextPos = protocolLen + 1

    if type(subdomain) == 'string' then
        subdomain = ('%s.'):format(subdomain)
        local subdomainLen = subdomain:len()
        if url:sub(nextPos, (nextPos - 1) + subdomainLen) ~= subdomain then
            return false
        end

        nextPos = nextPos + subdomainLen

        local domainStartPos = url:find(('%s/'):format(domain), nextPos)
        if not domainStartPos or domainStartPos - nextPos ~= 0 then
            return false
        end
    else
        if subdomain == nil then
            subdomain = true
        end

        local domainStartPos = url:find(('%s/'):format(domain), nextPos)
        if not domainStartPos then
            return false
        end

        if domainStartPos > nextPos then
            if not subdomain then
                return false
            end

            local possibleSubdomain = url:sub(nextPos, domainStartPos - 1)
            if not possibleSubdomain then
                return false
            end

            nextPos = nextPos + possibleSubdomain:len()
        end

        if domainStartPos - nextPos ~= 0 then
            return false
        end
    end

    return true
end

function Utils.String.IsEmpty(s)
    return type(s) ~= "string" or s:fullTrim() == ""
end

--@table customSets = { "number" | "upper" | "lower" }
function Utils.String.GetRandom(length, customSets, skipRandom)
    if not skipRandom then
        math.randomseed(GetGameTimer())
        math.random()
        math.random()
    end

    if length > 0 then
        local setsSelected = customSets or baseSets
        local setSelected = charsets[setsSelected[#setsSelected == 1 and 1 or math.random(1, #setsSelected)]]
        return Utils.String.GetRandom(length - 1, customSets, true) .. setSelected[math.random(1, #setSelected)]
    end

    return ""
end

function Utils.String.Trim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end

function Utils.String.FullTrim(s)
    local res = s:gsub("%s", "")

    if res == "" then
        return ""
    end
end

function Utils.String.Sanitize(s)
    local res, count = s:gsub("[^\32-\126]", "")

    if count > 0 then
        local trimmedRes = res:gsub("%s", "")

        if trimmedRes == "" then
            return ""
        end
    end

    return res
end

function Utils.String.Split(s, sep)
    local t = {}

    for str in s:gmatch(('([^%s]+)'):format(sep or '%s')) do
        t[#t + 1] = str
    end

    return t
end

function Utils.String.UpperFirst(s)
    return s:gsub("^%l", string.upper)
end

function Utils.String.LowerFirst(s)
    return s:gsub("^%u", string.lower)
end

function Utils.String.RFind(s, pattern, pos)
    pos = pos or #s
    s = s:sub(1, pos):reverse()
    local idx = s:find(pattern)

    if not idx then
        return nil
    end

    return #s - idx + 1
end

function Utils.String.StartsWith(s, prefix)
    return s:sub(1, #prefix) == prefix
end

function Utils.String.EndsWith(s, suffix)
    return s:sub(-#suffix) == suffix
end

--[[ STRING LIBRARY EXTENSION ]]--
for funcName, func in pairs(Utils.String) do
    string[Utils.String.LowerFirst(funcName)] = func
end

function Utils.Math.Round(value, numDecimal)
    if math.type(value) ~= "float" then
        value = value + 0.0
    end

    if type(value) == "vector2" then
        return vector2(Utils.Math.Round(value.x, numDecimal), Utils.Math.Round(value.y, numDecimal))
    end

    if type(value) == "vector3" then
        return vector3(Utils.Math.Round(value.x, numDecimal), Utils.Math.Round(value.y, numDecimal), Utils.Math.Round(value.z, numDecimal))
    end

    if type(value) == "vector4" then
        return vector4(Utils.Math.Round(value.x, numDecimal), Utils.Math.Round(value.y, numDecimal), Utils.Math.Round(value.z, numDecimal), Utils.Math.Round(value.w, numDecimal))
    end

    if type(value) == "quat" then
        return quat(Utils.Math.Round(value.w, numDecimal), Utils.Math.Round(value.x, numDecimal), Utils.Math.Round(value.y, numDecimal), Utils.Math.Round(value.z, numDecimal))
    end

    if numDecimal then
        local power = 10 ^ numDecimal
        return math.floor((value * power) + 0.5) / power
    end

    return math.floor(value + 0.5)
end

function Utils.Math.RoundVector(value, decimal)
    decimal = decimal or 1
    return vector3(Utils.Math.Round(value.x, decimal), Utils.Math.Round(value.y, decimal), Utils.Math.Round(value.z, decimal))
end

function Utils.Math.CenterOfVectors(vectors)
    local sum = vec3(0)

    if not vectors or #vectors == 0 then
        return sum
    end

    for i = 1, #vectors do
        sum += vectors[i]
    end

    return sum / #vectors
end

function Utils.Math.GroupDigits(value)
    local left, num, right = string.match(value, "^([^%d]*%d)(%d*)(.-)$")
    return left .. (num:reverse():gsub("(%d%d%d)", "%1" .. i18n('locale_digit_grouping_symbol')):reverse()) .. right
end

function Utils.Math.LimitWithinRange(num, min, max)
    return math.min(math.max(num, min or -0x7FFFFFFF), max or 0x7FFFFFFF)
end

function Utils.Math.RotationToDirection(rotation)
    local adjustedRotation = vec3((math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
    return vec3(-math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.sin(adjustedRotation.x))
end

function Utils.Math.RotAnglesToVec(rot)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function isPointInTriangle(point, triangle)
    local p0, p1, p2 = triangle[1], triangle[2], triangle[3]
    local p0X, p0Y, p1X, p1Y, p2X, p2Y = p0.x, p0.y, p1.x, p1.y, p2.x, p2.y
    local pointX, pointY = point.x, point.y

    local area = 0.5 * (-p1Y * p2X + p0Y * (-p1X + p2X) + p0X * (p1Y - p2Y) + p1X * p2Y)

    local s = 1 / (2 * area) * (p0Y * p2X - p0X * p2Y + (p2Y - p0Y) * pointX + (p0X - p2X) * pointY)
    local t = 1 / (2 * area) * (p0X * p1Y - p0Y * p1X + (p0Y - p1Y) * pointX + (p1X - p0X) * pointY)

    local orientation = (p1X - p0X) * (p2Y - p0Y) - (p2X - p0X) * (p1Y - p0Y)
    if orientation < 0 then p1, p2 = p2, p1 end

    return s >= 0 and t >= 0 and s + t <= 1
end

local function isVertexEar(prevVertex, currentVertex, nextVertex, vertices)
    local triangle = { prevVertex, currentVertex, nextVertex }

    for i = 1, #vertices do
        local vertex = vertices[i]

        if vertex ~= prevVertex and vertex ~= currentVertex and vertex ~= nextVertex then
            if isPointInTriangle(vertex, triangle) then
                return false
            end
        end
    end

    return true
end

function Utils.Math.EarClipping(polygon, inverted)
    local triangles = {}
    local vertices = {}
    local numVertices = #polygon

    for i = 1, numVertices do vertices[i] = polygon[i] end

    while numVertices >= 3 do
        for i = 1, numVertices do
            local prevIndex = (i - 2) % numVertices + 1
            local currentIndex = (i - 1) % numVertices + 1
            local nextIndex = i % numVertices + 1
            local prevVertex = vertices[prevIndex]
            local currentVertex = vertices[currentIndex]
            local nextVertex = vertices[nextIndex]
            local isEar = isVertexEar(prevVertex, currentVertex, nextVertex, vertices)

            if isEar then
                local triangle = { prevVertex, inverted and nextVertex or currentVertex, inverted and currentVertex or nextVertex } -- Inversion de l'ordre des sommets
                triangles[#triangles + 1] = triangle
                table.remove(vertices, currentIndex)
                numVertices = numVertices - 1
                break
            end
        end
    end

    return triangles
end

function Utils.Math.IsPointInPolygon(p, points)
    local pointsLen = #points
    local wn = 0
    local pX, pY = p.x, p.y

    for i = 1, pointsLen do
        local a = points[i]
        local bIdx = (i + 1) % (pointsLen + 1)
        bIdx = bIdx == 0 and 1 or bIdx
        local b = points[bIdx]

        if a.y <= pY then
            if b.y > pY and ((b.x - a.x) * (pY - a.y) - (pX - a.x) * (b.y - a.y)) > 0 then
                wn = wn + 1
            end
        elseif b.y <= pY and ((b.x - a.x) * (pY - a.y) - (pX - a.x) * (b.y - a.y)) < 0 then
            wn = wn - 1
        end
    end

    return wn ~= 0
end

function Utils.Math.CoordsToReadableString(coords, noAxis)
    if noAxis then
        return ('%.2f, %.2f, %.2f'):format(coords.x, coords.y, coords.z)
    end

    return ('X: %.2f, Y: %.2f, Z: %.2f'):format(coords.x, coords.y, coords.z)
end

--[[Purpose: Give the heading to apply to first param to look
    to second param--]]
---@param fromCoords Vector3
---@param toCoords Vector3
function Utils.Math.GetHeadingForCoords(fromCoords, toCoords)
    local direction = toCoords - fromCoords

    local angle = math.atan(direction.y, direction.x)
    local heading = (angle * 180.0 / math.pi) - 90.0
    if heading < 0 then
        heading += 360.0
    end

    return heading
end

function Utils.Table.FromMinMax(min, max)
    if not min then
        return
    end

    if not max then
        max = min
        min = 1
    end

    local t = { }

    for i = min, max do
        t[#t + 1] = tostring(i)
    end

    return t
end

function Utils.Table.Has(t, value, key)
    if key then
        for i = 1, #t do
            if t[i][key] == value then
                return true
            end
        end
    else
        for i = 1, #t do
            if t[i] == value then
                return true
            end
        end
    end

    return false
end

function Utils.Table.Length(t)
    local count = 0

    for _ in pairs(t) do
        count += 1
    end

    return count
end

function Utils.Table.Set(t)
    local set = {}

    for i = 1, #t do
        set[t[i]] = true
    end

    return set
end

function Utils.Table.IndexOf(t, value)
    for i = 1, #t do
        if t[i] == value then
            return i
        end
    end

    return -1
end

function Utils.Table.LastIndexOf(t, value)
    for i = #t, 1, -1 do
        if t[i] == value then
            return i
        end
    end

    return -1
end

function Utils.Table.Find(t, cb)
    for i = 1, #t do
        if cb(t[i]) then
            return t[i]
        end
    end

    return nil
end

function Utils.Table.FindIndex(t, cb)
    for i = 1, #t do
        if cb(t[i]) then
            return i
        end
    end

    return -1
end

function Utils.Table.Filter(t, cb)
    local newT = {}

    for i = 1, #t do
        if cb(t[i]) then
            newT[#newT + 1] = t[i]
        end
    end

    return newT
end

function Utils.Table.Map(t, cb)
    local newT = {}

    for i = 1, #t do
        newT[i] = cb(t[i], i)
    end

    return newT
end

function Utils.Table.Reverse(t)
    local newT = {}

    if #t > 0 then
        for i = #t, 1, -1 do
            newT[#newT + 1] = t[i]
        end
    end

    return newT
end

function Utils.Table.IClone(t, withoutMeta)
    if type(t) ~= 'table' then
        return t
    end

    local newT = {}

    for i = 1, #t do
        if type(t[i]) == 'table' then
            newT[i] = Utils.Table.Clone(t[i])
        else
            newT[i] = t[i]
        end
    end

    if not withoutMeta then
        setmetatable(newT, getmetatable(t))
    end

    return newT
end

function Utils.Table.Clone(t, withoutMeta)
    if type(t) ~= "table" then
        return t
    end

    local newT = table.clone(t)

    if not withoutMeta then
        setmetatable(newT, getmetatable(t))
    end

    return newT
end

function Utils.Table.DeepClone(t)
    local newT = {}

    for k, v in pairs(t) do
        if type(v) == 'table' then
            v = Utils.Table.DeepClone(v)
        end

        newT[k] = v
    end

    return newT
end

function Utils.Table.Concat(t, ...)
    local args = { ... }
    local newT = Utils.Table.Clone(t)

    for i = 1, #args do
        local otherT = args[i]

        for j = 1, #otherT do
            newT[#newT + 1] = otherT[j]
        end
    end

    return newT
end

function Utils.Table.Join(t, sep)
    sep = sep or ","
    local str = ''

    for i = 1, #t do
        if i > 1 then
            str = str .. sep
        end

        str = str .. t[i]
    end

    return str
end

function Utils.Table.Sort(t, order)
    local keys = {}

    for k, _ in pairs(t) do
        keys[#keys + 1] = k
    end

    if order then
        table.sort(keys, function(a, b)
            return order(t, a, b)
        end)
    else
        table.sort(keys)
    end

    local i = 0

    return function()
        i += 1

        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function Utils.Table.Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function Utils.Table.PairsByKeys(t, f)
    local a = {}

    for n in pairs(t) do
        a[#a + 1] = n
    end

    table.sort(a, f)
    local i = 0

    local iter = function()
        i += 1

        if a[i] then
            return a[i], t[a[i]]
        end

        return nil
    end

    return iter
end

function Utils.PackArgs(...)
    local args = {...}
    local argsLen = #args
    local argsPayload
    if argsLen > 0 then
        argsPayload = { L = argsLen }
        for i = 1, argsLen do
            argsPayload[tostring(i)] = args[i]
        end
    end
    return argsPayload
end

function Utils.UnpackArgs(argsPayload, dontUnpack)
    local args = {}
    for i = 1, argsPayload.L do
        args[i] = argsPayload[tostring(i)]
    end
    if dontUnpack then
        return args
    end
    return table.unpack(args)
end

--[[
function Utils.Table.Dump(table, nb)
	if nb == nil then
		nb = 0
	end

	if type(table) == "table" then
		local s = ""

		for i = 1, nb + 1 do
			s = s .. "    "
		end

		s = "{\n"

		for k, v in pairs(table) do
			if type(k) ~= "number" then
				k = "'" .. k .. "'"
			end

			for i = 1, nb do
				s = s .. "    "
			end

			s = s .. "[" .. k .. "] = " .. Utils.Table.Dump(v, nb + 1) .. ",\n"
		end

		for i = 1, nb do
			s = s .. "    "
		end

		return s .. "}"
	else
		return tostring(table)
	end
end
]]

do
    local toStringTypeValues = {
        ["number"] = true,
        ["boolean"] = true,
        ["vector2"] = true,
        ["vector3"] = true,
        ["vector4"] = true,
        ["quat"] = true,
        ["function"] = true
    }

    local stringSerializer = nil

    function Utils.StringSerializer(val, name, spaceIndent, depth, ignoredValues)
        depth = depth or 0

        local tmp = string.rep(" ", depth)
        local typeVal = rawtype(val)

        if name then
            tmp = tmp .. name .. " = "
        end

        if typeVal == "table" then
            spaceIndent = spaceIndent or 2
            ignoredValues = ignoredValues or {}

            local valSize = 0
            local newIgnored = { [val] = true }

            for k, v in pairs(val) do
                if not ignoredValues[v] and k ~= "parent" then
                    valSize = valSize + 1

                    if type(v) == "table" then
                        newIgnored[v] = true
                    end
                end
            end

            for k in pairs(ignoredValues) do
                newIgnored[k] = true
            end

            if valSize < 1 then
                tmp = tmp .. "{}"
            else
                tmp = tmp .. "{\n"
                local iteration = 0

                for k, v in pairs(val) do
                    if not ignoredValues[v] and k ~= "parent" then
                        iteration = iteration + 1
                        tmp = tmp .. stringSerializer(v, tostring(k), spaceIndent, depth + spaceIndent, newIgnored) .. (iteration < valSize and "," or "") .. "\n"
                    end
                end

                tmp = tmp .. string.rep(" ", depth) .. "}"
            end
        elseif toStringTypeValues[typeVal] then
            tmp = tmp .. tostring(val)
        elseif typeVal == "string" then
            tmp = tmp .. string.format("%q", val)
        else
            tmp = tmp .. "'[inserializeable datatype:" .. typeVal .. "]'"
        end

        return tmp
    end

    stringSerializer = Utils.StringSerializer
end

function Utils.GetDateFromString(dateStr) -- only supports dd/mm/yyyy
    local date = {}
    local day, month, year = dateStr:match("(%d+)[/](%d+)[/](%d+)")

    date.day = tonumber(day)
    date.month = tonumber(month)
    date.year = tonumber(year)

    return date
end

function Utils.GetBitFromBitPos(bits, bitPos)
    return 1 << (bitPos - 1)
end

function Utils.IsBitSet(bits, bit)
    return (bits & bit) == bit
end

function Utils.SetBit(bits, bit, state)
    return state and bits | bit or bits & ~bit
end

---@param x number
---@param y number
---@param z number
function Utils.CoordsToUniqueId(x, y, z)
    return ('%i:%i:%i'):format(math.floor(x), math.floor(y), math.floor(z))
end

packagesLoaded = {}

function require(filePath, packageName)
    if packageName == nil then
        error("lua function 'require(" .. tostring(filePath) .. ")' is not implemented, you can try the alias needing 2 arguments")
    end
    if packagesLoaded[packageName] ~= nil then
        return packagesLoaded[packageName]
    end

    local code = LoadResourceFile(CURRENT_RESOURCE, filePath .. "/" .. packageName) -- lib/foo.bar

    if code == nil then
        code = LoadResourceFile(CURRENT_RESOURCE, filePath .. "/" .. packageName .. ".lua") -- lib/foo.bar.lua
    end

    if code == nil then
        error("Module " .. packageName .. " not found")
        return nil
    end

    local stub = "local __STUB = function(...)\n" .. code .. "\nend\n" .. "return __STUB('" .. packageName .. "')"
    local package = load(stub)()
    packagesLoaded[packageName] = package

    return package
end

function booleanToString(v)
    return v and 'true' or 'false'
end

function floatToString(v, maxDecimals)
    local formattedString = (("%." .. (maxDecimals or 2) .. "f"):format(v)):gsub("[.]", ",")
    return formattedString
end

function toboolean(v)
    return (type(v) == "boolean" and v) or (type(v) == "number" and v == 1) or (type(v) == "string" and (v == "true" or v == "1"))
end

tobool = toboolean

tointeger = math.tointeger
toint = tointeger

function tofloat(v)
    v = tonumber(v)
    return (v and (math.type(v) == "integer" and v + 0.0) or (math.type(v) == "float" and v)) or 0.0
end

function totable(v)
    if type(v) == "table" then
        return v
    elseif type(v) == "string" then
        return json.decode(v)
    elseif type(v) == "vector3" then
        return { x = v.x, y = v.y, z = v.z }
    end

    return {}
end

function vecToArray(v)
    if type(v) == "vector2" then
        return { v.x, v.y }
    elseif type(v) == "vector3" then
        return { v.x, v.y, v.z }
    elseif type(v) == "vector4" then
        return { v.x, v.y, v.z, v.w }
    end

    return nil
end

function arrayToVec(v)
    if type(v) == "table" then
        return vec(table.unpack(v))
    end

    return nil
end

function ujoaat(v)
    if type(v) ~= 'number' then
        v = GetHashKey(v)
    end

    return v < 0 and (v & 0xFFFFFFFF) or v
end

function normalizeHash(hash)
    return (hash & 0x80000000) == 0x80000000 and hash | 0xFFFFFFFF00000000 or hash
end

local origType = type
rawtype = origType
type = function(v)
    local res = origType(v)
    if res == 'table' then
        local meta = getmetatable(v) -- result could not be a table as of __metatable metamethod
        if origType(meta) == 'table' and meta.__type then
            return meta.__type
        end
    end
    return res
end

function isInstance(v)
    if origType(v) == 'table' then
        local meta = getmetatable(v) -- result could not be a table as of __metatable metamethod
        return origType(meta) == 'table' and meta.__type
    end
    return false
end