
---@class LineEffect:Effect

LineEffect = class()


---Try using LineEffect.new instead
---@param thickness Vec3 X, Y: thickness of the line, Z: the overhang beyond the endpoints
---@param material string The Uuid of the block/part the line is made of (preferrably 1x1x1)
---@param parent Body|DefaultBody The Body that the line is attached to, position/rotation is calculated relative to here
function LineEffect:initialize(thickness, material, parent)

    self.lineEffect = sm.effect.createEffect("ShapeRenderable")
    self.lineEffect:setParameter("uuid", sm.uuid.new(material))
    self.startPos = sm.vec3.zero()
    self.endPos = sm.vec3.zero()
    self.fallbackDirection = PosZ
    self.thickness = thickness
    self.parent = parent
end


---Creates a new LineEffect.
---@param thickness Vec3 X, Y: thickness of the line, Z: the overhang beyond the endpoints
---@param material string The Uuid of the block/part the line is made of (preferrably 1x1x1)
---@param parent Body|nil (optional) The Body that the line is attached to, position/rotation is calculated relative to here
---@return LineEffect
function LineEffect.new(thickness, material, parent)

    if not parent then
        parent = DefaultBody
    end
    
    local returnClass = class(LineEffect)

    returnClass:initialize(thickness, material, parent)

    return returnClass
end


function LineEffect:update()
    
    local localPosition, localRotation, scale = LineEffect.calculateEffectTransform(self.startPos, self.endPos, self.thickness, self.fallbackDirection)

    local worldPosition = self.parent:transformPoint(localPosition)
    local worldRotation = self.parent.worldRotation * localRotation

    self.lineEffect:setPosition(worldPosition)
    self.lineEffect:setRotation(worldRotation)
    self.lineEffect:setScale(scale)
end


---Calculate the transforms that creates the correct line
---@param startPos Vec3
---@param endPos Vec3
---@param thickness Vec3
---@return Vec3
---@return Quat
---@return Vec3
function LineEffect.calculateEffectTransform(startPos, endPos, thickness, fallbackDirection)

    if startPos == endPos then
        
        return startPos, sm.vec3.getRotation(PosZ, fallbackDirection), thickness
    end
    
    ---@type Vec3
    local position = (startPos + endPos) / 2
    local rotation = sm.vec3.getRotation(PosZ, endPos - startPos)
    local length = (endPos - startPos):length() + thickness.z
    local scale = sm.vec3.new(thickness.x, thickness.y, length)

    return position, rotation, scale
end


function LineEffect:start()
    print("start")
    self.lineEffect:start()
end


function LineEffect:stop()
    print("stop")
    self.lineEffect:stop()
end


function LineEffect:setStart(pos)
    
    self.startPos = pos

    self:update()
end


function LineEffect:setEnd(pos)
    
    self.endPos = pos

    self:update()
end


function LineEffect:setParameter(name, value)
    self.lineEffect:setParameter(name, value)
end


function LineEffect:setPosition(pos) end

function LineEffect:setRotation(rot) end

function LineEffect:setScale(scale) end
    
