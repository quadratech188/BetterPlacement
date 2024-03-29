
dofile("$CONTENT_DATA/Scripts/DefaultBody.lua")

UsefulUtils = class()

-- #region Constants

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

Axes = {
	["+X"] = QuatPosX,
	["+Y"] = QuatPosY,
	["+Z"] = QuatPosZ,
	["-X"] = QuatNegX,
	["-Y"] = QuatNegY,
	["-Z"] = QuatNegZ
}

Quat90 = sm.quat.angleAxis(- math.pi / 2, PosZ)

UsefulUtils.callbacks = {}

-- #endregion

-- #region Client/Server

--- Set up the given function to be called(with all the arguments) when a callback is sent to the given class
---@param class table The class to which the callback is sent.
---@param callbackName string The name of the callback
---@param func function The function that is called
---@param order integer -1: function is called before the original function, 1: function is called after the original function
---@param noDuplicates boolean|nil don't add the new function if it already exists
function UsefulUtils.linkCallback(class, callbackName, func, order, noDuplicates)

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

			if originalFunction ~= nil then
				originalFunction(...)
			end

			for _, func in pairs(UsefulUtils.callbacks[class][callbackName][1]) do
					
				func(...)
			end
		end
	end

	if not UsefulUtils.contains(func, UsefulUtils.getCallbacks(class, callbackName)[order]) and noDuplicates == true then
		table.insert(UsefulUtils.callbacks[class][callbackName][order], func)
	end
end


--- Get all functions linked to the specified callback
---@param class table The class to which the callback is sent.
---@param callbackName string The name of the callback
---@return table|nil
function UsefulUtils.getCallbacks(class, callbackName)

	if callbackName == nil then
		return UsefulUtils.callbacks[class]
	end
	
	if UsefulUtils.callbacks[class] == nil then
		return nil
	end
	
	return UsefulUtils.callbacks[class][callbackName]
end


---Highlight the given shape using a SmartEffect
---@param smartEffect SmartEffect The effect
---@param shape Shape The shape
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


---Returns face data about the raycast
---@param raycastResult RaycastResult
function UsefulUtils.getFaceDataFromRaycast(raycastResult)
	
	local returnTable = {}

	returnTable.parentBody = UsefulUtils.getTransformBody(raycastResult)
	returnTable.parentObject = UsefulUtils.getAttachedObject(raycastResult)

	returnTable.localRawPos = raycastResult.pointLocal
	returnTable.localNormal = sm.vec3.closestAxis(raycastResult.normalLocal)

	---@type Vec3
	returnTable.localFaceCenterPos = UsefulUtils.roundVecToCenterGrid(raycastResult.pointLocal + returnTable.localNormal * SubdivideRatio_2) - returnTable.localNormal * SubdivideRatio_2
	returnTable.localFaceRot = sm.vec3.getRotation(PosZ, returnTable.localNormal)

	return returnTable
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


---@param object any
---@param table table
---@return any
function UsefulUtils.find(object, table)
	
	for key, value in pairs(table) do
		
		if value == object then
			
			return key
		end
	end

	return nil
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
	
	return dimensions / 2 - UsefulUtils.roundVecToGrid(dimensions / 2)
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


function UsefulUtils.absVec(vec)
	
	return sm.vec3.new(math.abs(vec.x), math.abs(vec.y), math.abs(vec.z))
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


---Returns raycast data to a plane
---@param raycastPos Vec3
---@param raycastDirection Vec3
---@param planePos Vec3
---@param planeRotation Quat
---@return table raycastData {pointLocal, pointWorld}
function UsefulUtils.raycastToPlane(raycastPos, raycastDirection, planePos, planeRotation)

	local localPos = sm.quat.inverse(planeRotation) * (raycastPos - planePos)

	local localDir = sm.quat.inverse(planeRotation) * raycastDirection

	local localPlanePos = localPos - localDir * (localPos.z / localDir.z)

	local worldPos = planeRotation * localPlanePos + planePos

	return {
		pointLocal = localPlanePos,
		pointWorld = worldPos,
		distanceToPlane = localPos.z
	}
end


