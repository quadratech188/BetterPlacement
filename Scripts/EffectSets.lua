
---@diagnostic disable: need-check-nil

---@class EffectSet

EffectSet = class()


---@param effects table
function EffectSet:initialize(effects)

    self.effectData = {}

    self.allEffectKeys = {}

    self.worldPosition = sm.vec3.zero()

    self.worldRotation = sm.quat.identity()

    for key, uuid in pairs(effects) do

        local effect = sm.effect.createEffect("ShapeRenderable")

        effect:setParameter("uuid", sm.uuid.new(uuid))
        effect:setScale(sm.vec3.new(1,1,1) * sm.construction.constants.subdivideRatio)
        
        self.effectData[key] = {["effect"] = effect, ["isPlaying"] = false}

        table.insert(self.allEffectKeys, key)
    end
end


---@param effects table
---@return EffectSet
function EffectSet.new(effects)

    local returnClass = class(EffectSet)

    returnClass:initialize(effects)

    return returnClass
end


function EffectSet:getAllEffectData()
    
    return self.effectData
end

function EffectSet:getAllEffectKeys()
    
    return self.allEffectKeys
end

function EffectSet:getEffect(key)
    
    return self.effectData[key].effect
end

function EffectSet:setTransforms(worldPosition, worldRotation)

    self.worldPosition = worldPosition

    self.worldRotation = worldRotation

    for _, effectData in pairs(self.effectData) do
        
        effectData.effect:setPosition(worldPosition)

        effectData.effect:setRotation(worldRotation)
    end
end


function EffectSet:setPosition(worldPosition)

    self.worldPosition = worldPosition

    for _, effectData in pairs(self.effectData) do
        
        effectData.effect:setPosition(worldPosition)
    end
end


function EffectSet:setRotation(worldRotation)

    self.worldRotation = worldRotation

    for _, effectData in pairs(self.effectData) do

        effectData.effect:setRotation(worldRotation)
    end
end


---Shows the given effects, hides all others
function EffectSet:showOnly(keys)

    if type(keys) ~= "table" then
        keys = {keys}
    end

    EffectSet.hideAll(self)

    for _, key in pairs(keys) do

        if self.effectData[key] == nil then
            
            goto continue
        end

        if self.effectData[key].isPlaying == false then

            self.effectData[key].effect:start()
            self.effectData[key].isPlaying = true

        end

        ::continue::
    end
end


---Shows the given effects, maintains all others
function EffectSet:show(keys)

    if type(keys) ~= "table" then
        keys = {keys}
    end

    for _, key in pairs(keys) do

        if self.effectData[key] == nil then
            
            goto continue
        end
        
        if self.effectData[key].isPlaying == false then

            self.effectData[key].effect:start()
            self.effectData[key].isPlaying = true

        end

        ::continue::
    end
end


---Hides the given effects
function EffectSet:hide(keys)

    if type(keys) ~= "table" then
        
        keys = {keys}
    end

    for _, key in pairs(keys) do
        
        self.effectData[key].effect:stop()
        self.effectData[key].isPlaying = false
    end
end


---Hides every effect
function EffectSet:hideAll()
    
    EffectSet.hide(self, self.allEffectKeys)
end