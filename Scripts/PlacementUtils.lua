
dofile("$CONTENT_DATA/Scripts/DefaultBody.lua")

PlacementUtils = class()


---@param object any
---@param table table
---@return boolean
function sm.util.contains(object, table)
    
    for _, value in pairs(table) do
        
        if value == object then
            
            return true
        end
    end

    return false
end


---@param container Container
---@return table
function sm.util.containerToTable(container)
    
    local size = container:getSize()

    local returnTable = {}

    for i = 1, size, 1 do
        
        returnTable[i] = container:getItem(i)
    end

    return returnTable
end


---@param container Container
---@return table
function sm.util.containerToStringTable(container)
    
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
function sm.effect.setTransforms(effect, pos, rot)
    
    effect:setPosition(pos)
    effect:setRotation(rot)
end


function PlacementUtils.is6Way(item)
    
    -- WIP

    return false
end


---@param num number
---@return number
function PlacementUtils.roundToCenterGrid(num)

    return SubdivideRatio * (math.floor(num / SubdivideRatio) + 1/2)
end


---@param vec Vec3
---@return Vec3
function PlacementUtils.roundVecToCenterGrid(vec)

    return sm.vec3.new(PlacementUtils.roundToCenterGrid(vec.x), PlacementUtils.roundToCenterGrid(vec.y), PlacementUtils.roundToCenterGrid(vec.z))
end


---@param num number
---@return number
function PlacementUtils.roundToGrid(num)
    
    return SubdivideRatio * math.floor(num / SubdivideRatio + 1/2)
end


---@param vec Vec3
---@return Vec3
function PlacementUtils.roundVecToGrid(vec)
    
    return sm.vec3.new(PlacementUtils.roundToGrid(vec.x), PlacementUtils.roundToGrid(vec.y), PlacementUtils.roundToGrid(vec.z))
end


---@param vec Vec3
---@param range number
---@return Vec3
function PlacementUtils.clampVec(vec, range)

    return sm.vec3.new(sm.util.clamp(vec.x, - range, range), sm.util.clamp(vec.y, - range, range), sm.util.clamp(vec.z, - range, range))
end


---@param raycastPos Vec3
---@param raycastDirection Vec3
---@param planePos Vec3
---@param planeNormal Vec3
---@return Vec3
function PlacementUtils.raycastToPlane(raycastPos, raycastDirection, planePos, planeNormal)
    
    local distance = planePos - raycastPos

    local perpendicularDistance = distance:dot(planeNormal)

    local perpendicularComponentOfRaycast = raycastDirection:dot(planeNormal)

    return raycastDirection * perpendicularDistance / perpendicularComponentOfRaycast
end


---@param raycastPos Vec3
---@param raycastDirection Vec3
---@param linePos Vec3
---@param lineDirection Vec3
---@return number
function PlacementUtils.raycastToLine(raycastPos, raycastDirection, linePos, lineDirection)

    local distance = raycastPos - linePos

    local planeNormal = (distance - lineDirection * distance:dot(lineDirection))

    local delta = PlacementUtils.raycastToPlane(raycastPos, raycastDirection, linePos, planeNormal) + raycastPos - linePos

    return delta:dot(lineDirection)
end


---@param raycastResult RaycastResult
---@return Body
function PlacementUtils.getTransformBody(raycastResult)

    if raycastResult.type == "body" then

        return raycastResult:getBody()

    elseif raycastResult.type == "joint" then
        
        return raycastResult:getJoint().shapeA.body

    elseif raycastResult.type == "terrainSurface" or raycastResult.type == "terrainAsset" then

        return DefaultBody
    end
end


---@param raycastResult RaycastResult
function PlacementUtils.getAttachedObject(raycastResult)
    
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
function PlacementUtils.isPlaceableFace(raycastResult, normalVector)
    
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