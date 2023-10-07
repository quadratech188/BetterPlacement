
---@class NetworkRelay

NetworkRelay = class()


---Creates a new NetworkRelay. this class requires a parent (ToolClass, ShapeClass etc).
---@param parent ShapeClass|ToolClass|CharacterClass|UnitClass|PlayerClass|HarvestableClass|GameClass|WorldClass|ScriptableObjectClass
---@return NetworkRelay
function NetworkRelay.new(parent)
    
    local returnClass = class(NetworkRelay)

    returnClass:initialize(parent)

    return returnClass
end

---Initializes a NetworkRelay. this class requires a parent (ToolClass, ShapeClass etc).
---@param parent ShapeClass|ToolClass|CharacterClass|UnitClass|PlayerClass|HarvestableClass|GameClass|WorldClass|ScriptableObjectClass
---@return NetworkRelay
function NetworkRelay:initialize(parent)
    
    self.parent = parent

    self.network = self.parent.network

    UsefulUtils.linkCallback(self.parent, "sendToClient_cl", self.sendToClient_cl, -1)
    UsefulUtils.linkCallback(self.parent, "sendToServer_cl", self.sendToServer_cl, -1)
end

-- Serverside

---Send data to the given client class
---@param client Player The client to which the callback is sent
---@param callback string
---@param data any
---@param class any
function NetworkRelay:sendToClient(client, callback, data, class)
    
    self.network:sendToClient(client, "sendToClient_cl", {callback, data, class})
end

-- Clientside

---@param _data any
function NetworkRelay:sendToClient_cl(_data)
    
    local class = _data[3]
    local data = _data[2]
    local callback = _data[1]

    class[callback](class, data)
end

-- Clientside

---Send data to the given server class
---@param callback string
---@param data any
---@param class any
function NetworkRelay:sendToServer(callback, data, class)
    
    self.network:sendToServer("sendToServer_cl", {callback, data, tostring(class)})
end

-- Serverside

---@param _data any
function NetworkRelay:sendToServer_cl(data)
    
    print(data)
end

