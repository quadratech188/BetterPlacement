---@diagnostic disable: undefined-field

dofile("$CONTENT_DATA/Scripts/DefaultBody.lua")

dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")

PartVisualization = class()


---Create a new PartVisualization
---@param part Uuid
---@param parent Body|DefaultBody|nil
function PartVisualization.new(part, parent)
    
    local returnClass = class(PartVisualization)

    returnClass:initialize(part, parent)

    return returnClass
end


---See PartVisualization.new
---@param part Uuid
---@param parent Body|DefaultBody|nil
function PartVisualization:initialize(part, parent)
    
    self.part = part

    self.effect = SmartEffect.new(part)

    self.effect:setOffsetTransforms({nil, nil, BlockSize})

    self.visualizationType = "None"

    if parent == nil then
        self.parent = DefaultBody
    
    else
        self.parent = parent
    end

    self.localPosition = sm.vec3.zero()

    self.localRotation = sm.quat.identity()
end


function PartVisualization:destroy()
    

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


---Attach an extra effect to the Center of the PartVisualization
---@param smartEffect any
function PartVisualization:attachEffect(smartEffect)
    
end


---comment
---@param body Body|DefaultBody
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


function PartVisualization:sv_createPart()
    
end