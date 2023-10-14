
dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")

dofile("$CONTENT_DATA/Scripts/PartVisualization.lua")

dofile("$CONTENT_DATA/Scripts/EffectSet.lua")

---@class BetterPlacementCoreV2

BetterPlacementCoreV2 = class()


function BetterPlacementCoreV2:initialize()

	RotationList = {

		[0] = sm.quat.identity(),
		[1] = Quat90,
		[2] = Quat90 * Quat90,
		[3] = Quat90 * Quat90 * Quat90
	}
	
	self.phases = {
		[0] = self.doPhase0,
		[1] = self.doPhase1,
		[2] = self.doPhase2
	}

	self.partVisualization = PartVisualization.new(sm.uuid.getNil(), nil)

	self.phase0 = {}
	self.phase1 = {}
	self.phase2 = {}

	self.phase0.rotationStorage = {}

	self.constants = {
		supportedSurfaces = {
			"body",
			"terrainSurface",
			"terrainAsset"
		},
		isSupportedItem = function (part)
			return sm.item.isPart(part)
		end,
		centerSize = 0.45,
		colours = {
			white = sm.color.new(0.8, 0.8, 0.8, 1),
			highlight = sm.color.new(0, 0, 0.8, 1),
			red = sm.color.new("9F0000"),
			green = sm.color.new("009F00"),
			blue = sm.color.new("00008F")
		}
	}

	self:createEffects()

	UsefulUtils.linkCallback(BetterPlacementClass, "sv_createPart", UsefulUtils.sv_createPart, -1)

	self:reset()

	-- Temporary

	self.settings = {

		roundingSetting = "Dynamic", -- Center, Fixed, Dynamic
		positionSelectionTimer = 5, -- Ticks before advancing to position selection
		placementRadii = 7.5, -- Reach distance
		doubleClick = false -- Click to begin placement, click again to end it
	}
end


function BetterPlacementCoreV2:createEffects()
	
	local rotationGizmoUuids = {

		["Base"] = "07ef9dbe-cf0d-4c18-a828-0092c1f50422",
		["+X"] = "03422fac-1103-4f93-9206-5324c1406a86",
		["+Y"] = "728e9744-9b40-45e7-9c0a-0e386f01e592",
		["+Z"] = "d8fc440b-ad25-45db-b72b-36a99414435b",
		["-X"] = "8cbaa03b-90f2-42fc-888b-1626650325c5",
		["-Y"] = "01e9830e-4b80-47b5-9cbb-736024f12d53"
	}

	-- Create effects

	self.rotationGizmo = EffectSet.new(rotationGizmoUuids)

	self.rotationGizmo:setParameter("Base", "color", self.constants.colours.white)
	self.rotationGizmo:setParameter("+X", "color", self.constants.colours.highlight)
	self.rotationGizmo:setParameter("+Y", "color", self.constants.colours.highlight)
	self.rotationGizmo:setParameter("+Z", "color", self.constants.colours.highlight)
	self.rotationGizmo:setParameter("-X", "color", self.constants.colours.highlight)
	self.rotationGizmo:setParameter("-Y", "color", self.constants.colours.highlight)

	self.rotationGizmo:setScale(SubdivideRatio)

	local cubeUuid = sm.uuid.new("4a91af39-7095-4497-8930-b9105e8a236d")

	local transformGizmoUuids = {
		["Base"] = cubeUuid,
		["X"] = cubeUuid,
		["Y"] = cubeUuid,
		["Z"] = cubeUuid
	}

	local centerThickness = 0.35
	local thickness = 0.2
	local length = 1.5

	self.transformGizmo = EffectSet.new(transformGizmoUuids)

	self.transformGizmo:setOffsetTransforms({
		["Base"] = {nil, nil, sm.vec3.one() * centerThickness},
		["X"] = {PosX * length / 2, nil, sm.vec3.new(length, thickness, thickness)},
		["Y"] = {PosY * length / 2, nil, sm.vec3.new(thickness, length, thickness)},
		["Z"] = {PosZ * length / 2, nil, sm.vec3.new(thickness, thickness, length)}
	})

	self.transformGizmo:setParameter("Base", "color", self.constants.colours.white)
	self.transformGizmo:setParameter("X", "color", self.constants.colours.red)
	self.transformGizmo:setParameter("Y", "color", self.constants.colours.green)
	self.transformGizmo:setParameter("Z", "color", self.constants.colours.blue)

	self.transformGizmo:setScale(SubdivideRatio)
