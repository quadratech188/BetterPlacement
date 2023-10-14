

dofile("$CONTENT_DATA/Scripts/BetterPlacementCore.lua")

dofile("$CONTENT_DATA/Scripts/BetterPlacementCoreV2.lua")

dofile("$SURVIVAL_DATA/Scripts/game/survival_shapes.lua")

dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")

dofile("$CONTENT_DATA/Scripts/EffectSet.lua")

dofile("$CONTENT_DATA/Scripts/PlacementSettingsGUI.lua")

---@class BetterPlacementTemplateClass:ToolClass

BetterPlacementTemplateClass = class()


function BetterPlacementTemplateClass:client_onCreate()

	sm.gui.chatMessage("Initializing BetterPlacement Mod")
	print("Initializing BetterPlacement Mod")

	-- References

	self.placementCore = BetterPlacementCoreV2

	self.guiClass = PlacementSettingsGUI

	-- Constants

	self.defaultSettings = {

		RoundingSetting = "SnapCornerToGrid", -- SnapCenterToGrid, DynamicSnapCornerToGrid, FixedSnapCornerToGrid
		PositionSelectionTimer = 5, -- Ticks before advancing to position selection
		PlacementRadii = 7.5, -- Reach distance
	}

	self.settingsData = {

		RoundingSettings = {"SnapCenterToGrid", "DynamicSnapCornerToGrid", "FixedSnapCornerToGrid"},
		MaxPositionSelectionTimer = 40,
		MaxPlacementRadii = 40
	}

	-- Setup callback system

	self.linkCallback = UsefulUtils.linkCallback

	-- Other

	self.on = false

	self.toolUuid = sm.uuid.new("74febb3f-cc08-4e02-89c8-9fd0d0a1aa3c")

	-- 'self' is actually not BetterPlacementTemplateClass, it's another object created by duplicating it and adding some extra parameters.
	-- We write the following line so that other classes can also refer to 'self'.

	BetterPlacementClass = self

	 self.settings = sm.json.open("$CONTENT_DATA/Scripts/settings.json")

	self.placementCore:initialize()

	self.guiClass:initialize()

	sm.gui.chatMessage("Initialized BetterPlacement Mod")
	print("Initialized BetterPlacement Mod")
end


function BetterPlacementTemplateClass:client_onRefresh()

	self:client_onCreate()
end


function BetterPlacementTemplateClass:client_onDestroy()

end

-- On/Off

function BetterPlacementTemplateClass.client_onReload(self)

	-- Is the tool selected

	if self.isEquipped then
		self.on = not self.on

		if self.on then

			sm.gui.displayAlertText("Use Better Placement:\n#00ff00True", 2)
		else

			sm.gui.displayAlertText("Use Better Placement:\n#ff0000False", 2)
		end
	else

		self.placementCore:onReload()
	end

	return true
end

-- Rotation

function BetterPlacementTemplateClass.client_onToggle(self)

	if self.isEquipped then

		self.guiClass:onToggle()
	else

		self.placementCore:onToggle()
	end

	return true
end

function BetterPlacementTemplateClass.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)

	self.placementCore.primaryState = primaryState

	-- The first parameter doesn't work for some reason

	return false, false
end

function BetterPlacementTemplateClass:client_onUpdate()

	local item = sm.localPlayer.getActiveItem()

	if item == self.toolUuid then

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

	local forceTool = self.placementCore.constants.isSupportedItem(item)

	if forceTool and self.on then

		sm.tool.forceTool(self.tool)
	else

		sm.tool.forceTool()
	end

	if self.on then

		self.placementCore:doFrame()
	end
end
