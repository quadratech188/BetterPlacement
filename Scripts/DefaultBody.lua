
---@class DefaultBody

DefaultBody = class()

DefaultBody.worldPosition = sm.vec3.zero()

DefaultBody.worldRotation = sm.quat.identity()

DefaultBody.type = "DefaultBody"


function DefaultBody:transformPoint(pos)
    
    return pos
end


function DefaultBody:createPart(a, b, c, d, e)
    
    sm.shape.createPart(a, b, c, d, e)
end