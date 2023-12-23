
dofile("$CONTENT_DATA/Scripts/LoadBasics.lua")

dofile("$CONTENT_DATA/Scripts/PieMenu.lua")

dofile("$CONTENT_DATA/Scripts/SelectionToolModules.lua")

SelectionToolTemplateClass = class()


function SelectionToolTemplateClass:server_onCreate()
	
	self.sv_modules = GetSelectionToolModules()

	-- Register serverside functions: SelectionToolClass.createPart becomes SelectionToolModules.sv.createPart

	for name, func in pairs(self.sv_modules.sv) do
			
		self[name] = function (_, args) 
			func(args)
		end
	end
end


function SelectionToolTemplateClass:client_onCreate()
	
	if SelectionToolInstances == nil or SelectionToolInstances == 0 or BPDebug then

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
			[0] = self.back,
			[1] = self.modules.cl.move,
			[2] = self.modules.cl.duplicate,
			[3] = self.back,
			[4] = self.back -- Temp
		}

		self.settings = {
			onlySwitchAxisWhenMouseIsInActive = false
		}
	
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

	print("reset")

	if self.currentPhase == "execute" then
		
		self.sandBox.secondaryState = 1 -- Fake a right button press(the reset button)

		self.sandBox.reset = function ()
			
		end -- self.sandBox.reset calls self.reset, We need to block it to prevent a loop

		self.actions[self.currentAction](self.sandBox)
	end
	
	self.sandBox = {}
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
			initialize = true,
			network = self.network
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

	print(SelectionToolClass.lastOn, (sm.localPlayer.getActiveItem() == self.toolUuid))

	if self.instanceIndex == 1 and sm.localPlayer.getActiveItem() == self.toolUuid then
		self.raycastSuccess, self.raycastResult = sm.localPlayer.getRaycast(7.5)

		self.pieMenu:doFrame()

		self.phases[self.currentPhase](self)

		-- Reset various states

		self.toggleState = false
		self.reloadState = false

		self.lastOn = true
	end
	
	if self.instanceIndex == 1 and sm.localPlayer.getActiveItem() ~= self.toolUuid then
		
		if self.lastOn == true then
			self:reset()
		end
	
		self.lastOn = false
	end
end
