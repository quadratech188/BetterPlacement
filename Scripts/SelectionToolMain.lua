
dofile("$CONTENT_DATA/Scripts/LoadBasics.lua")

dofile("$CONTENT_DATA/Scripts/PieMenu.lua")

SelectionToolTemplateClass = class()


function SelectionToolTemplateClass:client_onCreate()
	
	self.phases = {
		["start"] = self.doPhase0,
		["select"] = self.doPhase1,
		["actionSelect"] = self.doActionSelect,
		["execute"] = self.executeAction
	}

	self.currentPhase = "start"
	
	self.highLightEffect = SmartEffect.new(sm.effect.createEffect("ShapeRenderable"))

	self.highLightEffect:setScale(SubdivideRatio)

	self.highLightEffect:setParameter("visualization", true)

	self.pieMenu = PieMenu.new("$CONTENT_DATA/Gui/SelectionToolPieMenu.layout", 4, 0.12)

	self.actions = {
		[0] = self.back,
		[1] = self.move,
		[2] = self.duplicate,
		[3] = self.back,
		[4] = self.back -- Temp
	}

	self.settings = {
		onlySwitchAxisWhenMouseIsInActive = false
	}

	-- Create global access point

	---@type ToolClass
	SelectionToolClass = self
	
	UsefulUtils.linkCallback(SelectionToolClass, "sv_createPart", UsefulUtils.sv_createPart, -1)
end


function SelectionToolTemplateClass:client_onToggle()
	
	self.toggleState = true

	return true
end


function SelectionToolTemplateClass:client_onReload()
	
	self.reloadState = true

	return true
end


function SelectionToolTemplateClass:client_onRefresh()
	
	self:client_onCreate()
end


function SelectionToolTemplateClass:client_onDestroy()
	
	self.highLightEffect:stop()
end


function SelectionToolTemplateClass:reset()
	
	self.currentPhase = "start"
	self.pieMenu:close()
	self.highLightEffect:stop()
end


function SelectionToolTemplateClass:evaluateRaycast()
	
	if self.raycastResult.type ~= "body" then
		return false
	end

	if sm.item.isBlock(self.raycastResult:getShape():getShapeUuid()) then
		return false
	end
	
	return true
end


function SelectionToolTemplateClass:doPhase0()

	-- print("start")
	
	if self:evaluateRaycast() then

		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select")
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("ForceBuild", true), "Actions...")

		---@type Shape
		self.shape = self.raycastResult:getShape()

		UsefulUtils.highlightShape(self.highLightEffect, self.shape)

		self.pieMenu:setPosition(self.shape:getWorldPosition())
	
		if self.primaryState == 1 then
			self.currentPhase = "select"
		end

		if self.forceBuild then
			self.pieMenu:open()
			self.currentPhase = "actionSelect"
		end
	else

		self.shape = nil
		
		self.highLightEffect:stop()
	end
end


function SelectionToolTemplateClass:doPhase1()

	if not sm.exists(self.shape) then
		self:reset()
		return
	end

	-- print("select")
	
	sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Release")
	sm.gui.setInteractionText("", sm.gui.getKeyBinding("ForceBuild", true), "Actions...")

	UsefulUtils.highlightShape(self.highLightEffect, self.shape)

	self.pieMenu:setPosition(self.shape:getWorldPosition())

	if self.primaryState == 1 then
		self.currentPhase = "start"
	end

	if self.forceBuild then

		self.pieMenu:open()
		self.currentPhase = "actionSelect"
	end
end


function SelectionToolTemplateClass:doActionSelect()

	if not sm.exists(self.shape) then
		self:reset()
		return
	end

	if not self.forceBuild then
		self.currentAction = self.pieMenu:close()

		-- Prepare sandbox for actions

		self.sandBox = {
			shape = self.shape,
			highLightEffect = self.highLightEffect,
			initialize = true
		}

		self.currentPhase = "execute"
	end
end


function SelectionToolTemplateClass:executeAction()

	if not sm.exists(self.shape) then
		self:reset()
		return
	end

	-- Update variables

	self.sandBox.primaryState = self.primaryState
	self.sandBox.secondaryState = self.secondaryState
	self.sandBox.toggleState = self.toggleState
	self.sandBox.reloadState = self.reloadState
	self.forceBuild = self.forceBuild
	self.sandBox.raycastResult = self.raycastResult
	self.sandBox.reset = function ()
		self:reset()
	end
	self.sandBox.settings = self.settings

	self.actions[self.currentAction](self.sandBox)
end


function SelectionToolTemplateClass:move()

	if self.initialize == true then

		if self.shape:getInteractable() ~= nil then
		end
		
		-- self.initialize will be set to false by SelectionToolClass:duplicate, we don't do it yet
	end
	
	-- Use the duplicate function for controls
	SelectionToolClass.duplicate(self, false)

	-- Add deletion indicator

	self.highLightEffect:setParameter("valid", false)

	UsefulUtils.highlightShape(self.highLightEffect, self.shape)

	-- Overwrite Hotkeys

	sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Rotate Axis")
	sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Relocate")

	if self.reloadState then
		
		SelectionToolClass.network:sendToServer("sv_move", {self.shape, self.partPos, self.parentBody})
	end

	if self.reloadState or self.secondaryState ~= 0 then -- Reset conditions
		
		self.highLightEffect:stop()
		self.highLightEffect:setParameter("valid", true)
	end
