
---@diagnostic disable: need-check-nil

---@class SmartEffect
---@field new function
---@field initialize function
---@field start function
---@field stop function
---@field updateTransforms function
---@field setOffsetTransforms function
---@field setTransforms function
---@field setPosition function
---@field setRotation function
---@field setScale function
---@field setParameter function
---@field isPlaying function
---@field effect Effect
---@field on boolean
---@field offsetPosition Vec3
---@field offsetRotation Quat
---@field offsetScale Vec3
---@field worldPosition Vec3
---@field worldRotation Quat
---@field worldScale number

SmartEffect = class()


---Create a new SmartEffect
---@param effectData any Existing Effects, compatible custom effect classes, and uuids are supported
---@return SmartEffect
function SmartEffect.new(effectData)
	
	---@type SmartEffect
	local returnClass = class(SmartEffect)

	returnClass:initialize(effectData)

	return returnClass
end


function SmartEffect:initialize(effectData)
	
	-- Supported: 'Effect' userdata, Custom Effect class with sufficient callbacks, uuids for ShapeRenderable effect

	if type(effectData) == "Effect" or type(effectData) == "table" then
		
		self.effect = effectData
	
	elseif type(effectData) == "string" then

		self.effect = sm.effect.createEffect("ShapeRenderable")

		self.effect:setParameter("uuid", sm.uuid.new(effectData))

	elseif type(effectData) == "Uuid" then

		self.effect = sm.effect.createEffect("ShapeRenderable")

		self.effect:setParameter("uuid", effectData)
	end

	self.on = false

	self.offsetPosition = sm.vec3.zero()

	self.offsetRotation = sm.quat.identity()

	self.offsetScale = sm.vec3.one()
	
	self.worldPosition = sm.vec3.zero()

	self.worldRotation = sm.quat.identity()

	self.worldScale = 1
end


function SmartEffect:start()

	if not self.on then
		
		self.effect:start()
	end
	self.on = true
end

function SmartEffect:stop()

	if self.on then
		
		self.effect:stop()
	end
	self.on = false
end


---Refresh Transforms of SmartEffect
function SmartEffect:updateTransforms()

	self.effect:setPosition(self.worldPosition + self.worldRotation * (self.offsetPosition * self.worldScale))

	self.effect:setRotation(self.worldRotation * self.offsetRotation)

	self.effect:setScale(self.offsetScale * self.worldScale)
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


---Set world transforms of SmartEffect (nil values are ignored)
---@param transforms table {position, rotation, scale}
function SmartEffect:setTransforms(transforms)
	
	if transforms[1] ~= nil then
		self.worldPosition = transforms[1]
	end

	if transforms[2] ~= nil then
		self.worldRotation = transforms[2]
	end

	if transforms[3] ~= nil then
		self.worldScale = transforms[3]
	end

	self:updateTransforms()
end


---Set origin position
---@param position Vec3
function SmartEffect:setPosition(position)
	
	self.worldPosition = position

	self:updateTransforms()
end


---Set origin rotation
---@param rotation Quat
function SmartEffect:setRotation(rotation)
	
	self.worldRotation = rotation

	self:updateTransforms()
end


---Set origin scale
---@param scale number
function SmartEffect:setScale(scale)
	
	self.worldScale = scale

	self:updateTransforms()
end


---*Client only*  
---Sets a named parameter value on the effect.  
---@param name string The name.
---@param value any The effect parameter value.
function SmartEffect:setParameter(name, value)
	
	self.effect:setParameter(name, value)
end


function SmartEffect:isPlaying()
	
	return self.on
end


--------------------------------------------------------------------------------------------


---@class EffectSet
---@field initialize function
---@field new function
---@field getAllSmartEffects function
---@field getAllEffectKeys function
---@field setEffect function
---@field setPosition function
---@field setRotation function
---@field setPositionAndRotation function
---@field setScale function
---@field setParameter function
---@field updateTransforms function
---@field setOffsetTransforms function
---@field start function
---@field showOnly function
---@field show function
---@field hide function
---@field hideAll function
---@field smartEffects table
---@field allEffectKeys table
---@field worldPosition Vec3
---@field worldRotation Vec3
---@field worldScale number



EffectSet = class()


