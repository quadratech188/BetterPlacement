
dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")
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

	HighLightEffect = SmartEffect.new(sm.effect.createEffect("ShapeRenderable"))

	HighLightEffect:setScale(SubdivideRatio)

	HighLightEffect:setParameter("visualization", true)

	self.pieMenu = PieMenu.new("$CONTENT_DATA/Gui/SelectionToolPieMenu.layout", 4, 0.12)

	self.actions = {
		[0] = self.back,
		[1] = self.move,
		[2] = self.reset, -- Temp
		[3] = self.reset,
		[4] = self.reset -- Temp
	}
end


function SelectionToolTemplateClass:client_onRefresh()
	
	self:client_onCreate()
end


function SelectionToolTemplateClass:client_onDestroy()
	
	HighLightEffect:stop()
end


function SelectionToolTemplateClass:reset()
	
	self.currentPhase = "start"
	self.pieMenu:close()
end


function SelectionToolTemplateClass:doPhase0()

	-- print("start")

	sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select")

	if self.raycastSuccess then

		sm.gui.setInteractionText("", sm.gui.getKeyBinding("ForceBuild", true), "Actions...")
	end
	
	if self.raycastResult.type == "body" then

		self.shape = self.raycastResult:getShape()

		UsefulUtils.highlightShape(HighLightEffect, self.shape)

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
		
		HighLightEffect:stop()
	end
end


function SelectionToolTemplateClass:doPhase1()

	-- print("select")
	
	sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Release")
	sm.gui.setInteractionText("", sm.gui.getKeyBinding("ForceBuild", true), "Actions...")

	UsefulUtils.highlightShape(HighLightEffect, self.shape)

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

	if not self.forceBuild then
		self.currentAction = self.pieMenu:close()

		self.currentPhase = "execute"
	end
end


function SelectionToolTemplateClass:executeAction()
	
	print(self.currentAction)

	self.actions[self.currentAction](self)
end


function SelectionToolTemplateClass:move()
	
	print("move")

	self:reset()
end


function SelectionToolTemplateClass:back()
	
	print("back")
	
	self:reset()
end


function SelectionToolTemplateClass.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)

	self.primaryState = primaryState
	self.secondaryState = secondaryState
	self.forceBuild = forceBuild

	self.raycastSuccess, self.raycastResult = sm.localPlayer.getRaycast(7.5)

	self.pieMenu:doFrame()

	self.phases[self.currentPhase](self)


	-- The first parameter doesn't work for some reason

	return false, false
end