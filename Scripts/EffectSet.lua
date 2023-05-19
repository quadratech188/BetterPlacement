
---@diagnostic disable: need-check-nil

---@class SmartEffect

SmartEffect = class()


function SmartEffect.new(effectData)
    
    local returnClass = class(SmartEffect)

    returnClass:initialize(effectData)

    return returnClass
end


function SmartEffect:initialize(effectData)
    
    -- Supported: 'Effect' userdata, Custom Effect class with sufficient callbacks, uuids for ShapeRenderable effect

    if type(effectData) == "Effect" or type(effectData) == "table" then
        
        self.effect = effectData
    
    else

        self.effect = sm.effect.createEffect("ShapeRenderable")

        self.effect:setParameter("uuid", effectData)
    end

    self.isPlaying = false

    self.offsetPosition = sm.vec3.zero()

    self.offsetRotation = sm.quat.identity()

    self.offsetScale = sm.vec3.one()
end


function SmartEffect:start()
    
    if self.isPlaying == false then
        
        self.effect:start()
    end
    self.isPlaying = true
end

function SmartEffect:stop()

    if self.isPlaying == true then
        
        self.effect:stop()
    end
    self.isPlaying = false
end


function SmartEffect:updateTransforms()

    self.effect:setPosition(self.worldPosition + self.worldRotation * (self.offsetTransforms[1] * self.worldScale))

    self.effect:setRotation(self.worldRotation * self.offsetTransforms[2])

    self.effect:setScale(self.worldScale * self.offsetTransforms[3])
end


---Set offset transforms of SmartEffect (nil values are ignored)
---@param transforms table {position, rotation, scale}
function SmartEffect:setOffsetTransforms(transforms)

    if transforms[1] ~= nil then
        self.offsetPosition = transforms[1]
    end

    if transforms[2] ~= nil then
        self.offsetRotation = transforms[2]
    end

    if transforms[3] ~= nil then
        self.offsetScale = transforms[3]
    end

    self:updateTransforms()
end



---@class EffectSet

EffectSet = class()


---@param effects table
function EffectSet:initialize(effects)

    self.effectData = {}

    self.allEffectKeys = {}

    self.worldPosition = sm.vec3.zero()

    self.worldRotation = sm.quat.identity()

    self.scale = sm.vec3.one()

    for key, data in pairs(effects) do    

        local effect = sm.effect.createEffect("ShapeRenderable")

        effect:setParameter("uuid", sm.uuid.new(data))
        effect:setScale(sm.vec3.new(1,1,1) * sm.construction.constants.subdivideRatio)
        
        self.effectData[key] = {["effect"] = effect, ["isPlaying"] = false, ["offsetTransforms"] = {sm.vec3.zero(), sm.quat.identity(), sm.vec3.one()}}

        table.insert(self.allEffectKeys, key)
    end

    self:updateEffectTransforms()
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


function EffectSet:setEffect(key, effect)
    
    if self.effectData[key] ~= nil then
        
        self.effectData[key].effect:stop()
    end

    self.effectData[key] = {
        ["effect"] = effect,
        ["isPlaying"] = false,
        ["offsetTransforms"] = {sm.vec3.zero(), sm.quat.identity(), sm.vec3.one()}
    }

    table.insert(self.allEffectKeys, key)

    self:updateEffectTransforms()
end


---Set world position of EffectSet
---@param worldPosition Vec3
function EffectSet:setPosition(worldPosition)

    self.worldPosition = worldPosition

    self:updateEffectTransforms()
end


---Set world rotation of EffectSet
---@param worldRotation Quat
function EffectSet:setRotation(worldRotation)

    self.worldRotation = worldRotation

    self:updateEffectTransforms()
end


---Set world position and world rotation of EffectSet
---@param worldPosition Vec3
---@param worldRotation Quat
function EffectSet:setPositionAndRotation(worldPosition, worldRotation)

    self.worldPosition = worldPosition

    self.worldRotation = worldRotation

    self:updateEffectTransforms()
end


function EffectSet:setParameter(effectKey, parameterKey, parameter, reload)
    
    if reload == nil then
        reload = false
    end

    if reload and self.effectData[effectKey].isPlaying == true then

        self:getEffect(effectKey):stop()
        self:getEffect(effectKey):setParameter(parameterKey, parameter)
        self:getEffect(effectKey):start()

    else

        self:getEffect(effectKey):setParameter(parameterKey, parameter)
    end
end


---Set scale of EffectSet
---@param scale Vec3
function EffectSet:setScale(scale)

    self.scale = scale

    self:updateEffectTransforms()
end


---Update position, rotation, scale of the effects passed as arguments
---@param table table | nil (Optional) The passed effectData (Defaults to all effects)
function EffectSet:updateEffectTransforms(table)
    
    if table == nil then
        
        table = self.effectData
    end

    for _, effectData in pairs(table) do

        local offsetTransforms = effectData["offsetTransforms"]
        
        effectData["effect"]:setPosition(self.worldPosition + self.worldRotation * (offsetTransforms[1] * self.scale))

        effectData["effect"]:setRotation(self.worldRotation * offsetTransforms[2])

        effectData["effect"]:setScale(self.scale * offsetTransforms[3])
    end
end


---Set the local transforms of some of the effects
---@param transforms table {[key] = {position, rotation, scale}}; Parameters that are nil are not edited.
function EffectSet:setOffsetTransforms(transforms)
    
    for key, transform in pairs(transforms) do

        if self.effectData[key] == nil then
            
            goto continue
        end

        PlacementUtils.copyExcludingNil(transform, self.effectData[key]["offsetTransforms"])

        self:updateEffectTransforms({self.effectData[key]})

        ::continue::
    end
end


--Compatibility
function EffectSet:start()
    
    EffectSet:show(self.allEffectKeys)
end


function EffectSet:stop()
    
    EffectSet:stop()
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