---@param effects table
function EffectSet:initialize(effects)

	self.smartEffects = {}

	self.allEffectKeys = {}

	self.worldPosition = sm.vec3.zero()

	self.worldRotation = sm.quat.identity()

	self.worldScale = 1

	for key, data in pairs(effects) do

		---@type SmartEffect
		self.smartEffects[key] = SmartEffect.new(data)

		table.insert(self.allEffectKeys, key)
	end

	self:updateTransforms()
end


---@param effects table
---@return EffectSet
function EffectSet.new(effects)

	---@type EffectSet
	local returnClass = class(EffectSet)

	returnClass:initialize(effects)

	return returnClass
end


function EffectSet:getAllSmartEffects()
	
	return self.smartEffects
end


function EffectSet:getAllEffectKeys()
	
	return self.allEffectKeys
end


function EffectSet:getSmartEffect(key)
	
	return self.smartEffects[key]
end


function EffectSet:setEffect(key, effect)
	
	if self.smartEffects[key] ~= nil then
		
		self.smartEffects[key].effect:destroy()
	end

	self.smartEffects[key] = SmartEffect.new(effect)

	self.smartEffects[key]:setTransforms(self.worldPosition, self.worldRotation, self.worldScale)

	table.insert(self.allEffectKeys, key)
end


---Set world position of EffectSet
---@param worldPosition Vec3
function EffectSet:setPosition(worldPosition)

	self.worldPosition = worldPosition

	self:updateTransforms()
end


---Set world rotation of EffectSet
---@param worldRotation Quat
function EffectSet:setRotation(worldRotation)

	self.worldRotation = worldRotation

	self:updateTransforms()
end


---Set world position and world rotation of EffectSet
---@param worldPosition Vec3
---@param worldRotation Quat
function EffectSet:setPositionAndRotation(worldPosition, worldRotation)

	self.worldPosition = worldPosition

	self.worldRotation = worldRotation

	self:updateTransforms()
end


---Set a parameter of an effect
---@param effectKey any The key of the desired effect
---@param parameterKey string The name of the desired parameter
---@param parameter any The parameter value
---@param reload boolean|nil Whether to reload (turn off/on) the effect while changing the parameter (Required for ShapeRenderables etc.)
function EffectSet:setParameter(effectKey, parameterKey, parameter, reload)
	
	if reload == nil then
		reload = false
	end

	if reload and self.smartEffects[effectKey].isPlaying == true then

		self.smartEffects[effectKey]:stop()
		self.smartEffects[effectKey]:setParameter(parameterKey, parameter)
		self.smartEffects[effectKey]:start()

	else

		self.smartEffects[effectKey]:setParameter(parameterKey, parameter)
	end
end


---Set scale of EffectSet (Vec3 is not possible)
---@param scale number
function EffectSet:setScale(scale)

	self.worldScale = scale

	self:updateTransforms()
end


---Update position, rotation, scale of all effects
function EffectSet:updateTransforms()

	for _, smartEffect in pairs(self.smartEffects) do

		smartEffect:setTransforms({self.worldPosition, self.worldRotation, self.worldScale})
	end
end


---Set the local transforms of some of the effects
---@param transforms table {[key] = {position, rotation, scale}}; Parameters that are nil are not edited.
function EffectSet:setOffsetTransforms(transforms)
	
	for key, transform in pairs(transforms) do

		if self.smartEffects[key] == nil then
			
			-- Invalid key

			goto continue
		end

		self.smartEffects[key]:setOffsetTransforms(transform)

		::continue::
	end
end


--Compatibility
function EffectSet:start()
	
	EffectSet:show(self.allEffectKeys)
end


function EffectSet:stop()
	
	EffectSet:hideAll()
end


---Shows the given effects, hides all others
function EffectSet:showOnly(keys)

	self:hideAll()

	self:show(keys)
end


---Shows the given effects, maintains all others
function EffectSet:show(keys)

	if type(keys) ~= "table" then
		keys = {keys}
	end

	for _, key in pairs(keys) do

		local smartEffect = self.smartEffects[key]

		if smartEffect == nil then
			
			goto continue
		end

		if not smartEffect:isPlaying() then
			
			smartEffect:start()
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

		local smartEffect = self.smartEffects[key]
		
		if smartEffect == nil then
			
			goto continue
		end

		if smartEffect:isPlaying() then
			
			smartEffect:stop()
		end

		::continue::
	end
end


---Hides every effect
function EffectSet:hideAll()
	
	self:hide(self.allEffectKeys)
end