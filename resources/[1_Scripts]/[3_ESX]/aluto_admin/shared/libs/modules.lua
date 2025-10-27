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