---@param raycastPos Vec3
---@param raycastDirection Vec3
---@param linePos Vec3
---@param lineDirection Vec3
---@return number
function UsefulUtils.raycastToLineDeprecated(raycastPos, raycastDirection, linePos, lineDirection)

	local distance = raycastPos - linePos

	local planeNormal = (distance - lineDirection * distance:dot(lineDirection))

	local delta = UsefulUtils.raycastToPlaneDeprecated(raycastPos, raycastDirection, linePos, planeNormal) + raycastPos - linePos

	return delta:dot(lineDirection)
end


---@param raycastPos Vec3
---@param raycastDirection Vec3
---@param linePos Vec3
---@param lineDirection Vec3
---@return table
function UsefulUtils.raycastToLine(raycastPos, raycastDirection, linePos, lineDirection)

	local distance = raycastPos - linePos

	local planeNormal = (distance - lineDirection * distance:dot(lineDirection))

	local delta = UsefulUtils.raycastToPlaneDeprecated(raycastPos, raycastDirection, linePos, planeNormal) + raycastPos - linePos

	local offset = delta:dot(lineDirection)

	return {
		pointLocal = sm.vec3.new(0, 0, offset),
		pointWorld = linePos + lineDirection * offset
	}
end


---Snaps a volume to a cursor on a surface
---@param size Vec3 Size of the volume to be snapped
---@param cursorPos Vec3 Position of the cursor relative to the surface
---@param surfacePos Vec3 Position of the surface
---@param surfaceNormal Vec3 Normal vector of the surface
---@param snappingMode "Center"|"Fixed"|"Dynamic" Snapping mode.
---@return Vec3
function UsefulUtils.snapVolumeToSurface(size, cursorPos, surfacePos, surfaceNormal, snappingMode)

	local localSize = UsefulUtils.absVec(sm.quat.inverse(sm.vec3.getRotation(PosZ, surfaceNormal)) * size)

	local roundedOffset
	
	if snappingMode == "Center" then

		roundedOffset = sm.vec3.zero()
	
	elseif snappingMode == "Fixed" then

		roundedOffset = UsefulUtils.getCenterOffset(localSize) - BlockSize / 2
		
	elseif snappingMode == "Dynamic" then

		roundedOffset = UsefulUtils.roundVecToCenterGrid(cursorPos + UsefulUtils.getCenterOffset(localSize)) - UsefulUtils.getCenterOffset(localSize)

	end

	roundedOffset.z = localSize.z / 2

	return sm.vec3.getRotation(PosZ, surfaceNormal) * roundedOffset + surfacePos
end


---@param raycastResult RaycastResult
function UsefulUtils.getTransformBody(raycastResult)

	if raycastResult.type == "body" then

		return raycastResult:getBody()

	elseif raycastResult.type == "joint" then
		
		return raycastResult:getJoint().shapeA.body

	elseif raycastResult.type == "terrainSurface" or raycastResult.type == "terrainAsset" then

		return TerrainBody
	
	elseif raycastResult.type == "lift" then

		return LiftBody
	end
end


---@param raycastResult RaycastResult
function UsefulUtils.getAttachedObject(raycastResult)
	
	if raycastResult.type == "body" then

		return raycastResult:getShape()

	elseif raycastResult.type == "joint" then

		return raycastResult:getJoint()
	
	elseif raycastResult.type == "terrainSurface" or raycastResult.type == "terrainAsset" then

		return TerrainBody
	
	elseif raycastResult.type == "lift" then
		
		return LiftBody
	end
end


---@param raycastResult RaycastResult
---@param normalVector Vec3
---@return boolean
function UsefulUtils.isPlaceableFace(raycastResult, normalVector)
	
	if raycastResult.type == "body" then

		PositiveStick, NegativeStick = raycastResult:getShape():getSticky()

	elseif raycastResult.type == "joint" then

		PositiveStick, NegativeStick = raycastResult:getJoint():getSticky()

		-- Check if joint isn't occupied

		if raycastResult:getJoint():getShapeB() ~= nil then
			return false
		end

	elseif raycastResult.type == "lift" then
		
		return (normalVector.z == 1)

	else
		
		return UsefulUtils.contains(raycastResult.type, {"terrainSurface", "terrainAsset"})
	end

	local t = {[0] = false, [1] = true}

	if normalVector.x == -1 then
		return t[PositiveStick.x]
	
	elseif normalVector.x == 1 then
		return t[NegativeStick.x]

	elseif normalVector.y == -1 then
		return t[PositiveStick.y]

	elseif normalVector.y == 1 then
		return t[NegativeStick.y]

	elseif normalVector.z == -1 then
		return t[PositiveStick.z]

	else
		return t[NegativeStick.z]
	end
