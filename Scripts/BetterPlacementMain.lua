

dofile("$CONTENT_DATA/Scripts/BetterPlacementCoreV2.lua")

dofile("$CONTENT_DATA/Scripts/PlacementSettingsGUI.lua")

dofile("$CONTENT_DATA/Scripts/LoadBasics.lua")

---@class BetterPlacementTemplateClass:ToolClass

BetterPlacementTemplateClass = class()


function BetterPlacementTemplateClass:client_onCreate()

	self.placementCore = BetterPlacementCoreV2

	self.guiClass = PlacementSettingsGUI

	-- Managing Instances

	if BetterPlacementToolInstances == nil  or BetterPlacementToolInstances == 0 then

		sm.gui.chatMessage("Initializing BetterPlacement Mod")
		print("Initializing BetterPlacement Mod")
		
		BetterPlacementToolInstances = 1
	
		self.instanceIndex = 1
		
		-- 'self' is actually not BetterPlacementTemplateClass
		-- We write the following line so that other classes can also refer to 'self'.
	
		BetterPlacementClass = self
		
		-- Setup callback system

		BetterPlacementClass.linkCallback = UsefulUtils.linkCallback
		
		self.placementCore.settings = sm.json.open("$CONTENT_DATA/Scripts/settings.json")

		self.placementCore:initialize()

		self.guiClass:initialize()
		


		BetterPlacementClass.toolUuid = sm.uuid.new("74febb3f-cc08-4e02-89c8-9fd0d0a1aa3c")

		BetterPlacementClass.on = false

		sm.gui.chatMessage("Initialized BetterPlacement Mod")
		print("Initialized BetterPlacement Mod")
	else

		BetterPlacementToolInstances = BetterPlacementToolInstances + 1

		self.instanceIndex = BetterPlacementToolInstances
	end
end


function BetterPlacementTemplateClass:client_onRefresh()

	self:client_onCreate()
end


function BetterPlacementTemplateClass:client_onDestroy()

	sm.json.save(self.placementCore.settings, "$CONTENT_DATA/Scripts/settings.json")

	BetterPlacementToolInstances = BetterPlacementToolInstances - 1
end

-- On/Off

function BetterPlacementTemplateClass.client_onReload(self)

	if self.instanceIndex == 1 and sm.localPlayer.getActiveItem() ~= BetterPlacementClass.toolUuid then -- not holding a BetterPlacement tool
		
		self.placementCore:onReload()
	else

		BetterPlacementClass.on = not BetterPlacementClass.on

		if BetterPlacementClass.on then

			sm.gui.displayAlertText("Use Better Placement:\n#00ff00True", 2)
		else

			sm.gui.displayAlertText("Use Better Placement:\n#ff0000False", 2)
		end
	end

	return true
end

-- Rotation

function BetterPlacementTemplateClass.client_onToggle(self)

	if self.instanceIndex == 1 and sm.localPlayer.getActiveItem() ~= BetterPlacementClass.toolUuid then -- not holding a BetterPlacement tool
		
		self.placementCore:onToggle()
	else

		self.guiClass:onToggle()
	end

	return true
end

function BetterPlacementTemplateClass.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)

	self.placementCore.primaryState = primaryState

	-- The first parameter doesn't work for some reason

	return false, false
end

function BetterPlacementTemplateClass:client_onUpdate()

	if self.instanceIndex ~= 1 then
		return
	end

	local item = sm.localPlayer.getActiveItem()

	if item == BetterPlacementClass.toolUuid then

		if BetterPlacementClass.on then
			sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Disable Better Placement")
		
		else
			sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Enable Better Placement")
		end
		
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Open Settings GUI") -- https://scrapmechanictools.com/modding_help/Keybind_Names

		self.isEquipped = true
	else

		self.isEquipped = false
	end

	if self.on then

		self.placementCore:doFrame()
	end
end
