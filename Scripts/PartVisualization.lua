---@diagnostic disable: undefined-field

---@class PartVisualization
---@field new function
---@field initialize function
---@field destroy function
---@field doFrame function
---@field setPart function
---@field attachEffect function
---@field setParent function
---@field setTransforms function
---@field visualize function
---@field part Uuid
---@field effect SmartEffect
---@field visualizationType "None"|"Solid"|"Blue"|"Red"
---@field parent Body|nil
---@field localPosition Vec3
---@field localRotation Quat


PartVisualization = class()


---Create a new PartVisualization
---@param part Uuid
---@param parent Body|nil
function PartVisualization.new(part, parent)
	
	---@type PartVisualization
	local returnClass = class(PartVisualization)

	returnClass:initialize(part, parent)

	return returnClass
end


---See PartVisualization.new
---@param part Uuid
---@param parent Body|nil
function PartVisualization:initialize(part, parent)
	
	self.part = part

	self.effect = SmartEffect.new(part)

	self.effect:setOffsetTransforms({nil, nil, BlockSize})

	self.visualizationType = "None"

	if parent == nil then
		self.parent = TerrainBody
	
	else
		self.parent = parent
	end

	self.localPosition = sm.vec3.zero()

	self.localRotation = sm.quat.identity()
end


function PartVisualization:doFrame()
	
	self.effect:setOffsetTransforms({self.localPosition, self.localRotation, nil})
	self.effect:setTransforms({self.parent.worldPosition, self.parent.worldRotation, nil})
end


---Set the uuid of the part
---@param part Uuid
function PartVisualization:setPart(part)
	
	self.part = part

	self.effect:stop()
	self.effect:setParameter("uuid", part)

	self:visualize(self.visualizationType)
end


---comment
---@param body Body
function PartVisualization:setParent(body)
	
	self.parent = body

	self:doFrame()
end


---Sets the position and rotation of the PartVisualization
---@param pos Vec3|nil The position
---@param rot Quat|nil The rotation
function PartVisualization:setTransforms(pos, rot)
	
	if pos ~= nil then
		self.localPosition = pos
	end

	if rot ~= nil then
		self.localRotation = rot
	end

	self:doFrame()
end


---Show an ShapeRenderable effect of the part
---@param state "None"|"Solid"|"Blue"|"Red"
function PartVisualization:visualize(state)

	self.visualizationType = state
	
	UsefulUtils.setShapeRenderableState(self.effect, state)
end