end


function BetterPlacementCoreV2:reset()
	
	self.phase0.placementIsValid = false

	self.phase0.raycastStorage = nil

	self.status = {
		lockedSelection = false,
		verticalPositioning = false,
		phase = 0
	}

	self.partVisualization:visualize("None")
end


function BetterPlacementCoreV2:start()
	
end


function BetterPlacementCoreV2:stop()
	
	self:reset()
end


function BetterPlacementCoreV2:evaluateRaycast(raycastResult)
	
	if not UsefulUtils.contains(raycastResult.type, self.constants.supportedSurfaces) then
		return false
	end
	
	if raycastResult.type == "joint" and sm.item.isJoint(self.currentItem) then
		return false
	end

	if not self.constants.isSupportedItem(self.currentItem) then
		return false
	end

	return UsefulUtils.isPlaceableFace(raycastResult, sm.vec3.closestAxis(raycastResult.normalLocal))
end


function BetterPlacementCoreV2:onToggle()
	
	if self.status.phase == 0 then
		
		self.phase0.rotationStorage[tostring(self.currentItem)][self.placementAxis] = (self.phase0.rotationStorage[tostring(self.currentItem)][self.placementAxis] + 1) % 4
	
	elseif self.status.phase == 1 then

		self.status.verticalPositioning = not self.status.verticalPositioning

		self.status.cursorHasMoved = false
	end
end


function BetterPlacementCoreV2:onReload()
	
	if self.status.phase == 0 then
		
		self.status.lockedSelection = not self.status.lockedSelection
	end
end


---@param item Uuid
function BetterPlacementCoreV2:generateRotationStorage(item)
	
	if self.phase0.rotationStorage[tostring(item)] == nil then
		
		self.phase0.rotationStorage[tostring(item)] = {
			["+X"] = 0,
			["+Y"] = 0,
			["+Z"] = 0,
			["-X"] = 0,
			["-Y"] = 0
		}
	end
end

-- #region Phases

function BetterPlacementCoreV2:doPhase0()
	
	sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Rotate")
	sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Lock to Face")

	if not self.status.lockedSelection then

		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Lock to Face")

		self.phase0.placementIsValid = self:evaluateRaycast(self.raycastResult)

		if self.phase0.placementIsValid then

			self.phase0.raycastStorage = self.raycastResult

			self.phase0.faceData = UsefulUtils.getFaceDataFromRaycast(self.phase0.raycastStorage)
		end
	else
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Unlock Face")
	end

	if not self.phase0.placementIsValid then
		
		self.partVisualization:visualize("None")
		self.rotationGizmo:hideAll()

	else

		local faceData = self.phase0.faceData

		local surfaceDelta = UsefulUtils.raycastToPlane(self.raycastResult.originWorld, self.raycastResult.directionWorld, faceData.parentBody:transformPoint(faceData.localFaceCenterPos), faceData.parentBody.worldRotation * faceData.localFaceRot).pointLocal

		local x = surfaceDelta.x
		local y = surfaceDelta.y

		local a = x + y
		local b = x - y

		if math.max(math.abs(x), math.abs(y)) < SubdivideRatio_2 * self.constants.centerSize then
			
			-- Center
			self.placementAxis = "+Z"
		
		elseif a > 0 and b > 0 then
			
			-- Right
			self.placementAxis = "-X"

		elseif a > 0 and b <= 0 then

			-- Up
			self.placementAxis = "-Y"
		
		elseif a <= 0 and b > 0 then

			-- Down
			self.placementAxis = "+Y"
		
		else

			-- Left
			self.placementAxis = "+X"
		end

		-- Show Rotation Gizmo

		self.rotationGizmo:showOnly({self.placementAxis, "Base"})

		self.rotationGizmo:setPosition(faceData.parentBody:transformPoint(faceData.localFaceCenterPos))

		self.rotationGizmo:setRotation(faceData.parentBody.worldRotation * faceData.localFaceRot)

		-- Calculate final position and rotation

		self.phase0.localPlacementRot = faceData.localFaceRot * Axes[self.placementAxis] * RotationList[self.phase0.rotationStorage[tostring(self.currentItem)][self.placementAxis]]

		self.phase0.localPlacementPos = UsefulUtils.snapVolumeToSurface(UsefulUtils.absVec(self.phase0.localPlacementRot * sm.item.getShapeSize(self.currentItem) * SubdivideRatio), UsefulUtils.clampVec(surfaceDelta, SubdivideRatio_2), faceData.localFaceCenterPos, faceData.localNormal, self.settings.roundingSetting)

		-- Show Part preview

		self.partVisualization:visualize("Blue")

		self.partVisualization:setParent(faceData.parentBody)

		self.partVisualization:setTransforms(self.phase0.localPlacementPos, self.phase0.localPlacementRot)
	end

	if self.primaryState == 1 and self.phase0.placementIsValid then

		self:preparePhase1()
		
		self.status.phase = 1
	end