end


---Transforms a world direction to local space
---@param dir Vec3
---@param body Body
function UsefulUtils.worldToLocalDir(dir, body)
	
	return sm.quat.inverse(body.worldRotation) * dir
end


---Transforms a world rotation to local space
---@param rot Quat
---@param body Body
function UsefulUtils.worldToLocalRot(rot, body)
	
	return sm.quat.inverse(body.worldRotation) * rot
end


---Transforms a world position to local space
---@param pos Vec3
---@param body Body
function UsefulUtils.worldToLocalPos(pos, body)
	
	return sm.quat.inverse(body.worldRotation) * (pos - body.worldPosition)
end


---Returns the actual(not grid) local position of a shape
---@param shape Shape
function UsefulUtils.getActualLocalPos(shape)
	
	return UsefulUtils.worldToLocalPos(shape.worldPosition, shape:getBody())
end

-- #endregion

-- #region Server

---Create a part.
---@param _ any ignored
---@param data table {uuid, parent, localPos, localRot, forceAccept, colour}
---@return Shape|Joint|nil
function UsefulUtils.sv_createPart(_, data)

	local part = data[1]
	local parentObject = data[2]
	local localPos = data[3]
	local localRot = data[4]
	local forceAccept = data[5]
	local colour = data[6]

	if forceAccept == nil then
		forceAccept = true
	end

	if colour == nil then
		colour = sm.item.getShapeDefaultColor(part)
	end

	local xAxis = sm.vec3.closestAxis(sm.quat.getRight(localRot))
	local yAxis = sm.vec3.closestAxis(sm.quat.getUp(localRot))
	local zAxis = sm.vec3.closestAxis(sm.quat.getAt(localRot))

	if sm.item.isPart(part) then

		local function convertToWeird(x)

			--From testing, the correct numbers are:
			-- -2 -> -2.5,
			-- -1 -> -1.5,
			-- 0 -> 0,
			-- 1 -> 1.5,
			-- 2 -> 2.5 etc.

			if x > 0.5 then
				return x + 0.5
			
			elseif x < 0.5 then
				return x - 0.5
			
			else
				return x
			end
		end

		local function convertVecToWeird(vec)
			
			return sm.vec3.new(convertToWeird(vec.x), convertToWeird(vec.y), convertToWeird(vec.z))
		end

		if type(parentObject) == "Shape" then
			local cornerPos = localPos / SubdivideRatio - localRot * sm.item.getShapeSize(part) * 0.5

			local shape = parentObject:getBody():createPart(part, convertVecToWeird(cornerPos), zAxis, xAxis, forceAccept)

			shape:setColor(colour)

			return shape

		elseif type(parentObject) == "Body" then
			local cornerPos = localPos / SubdivideRatio - localRot * sm.item.getShapeSize(part) * 0.5

			local shape = parentObject:createPart(part, convertVecToWeird(cornerPos), zAxis, xAxis, forceAccept)

			shape:setColor(colour)

			return shape
		
		elseif type(parentObject) == "Joint" then

			-- parentObject:createPart(part, localPlacementPos - parentObject.localPosition / SubdivideRatio, zAxis, xAxis, forceAccept)
		
		elseif parentObject == "terrain" then

			local shape = sm.shape.createPart(part, localPos - localRot * sm.item.getShapeOffset(part), localRot, false, forceAccept)

			shape:setColor(colour)

			return shape

		elseif parentObject == "lift" then


		end
	end
end


function UsefulUtils.sv_destroyPart(_, shape)
	
	shape:destroyPart()
end


-- #endregion