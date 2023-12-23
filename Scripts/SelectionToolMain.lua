
dofile("$CONTENT_DATA/Scripts/LoadBasics.lua")

dofile("$CONTENT_DATA/Scripts/PieMenu.lua")

SelectionToolTemplateClass = class()


function SelectionToolTemplateClass:client_onCreate()
	
	if SelectionToolInstances == nil or SelectionToolInstances == 0 or BPDebug then

		sm.gui.chatMessage("Initializing SelectionTool")
		print("Initializing SelectionTool")

		self.toolUuid = sm.uuid.new("79f915b5-25cf-485c-9022-23becf9b3e09")

		SelectionToolInstances = 1
	
		self.instanceIndex = 1

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
			[3] = self.delete,
			[4] = self.back -- Temp
		}

		self.settings = {
			onlySwitchAxisWhenMouseIsInActive = false
		}

		-- Create global access point

		---@type ToolClass
		SelectionToolClass = self
		
		UsefulUtils.linkCallback(SelectionToolClass, "sv_createPart", UsefulUtils.sv_createPart, -1, true)
		UsefulUtils.linkCallback(SelectionToolClass, "sv_destroyPart", UsefulUtils.sv_destroyPart, -1, true)
	
		sm.gui.chatMessage("Initialized SelectionTool")
		print("Initialized SelectionTool")
	else
		SelectionToolInstances = SelectionToolInstances + 1

		self.instanceIndex = SelectionToolInstances
	end
end


function SelectionToolTemplateClass:client_onToggle()
	
	SelectionToolClass.toggleState = true

	return true
end


function SelectionToolTemplateClass:client_onReload()
	
	SelectionToolClass.reloadState = true

	return true
end


function SelectionToolTemplateClass:client_onRefresh()
	
	self:client_onCreate()
end


function SelectionToolTemplateClass:client_onDestroy()
	
	self.highLightEffect:stop()

	SelectionToolInstances = SelectionToolInstances - 1
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

-- #region Phase Management

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

	UsefulUtils.highlightShape(self.highLightEffect, self.shape)

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

-- #endregion

-- #region Modules

-- #region Move

function SelectionToolTemplateClass.move(sandBox)

	if sandBox.initialize == true then

		if sandBox.shape:getInteractable() ~= nil then
		end
		
		-- sandBox.initialize will be set to false by SelectionToolClass:duplicate, we don't do it yet
	end
	
	-- Use the duplicate function for controls
	SelectionToolClass.duplicate(sandBox, false)

	-- Add deletion indicator

	sandBox.highLightEffect:setParameter("valid", false)

	UsefulUtils.highlightShape(sandBox.highLightEffect, sandBox.shape)

	-- Overwrite Hotkeys

	sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Rotate Axis")
	sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Relocate")

	if sandBox.reloadState then
		
		SelectionToolClass.network:sendToServer("sv_move", {sandBox.shape, sandBox.partPos, sandBox.parentBody})
	end

	if sandBox.reloadState or sandBox.secondaryState ~= 0 then -- Reset conditions
		
		sandBox.highLightEffect:stop()
		sandBox.highLightEffect:setParameter("valid", true)
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

	if originalShape.interactable ~= nil then -- Copy over interactable properties

		local children = originalShape.interactable:getChildren()
		
		for _, child in pairs(children) do

			newShape.interactable:connect(child)
		end

		local parents = originalShape.interactable:getParents()

		for _, parent in pairs(parents) do
			
			parent:connect(newShape.interactable)
		end

		local joints = originalShape.interactable:getJoints()

		for _, joint in pairs(joints) do
			
			-- newShape.interactable:connectToJoint(joint)
		end
	end

	-- Destroy originalShape
	originalShape:destroyPart(0)
end

-- #endregion

-- #region Duplicate