end


function BetterPlacementCoreV2:preparePhase1()

	local faceData = self.phase0.faceData
	
	self.phase1.parentBody = faceData.parentBody

	self.phase1.parentObject = faceData.parentObject

	self.phase1.localNormal = faceData.localNormal

	self.phase1.surfaceRot = faceData.localFaceRot

	self.phase1.partPos = self.phase0.localPlacementPos

	self.phase1.cursorPos = self.phase0.localPlacementPos

	self.phase1.partRot = self.phase0.localPlacementRot

	self.phase1.shapeOffset = self.phase0.localPlacementRot * sm.item.getShapeOffset(self.currentItem)

	self.partVisualization:visualize("Blue")

	self.rotationGizmo:hideAll()
end


function BetterPlacementCoreV2:doPhase1()

	local localRaycastOrigin = UsefulUtils.worldToLocalPos(self.raycastResult.originWorld, self.phase1.parentBody)

	local localRaycastDirection = UsefulUtils.worldToLocalDir(self.raycastResult.directionWorld, self.phase1.parentBody)

	local phase1 = self.phase1
	
	if not self.status.verticalPositioning then
		
		phase1.cursorPos = UsefulUtils.raycastToPlane(localRaycastOrigin, localRaycastDirection, phase1.cursorPos, phase1.surfaceRot).pointWorld

		self.transformGizmo:showOnly({"X", "Y", "Base"})
	else

		phase1.cursorPos = UsefulUtils.raycastToLine(localRaycastOrigin, localRaycastDirection, phase1.cursorPos, sm.quat.getAt(phase1.surfaceRot)).pointWorld

		self.transformGizmo:showOnly({"Z", "Base"})
	end

	phase1.partPos = UsefulUtils.roundVecToGrid(phase1.cursorPos - phase1.shapeOffset) + phase1.shapeOffset

	self.partVisualization:setTransforms(phase1.partPos, phase1.partRot)

	self.transformGizmo:setPositionAndRotation(phase1.partPos, phase1.surfaceRot)

	if (self.settings.doubleClick and self.primaryState == 1) or (not self.settings.doubleClick and self.primaryState  == 3) then
		
		self:preparePhase2()

		self.status.phase = 2
	end
end


function BetterPlacementCoreV2:preparePhase2()
	
	self.phase2.parentObject = self.phase1.parentObject

	self.phase2.partPos = self.phase1.partPos

	self.phase2.partRot = self.phase1.partRot

	self.transformGizmo:hideAll()
end


function BetterPlacementCoreV2:doPhase2()

	local phase2 = self.phase2

	if phase2.parentObject == TerrainBody then
		
		phase2.parentObject = "terrain"
	end

	if phase2.parentObject == LiftBody then
		
		phase2.parentObject = "lift"
	end

	BetterPlacementClass.network:sendToServer("sv_createPart", {self.currentItem, phase2.parentObject, phase2.partPos, phase2.partRot})

	self:reset()
end

-- #endregion

function BetterPlacementCoreV2:doFrame()

	local deltaX, deltaY = sm.localPlayer.getMouseDelta()

	if deltaX ~= 0 or deltaY ~= 0 then
		
		self.status.cursorHasMoved = true
	end
	
	_, self.raycastResult = sm.localPlayer.getRaycast(self.settings.placementRadii)

	local lastItem = self.currentItem

	self.currentItem = sm.localPlayer.getActiveItem()

	self.itemHasChanged = (lastItem ~= self.currentItem)

	if self.itemHasChanged then

		self.partVisualization:setPart(self.currentItem)
		
		self:reset()

		self:generateRotationStorage(self.currentItem)
	end
	
	self.phases[self.status.phase](self)
end