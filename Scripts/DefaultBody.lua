
---@class DefaultBody

DefaultBody = class()

DefaultBody.worldPosition = sm.vec3.zero()

DefaultBody.worldRotation = sm.quat.identity()

function DefaultBody:transformPoint(pos)
    
    return pos
end