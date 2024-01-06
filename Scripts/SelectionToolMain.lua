
dofile("$CONTENT_DATA/Scripts/LoadBasics.lua")

dofile("$CONTENT_DATA/Scripts/PieMenu.lua")

dofile("$CONTENT_DATA/Scripts/SelectionToolModules.lua")

SelectionToolTemplateClass = class()


function SelectionToolTemplateClass:server_onCreate()
	
	self.sv_modules = GetSelectionToolModules()

	-- Register serverside functions: SelectionToolClass.createPart becomes SelectionToolModules.svcallbacks.createPart

	for name, func in pairs(self.sv_modules.sv_callbacks) do
			
		self[name] = function (_, args) 
			func(args)
		end
	end
end


function SelectionToolTemplateClass:client_onCreate()
	
	if SelectionToolClass == nil then

		sm.gui.chatMessage("Initializing SelectionTool")
		print("Initializing SelectionTool")

		self.toolUuid = sm.uuid.new("79f915b5-25cf-485c-9022-23becf9b3e09")

		SelectionToolInstances = 1
	
		self.instanceIndex = 1

		-- Create global access point

		---@type ToolClass
		SelectionToolClass = self

		-- Get SelectionToolModules

		self.modules = GetSelectionToolModules()

		-- Register clientside functions: SelectionToolClass.createPart becomes SelectionToolModules.clcallbacks.createPart

		for name, func in pairs(self.modules.cl_callbacks) do
				
			self[name] = function (_, args) 
				func(args)
			end
		end

		-- Constants

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
			[0] = self.modules.modules.back,
			[1] = self.modules.modules.move,
			[2] = self.modules.modules.duplicate,
			[3] = self.modules.modules.back,
			[4] = self.modules.modules.back -- Temp
		}

		self.settings = {
			onlySwitchAxisWhenMouseIsInActive = false
		}
	
		sm.gui.chatMessage("Initialized SelectionTool")
		print("Initialized SelectionTool")
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
	
	self:reset()

	if self == SelectionToolClass then
		
		SelectionToolClass = nil
	end
end


function SelectionToolTemplateClass:reset()

	if self.currentPhase == "execute" then
		
		self.sandBox:stop() -- This takes care of resetting
	
	else
		self.sandBox = {}
		self.currentPhase = "start"
		self.pieMenu:close()
		self.highLightEffect:stop()
	end
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

function SelectionToolTemplateClass:client_onEquippedUpdate(primaryState, secondaryState, forceBuild)

	SelectionToolClass.primaryState = primaryState
	SelectionToolClass.secondaryState = secondaryState
	SelectionToolClass.forceBuild = forceBuild

	-- The first parameter doesn't work for some reason

	return false, false
end


function SelectionToolTemplateClass:client_onUpdate()

	if SelectionToolClass == nil then
		self:client_onCreate()
	end

	if self ~= SelectionToolClass then
		return
	end

	if sm.localPlayer.getActiveItem() == self.toolUuid then
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

-- #region Phase Management

function SelectionToolTemplateClass:doPhase0()
	
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
			network = self.network,
			terminate = function ()
				self.currentPhase = "start"
				self:reset()
			end,
			settings = self.settings,

			doFrame = self.actions[self.currentAction].doFrame,
			start = self.actions[self.currentAction].start,
			stop = self.actions[self.currentAction].stop,

		}

		-- Update variables

		self.sandBox.primaryState = self.primaryState
		self.sandBox.secondaryState = self.secondaryState
		self.sandBox.toggleState = self.toggleState
		self.sandBox.reloadState = self.reloadState
		self.forceBuild = self.forceBuild
		self.sandBox.raycastResult = self.raycastResult

		self.sandBox:start()

		-- Next phase
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

	self.sandBox:doFrame()
end

-- #endregion