end


function SelectionToolTemplateClass:sv_move(args)
	
	---@type Shape
	local originalShape = args[1]

	---@type Vec3
	local newPosition = args[2]

	---@type Body
	local parentBody = args[3]

	-- Create new shape
	---@type Shape
	local newShape = UsefulUtils.sv_createPart(nil, {originalShape.uuid, parentBody, newPosition, originalShape.localRotation, true, originalShape.color})
	
	print(originalShape)
	print(newShape)

	if originalShape.usable then -- Copy over interactable properties

		local children = originalShape.interactable:getChildren()
		
		for _, child in pairs(children) do

			newShape.interactable:connect(child)
		end

		local joints = originalShape.interactable:getJoints()

		for _, joint in pairs(joints) do
			
			newShape.interactable:connectToJoint(joint)
		end
	end

	-- Destroy originalShape
	originalShape:destroyPart(0)
end


function SelectionToolTemplateClass:duplicate(isMain)

	if isMain == nil then
		isMain = true
	end

	-- Compatibility for move
	if isMain == true then
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Rotate Axis")
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Paste")
	end

	if self.initialize then
		
		-- Create visualizationEffect

		self.visualizationEffect = SmartEffect.new(self.shape.uuid)

		self.visualizationEffect:setParameter("color", self.shape:getColor())
		self.visualizationEffect:setScale(SubdivideRatio)
		self.visualizationEffect:start()

		-- Create transformGizmo
		
		self.transformGizmo = BPEffects.createTransformGizmo()

		-- We don't need highLightEffect

		self.highLightEffect:stop()

		self.parentBody = self.shape:getBody()

		self.directionNum = 0

		self.vecDirections = {
			[0] = PosX,
			[1] = PosY,
			[2] = PosZ
		}

		self.strDirections = {
			[0] = "X",
			[1] = "Y",
			[2] = "Z"
		}

		self.direction = PosX
		self.transformGizmo:showOnly({"X", "Base"})

		self.partPos = UsefulUtils.getActualLocalPos(self.shape)
		self.cursorPos = self.partPos
		self.initialOffset = 0

		self.initialize = false
	end

	local localRaycastOrigin = UsefulUtils.worldToLocalPos(self.raycastResult.originWorld, self.parentBody)

	local localRaycastDirection = UsefulUtils.worldToLocalDir(self.raycastResult.directionWorld, self.parentBody)
	
	if self.toggleState then

		if self.settings.onlySwitchAxisWhenMouseIsInActive and self.primaryState ~= 0 then
			
			goto skip
		end
		
		self.directionNum = self.directionNum + 1
		
		if self.directionNum == 3 then
			self.directionNum = 0
		end
		
		self.direction = self.vecDirections[self.directionNum]

		self.transformGizmo:showOnly({self.strDirections[self.directionNum], "Base"})
	end
	
	::skip::

	if self.primaryState == 1 or self.primaryState == 2 then -- If left mouse is clicked
		
		local offset = UsefulUtils.raycastToLine(localRaycastOrigin, localRaycastDirection, self.cursorPos, self.direction).pointLocal.z

		self.cursorPos = self.cursorPos + self.direction * (offset - self.initialOffset)

		self.partPos = self.partPos + UsefulUtils.roundVecToGrid(self.cursorPos - self.partPos)
	end

	-- Set position of visualizationEffect
	self.visualizationEffect:setTransforms({self.parentBody:transformPoint(self.partPos), self.shape.worldRotation, nil})

	-- Set position of transformGizmo
	self.transformGizmo:setPositionAndRotation(self.parentBody:transformPoint(self.cursorPos), self.parentBody.worldRotation)

	if self.reloadState then -- If selection has ended

		if isMain then

			-- Build part
			
			SelectionToolClass.network:sendToServer("sv_createPart", {self.shape.uuid, self.parentBody, self.partPos, self.shape.localRotation, true, self.shape.color})
		end
	end

	if self.reloadState or self.secondaryState ~= 0 then -- Reset conditions

		self.visualizationEffect:destroy()
		self.visualizationEffect = nil
		self.transformGizmo:destroy()
		self.transformGizmo = nil

		self.reset()
	end
end


function SelectionToolTemplateClass:back()
	
	print("back")
	
	self.reset()
end

 
function SelectionToolTemplateClass:client_onEquippedUpdate(primaryState, secondaryState, forceBuild)

	self.primaryState = primaryState
	self.secondaryState = secondaryState
	self.forceBuild = forceBuild

	self.raycastSuccess, self.raycastResult = sm.localPlayer.getRaycast(7.5)

	self.pieMenu:doFrame()

	self.phases[self.currentPhase](self)

	-- Reset various states

	self.toggleState = false
	self.reloadState = false

	-- The first parameter doesn't work for some reason

	return false, false
end


function SelectionToolTemplateClass:client_onUpdate()
	
	if self.tool:isEquipped() == false then
		
		self:reset()
	end
end