function SelectionToolTemplateClass.duplicate(sandBox, isMain)

	if isMain == nil then
		isMain = true
	end

	-- Compatibility for move
	if isMain == true then
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Rotate Axis")
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Paste")
	end

	if sandBox.initialize then
		
		-- Create visualizationEffect

		sandBox.visualizationEffect = SmartEffect.new(sandBox.shape.uuid)

		sandBox.visualizationEffect:setParameter("color", sandBox.shape:getColor())
		sandBox.visualizationEffect:setScale(SubdivideRatio)
		sandBox.visualizationEffect:start()

		-- Create transformGizmo
		
		sandBox.transformGizmo = BPEffects.createTransformGizmo()

		-- We don't need highLightEffect

		sandBox.highLightEffect:stop()

		sandBox.parentBody = sandBox.shape:getBody()

		sandBox.directionNum = 0

		sandBox.vecDirections = {
			[0] = PosX,
			[1] = PosY,
			[2] = PosZ
		}

		sandBox.strDirections = {
			[0] = "X",
			[1] = "Y",
			[2] = "Z"
		}

		sandBox.direction = PosX
		sandBox.transformGizmo:showOnly({"X", "Base"})

		sandBox.partPos = UsefulUtils.getActualLocalPos(sandBox.shape)
		sandBox.cursorPos = sandBox.partPos
		sandBox.initialOffset = 0

		sandBox.initialize = false
	end

	local localRaycastOrigin = UsefulUtils.worldToLocalPos(sandBox.raycastResult.originWorld, sandBox.parentBody)

	local localRaycastDirection = UsefulUtils.worldToLocalDir(sandBox.raycastResult.directionWorld, sandBox.parentBody)
	
	if sandBox.toggleState then

		if sandBox.settings.onlySwitchAxisWhenMouseIsInActive and sandBox.primaryState ~= 0 then
			
			goto skip
		end
		
		sandBox.directionNum = sandBox.directionNum + 1
		
		if sandBox.directionNum == 3 then
			sandBox.directionNum = 0
		end
		
		sandBox.direction = sandBox.vecDirections[sandBox.directionNum]

		sandBox.transformGizmo:showOnly({sandBox.strDirections[sandBox.directionNum], "Base"})
	end
	
	::skip::

	if sandBox.primaryState == 1 or sandBox.primaryState == 2 then -- If left mouse is clicked
		
		local offset = UsefulUtils.raycastToLine(localRaycastOrigin, localRaycastDirection, sandBox.cursorPos, sandBox.direction).pointLocal.z

		sandBox.cursorPos = sandBox.cursorPos + sandBox.direction * (offset - sandBox.initialOffset)

		sandBox.partPos = sandBox.partPos + UsefulUtils.roundVecToGrid(sandBox.cursorPos - sandBox.partPos)
	end

	-- Set position of visualizationEffect
	sandBox.visualizationEffect:setTransforms({sandBox.parentBody:transformPoint(sandBox.partPos), sandBox.shape.worldRotation, nil})

	-- Set position of transformGizmo
	sandBox.transformGizmo:setPositionAndRotation(sandBox.parentBody:transformPoint(sandBox.cursorPos), sandBox.parentBody.worldRotation)

	if sandBox.reloadState then -- If selection has ended

		if isMain then

			-- Build part
			
			SelectionToolClass.network:sendToServer("sv_createPart", {sandBox.shape.uuid, sandBox.parentBody, sandBox.partPos, sandBox.shape.localRotation, true, sandBox.shape.color})
		end
	end

	if sandBox.reloadState or sandBox.secondaryState ~= 0 then -- Reset conditions

		sandBox.visualizationEffect:destroy()
		sandBox.visualizationEffect = nil
		sandBox.transformGizmo:destroy()
		sandBox.transformGizmo = nil

		sandBox.reset()
	end
end

-- #endregion

-- #endregion

function SelectionToolTemplateClass:back()
	
	print("back")
	
	self.reset()
end

 
function SelectionToolTemplateClass:client_onEquippedUpdate(primaryState, secondaryState, forceBuild)

	SelectionToolClass.primaryState = primaryState
	SelectionToolClass.secondaryState = secondaryState
	SelectionToolClass.forceBuild = forceBuild

	-- The first parameter doesn't work for some reason

	return false, false
end


function SelectionToolTemplateClass:client_onUpdate()

	if self.instanceIndex == 1 and sm.localPlayer.getActiveItem() == self.toolUuid then
		self.raycastSuccess, self.raycastResult = sm.localPlayer.getRaycast(7.5)

		self.pieMenu:doFrame()

		self.phases[self.currentPhase](self)

		-- Reset various states

		self.toggleState = false
		self.reloadState = false
	end
	
	if sm.localPlayer.getActiveItem() ~= self.toolUuid then
		
		self:reset()
	end
end
