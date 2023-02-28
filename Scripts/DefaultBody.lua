
-- This Class exists for the sole purpose of making the code look better

DefaultBody = class()

DefaultBody.worldRotation = sm.quat.identity()

function DefaultBody:transformPoint(pos)
    
    return pos
end