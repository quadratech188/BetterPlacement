

dofile("$CONTENT_DATA/Scripts/BetterPlacementCoreV2.lua")

dofile("$CONTENT_DATA/Scripts/PlacementSettingsGUI.lua")

dofile("$CONTENT_DATA/Scripts/LoadBasics.lua")

---@class BetterPlacementTemplateClass:ToolClass

BetterPlacementTemplateClass = class()


function BetterPlacementTemplateClass:onGUIUpdate(data)
	
	BetterPlacementClass.guiClass:onGUIUpdate(data)
end


function BetterPlacementTemplateClass:client_onCreate()

	if BetterPlacementClass == nil then -- If main tool doesn't exist

		-- Become main tool

		sm.gui.chatMessage("Initializing BetterPlacement Tool")
		print("Initializing BetterPlacement Tool")
	
		BetterPlacementClass = self
		
		-- Setup callback system

		self.linkCallback = UsefulUtils.linkCallback

		self.placementCore = BetterPlacementCoreV2
		
		self.placementCore.settings = sm.json.open("$CONTENT_DATA/Scripts/settings.json")

		self.placementCore:initialize()

		self.guiClass = GetPlacementSettingsGUI()

		self.toolUuid = sm.uuid.new("74febb3f-cc08-4e02-89c8-9fd0d0a1aa3c")

		self.on = false

		UsefulUtils.linkCallback(self, "sv_createPart", UsefulUtils.sv_createPart, -1, true)

		sm.gui.chatMessage("Initialized BetterPlacement Tool")
		print("Initialized BetterPlacement Tool")
	end

	-- Add self to list

	if BetterPlacementTools == nil then
		BetterPlacementTools = {}
	end

	table.insert(BetterPlacementTools, #BetterPlacementTools + 1, self)
end


function BetterPlacementTemplateClass:client_onRefresh()

	BetterPlacementClass = nil

	BetterPlacementTools = nil

	print("Refresh")

	self:client_onCreate()
end


function BetterPlacementTemplateClass:client_onDestroy()

	if BetterPlacementClass == self then

		sm.json.save(self.placementCore.settings, "$CONTENT_DATA/Scripts/settings.json")
		
		BetterPlacementClass = nil
	end
end

-- On/Off

function BetterPlacementTemplateClass.client_onReload(self)

	if sm.localPlayer.getActiveItem() ~= BetterPlacementClass.toolUuid then -- not holding a BetterPlacement tool
		
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

	if sm.localPlayer.getActiveItem() ~= BetterPlacementClass.toolUuid then -- not holding a BetterPlacement tool
		
		BetterPlacementClass.placementCore:onToggle()
	else

		BetterPlacementClass.guiClass:onToggle()
	end

	return true
end

function BetterPlacementTemplateClass.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)

	BetterPlacementClass.placementCore.primaryState = primaryState

	-- The first parameter doesn't work for some reason

	return false, false
end

function BetterPlacementTemplateClass:client_onUpdate()

	if BetterPlacementClass == nil then -- If main class was removed
		
		self:client_onCreate()
	end

	if self ~= BetterPlacementClass then
		return
	end

	if sm.localPlayer.getActiveItem() == BetterPlacementClass.toolUuid then

		if self.on then
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
