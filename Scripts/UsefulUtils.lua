
dofile("$CONTENT_DATA/Scripts/DefaultBody.lua")

UsefulUtils = class()


---@type number
SubdivideRatio_2 = sm.construction.constants.subdivideRatio_2

---@type number
SubdivideRatio = sm.construction.constants.subdivideRatio

BlockSize = sm.vec3.new(1, 1, 1) * SubdivideRatio

PosX = sm.vec3.new(1,0,0)
PosY = sm.vec3.new(0,1,0)
PosZ = sm.vec3.new(0,0,1)
NegX = sm.vec3.new(-1,0,0)
NegY = sm.vec3.new(0,-1,0)
NegZ = sm.vec3.new(0,0,-1)

QuatPosX = sm.vec3.getRotation(PosZ, PosX)
QuatPosY = sm.vec3.getRotation(PosZ, PosY)
QuatPosZ = sm.quat.identity()
QuatNegX = sm.vec3.getRotation(PosZ, NegX)
QuatNegY = sm.vec3.getRotation(PosZ, NegY)
QuatNegZ = sm.vec3.getRotation(PosZ, NegZ)

Quat90 = sm.quat.angleAxis(- math.pi / 2, PosZ)

UsefulUtils.callbacks = {}

--- Makes the given function get called when a callback is sent to the class (with all the arguments given to the callback)
---@param class table The class to which the callback is sent.
---@param callbackName string The name of the callback
---@param func function The function that is called
---@param order integer -1: function is called before the original function, 1: function is called after the original function
function UsefulUtils.linkCallback(class, callbackName, func, order)

    if UsefulUtils.callbacks[class] == nil then
        UsefulUtils.callbacks[class] = {}
    end

    if UsefulUtils.callbacks[class][callbackName] == nil then

        -- This is the first time hooking the callback

        UsefulUtils.callbacks[class][callbackName] = {
            [-1] = {},
            [1] = {}
        }

        local originalFunction = class[callbackName]

        class[callbackName] = function (...)
            
            for _, func in pairs(UsefulUtils.callbacks[class][callbackName][-1]) do
                    
                func(...)
            end

            if originalFunction ~= ni then
                originalFunction(...)
            end

            for _, func in pairs(UsefulUtils.callbacks[class][callbackName][1]) do
                    
                func(...)
            end
        end
    end

    table.insert(UsefulUtils.callbacks[class][callbackName][order], func)
end

---Highlight the given shape using a SmartEffect
---@param smartEffect SmartEffect The effect
---@param shape ShapeClass The shape
function UsefulUtils.highlightShape(smartEffect, shape)

    smartEffect:stop()
        
    smartEffect:setParameter("uuid", shape.uuid)

    smartEffect:start()

    if shape.isBlock then
        smartEffect:setOffsetTransforms({nil, nil, shape:getBoundingBox() / SubdivideRatio})
    else
        smartEffect:setOffsetTransforms({nil, nil, sm.vec3.one()})
    end
        
    smartEffect:setTransforms({shape.worldPosition, shape.worldRotation, SubdivideRatio})
end


---@param object any
---@param table table
---@return boolean
function UsefulUtils.contains(object, table)
    
    for _, value in pairs(table) do
        
        if value == object then
            
            return true
        end
    end

    return false
end


---@param effect SmartEffect|Effect
---@param state "None"|"Solid"|"Blue"|"Red"
function UsefulUtils.setShapeRenderableState(effect, state)

    if effect:isPlaying() then

        effect:stop()
    end

    if state == "None" then
        

    elseif state == "Solid" then

        effect:setParameter("visualization", false)
        effect:start()
    elseif state == "Blue" then

        effect:setParameter("visualization", true)
        effect:setParameter("valid", true)
        effect:start()
    elseif state == "Red" then

        effect:setParameter("visualization", true)
        effect:setParameter("valid", false)
        effect:start()
    end
end


---Copies the contents of table1 to table2, not modifying nil values
---@param table1 table the table to be copied from
---@param table2 table the table to be copied to
function UsefulUtils.copyExcludingNil(table1, table2)
    
    for key, value in pairs(table1) do

        table2[key] = value
    end
end


---@param container Container
---@return table
function UsefulUtils.containerToTable(container)
    
    local size = container:getSize()

    local returnTable = {}

    for i = 1, size, 1 do
        
        returnTable[i] = container:getItem(i)
    end

    return returnTable
end


---@param container Container
---@return table
function UsefulUtils.containerToStringTable(container)
    
    local size = container:getSize()

    local returnTable = {}

    for i = 1, size, 1 do

        local info = container:getItem(i)
        
        info.uuid = tostring(info.uuid)

        returnTable[i] = info
    end

    return returnTable
end


---@param effect Effect
---@param pos Vec3
---@param rot Quat
function UsefulUtils.setTransforms(effect, pos, rot)
    
    effect:setPosition(pos)
    effect:setRotation(rot)
end


function UsefulUtils.is6Way(item)
    
    -- WIP

    return false
end


