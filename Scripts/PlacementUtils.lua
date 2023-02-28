
dofile("$CONTENT_DATA/Scripts/DefaultBody.lua")

PlacementUtils = class()


function sm.util.contains(object, table)
    
    for _, value in pairs(table) do
        
        if value == object then
            
            return true
        end
    end

    return false
end

--- @param container Container
---@return table returnTable
function sm.util.containerToTable(container)
    
    local size = container:getSize()

    local returnTable = {}

    for i = 1, size, 1 do
        
        returnTable[i] = container:getItem(i)
    end

    return returnTable
end


--- @param container Container
---@return table returnTable
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


function PlacementUtils.is6Way(item)
    
    return false
end


function PlacementUtils.roundToCenterGrid(num)

    return SubdivideRatio * (math.floor(num / SubdivideRatio) + 1/2)
end


function PlacementUtils.roundVecToCenterGrid(vec)

    return sm.vec3.new(PlacementUtils.roundToCenterGrid(vec.x), PlacementUtils.roundToCenterGrid(vec.y), PlacementUtils.roundToCenterGrid(vec.z))
end


function PlacementUtils.roundToGrid(num)
    
    return SubdivideRatio * math.floor(num / SubdivideRatio + 1/2)
end


function PlacementUtils.roundVecToGrid(vec)
    
    return sm.vec3.new(PlacementUtils.roundToGrid(vec.x), PlacementUtils.roundToGrid(vec.y), PlacementUtils.roundToGrid(vec.z))
end


function PlacementUtils.clampVec(vec, range)

    return sm.vec3.new(sm.util.clamp(vec.x, - range, range), sm.util.clamp(vec.y, - range, range), sm.util.clamp(vec.z, - range, range))
end


function PlacementUtils.raycastToPlane(raycastPos, raycastDirection, planePos, planeNormal)
    
    local distance = planePos - raycastPos

    local perpendicularDistance = distance:dot(planeNormal)

    local perpendicularComponentOfRaycast = raycastDirection:dot(planeNormal)

    return raycastDirection * perpendicularDistance / perpendicularComponentOfRaycast
end


function PlacementUtils.raycastToLine(raycastPos, raycastDirection, linePos, lineDirection)

    local distance = raycastPos - linePos

    local planeNormal = (distance - lineDirection * distance:dot(lineDirection))

    local delta = PlacementUtils.raycastToPlane(raycastPos, raycastDirection, linePos, planeNormal) + raycastPos - linePos

    return delta:dot(lineDirection)
end


function PlacementUtils.getTransformBody(raycastResult)

    if raycastResult.type == "body" then

        return raycastResult:getBody()

    elseif raycastResult.type == "joint" then
        
        return raycastResult:getJoint().shapeA.body

    elseif raycastResult.type == "terrainSurface" or raycastResult.type == "terrainAsset" then

        return DefaultBody
    end
end


function PlacementUtils.getAttachedObject(raycastResult)
    
    if raycastResult.type == "body" then

        return raycastResult:getShape()

    elseif raycastResult.type == "joint" then

        return raycastResult:getJoint()
    
    elseif raycastResult.type == "terrainSurface" or raycastResult.type == "terrainAsset" then

        return DefaultBody
    end
end


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