function UsefulUtils.getCenterOffset(dimensions)
    
    return dimensions - UsefulUtils.roundToGrid(dimensions)
end


---@param num number
---@return number
function UsefulUtils.roundToCenterGrid(num)

    return SubdivideRatio * (math.ceil(num / SubdivideRatio) - 1/2)
end


---@param vec Vec3
---@return Vec3
function UsefulUtils.roundVecToCenterGrid(vec)

    return sm.vec3.new(UsefulUtils.roundToCenterGrid(vec.x), UsefulUtils.roundToCenterGrid(vec.y), UsefulUtils.roundToCenterGrid(vec.z))
end


---@param num number
---@return number
function UsefulUtils.roundToGrid(num)
    
    return SubdivideRatio * math.ceil(num / SubdivideRatio - 1/2)
end


---@param vec Vec3
---@return Vec3
function UsefulUtils.roundVecToGrid(vec)
    
    return sm.vec3.new(UsefulUtils.roundToGrid(vec.x), UsefulUtils.roundToGrid(vec.y), UsefulUtils.roundToGrid(vec.z))
end


---@param vec Vec3
---@param range number
---@return Vec3
function UsefulUtils.clampVec(vec, range)

    return sm.vec3.new(sm.util.clamp(vec.x, - range, range), sm.util.clamp(vec.y, - range, range), sm.util.clamp(vec.z, - range, range))
end


---@param raycastPos Vec3
---@param raycastDirection Vec3
---@param planePos Vec3
---@param planeNormal Vec3
---@return Vec3
function UsefulUtils.raycastToPlaneDeprecated(raycastPos, raycastDirection, planePos, planeNormal)
    
    local distance = planePos - raycastPos

    local perpendicularDistance = distance:dot(planeNormal)

    local perpendicularComponentOfRaycast = raycastDirection:dot(planeNormal)

    return raycastDirection * perpendicularDistance / perpendicularComponentOfRaycast
end


---@param raycastPos Vec3
---@param raycastDirection Vec3
---@param planePos Vec3
---@param planeRotation Quat
---@return table
function UsefulUtils.raycastToPlane(raycastPos, raycastDirection, planePos, planeRotation)

    local planeNormal = sm.quat.getUp(planeRotation)
    
    local distance = planePos - raycastPos

    local perpendicularDistance = distance:dot(planeNormal)

    local perpendicularComponentOfRaycast = raycastDirection:dot(planeNormal)

    local worldPos = raycastDirection * perpendicularDistance / perpendicularComponentOfRaycast + raycastPos

    local worldDeltaPos = worldPos - planePos

    local localPos = sm.quat.inverse(planeRotation) * worldDeltaPos

    return {
        pointLocal = localPos,
        pointWorld = worldPos
    }
end


---@param raycastPos Vec3
---@param raycastDirection Vec3
---@param linePos Vec3
---@param lineDirection Vec3
---@return number
function UsefulUtils.raycastToLine(raycastPos, raycastDirection, linePos, lineDirection)

    local distance = raycastPos - linePos

    local planeNormal = (distance - lineDirection * distance:dot(lineDirection))

    local delta = UsefulUtils.raycastToPlaneDeprecated(raycastPos, raycastDirection, linePos, planeNormal) + raycastPos - linePos

    return delta:dot(lineDirection)
end


---@param raycastResult RaycastResult
---@return Body
function UsefulUtils.getTransformBody(raycastResult)

    if raycastResult.type == "body" then

        return raycastResult:getBody()

    elseif raycastResult.type == "joint" then
        
        return raycastResult:getJoint().shapeA.body

    elseif raycastResult.type == "terrainSurface" or raycastResult.type == "terrainAsset" then

        return DefaultBody
    end
end


---@param raycastResult RaycastResult
function UsefulUtils.getAttachedObject(raycastResult)
    
    if raycastResult.type == "body" then

        return raycastResult:getShape()

    elseif raycastResult.type == "joint" then

        return raycastResult:getJoint()
    
    elseif raycastResult.type == "terrainSurface" or raycastResult.type == "terrainAsset" then

        return DefaultBody
    end
end

---@param raycastResult RaycastResult
---@param normalVector Vec3
---@return number 1 is true, 0 is false
function UsefulUtils.isPlaceableFace(raycastResult, normalVector)
    
    if raycastResult.type == "body" then

        PositiveStick, NegativeStick = raycastResult:getShape():getSticky()

    elseif raycastResult.type == "joint" then

        PositiveStick, NegativeStick = raycastResult:getJoint():getSticky()

        -- Check if joint isn't occupied

        if raycastResult:getJoint():getShapeB() ~= nil then
            return false
        end
    else
        return 1
    end


    if normalVector.x == -1 then
        return PositiveStick.x
    
    elseif normalVector.x == 1 then
        return NegativeStick.x

    elseif normalVector.y == -1 then
        return PositiveStick.y

    elseif normalVector.y == 1 then
        return NegativeStick.y

    elseif normalVector.z == -1 then
        return PositiveStick.z

    else
        return NegativeStick.z
    end
end