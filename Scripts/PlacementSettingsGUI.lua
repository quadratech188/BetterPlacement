
PlacementSettingsGUI = class()

-- The next 3 functions recieve BetterPlacementClass as self


function PlacementSettingsGUI:initialize()

	self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/PlacementSettingsGUI.layout")

	self.gui:createHorizontalSlider("PlacementRadius", 20, 7.5, "onGUIUpdate", true)

	self.buttons = {
		roundingMode = {
			["Center"] = "RoundingMode_Center",
			["Fixed"] = "RoundingMode_Fixed",
			["Dynamic"] = "RoundingMode_Dynamic"
		},
		clickMode = {
			[true] = "ClickMode_Twice",
			[false] = "ClickMode_Once"
		}
	}

	for _, button in pairs(self.buttons.roundingMode) do
		self.gui:setButtonCallback(button .. "T", "onGUIUpdate")
		self.gui:setButtonCallback(button .. "F", "onGUIUpdate")
	end

	for _, button in pairs(self.buttons.clickMode) do
		self.gui:setButtonCallback(button .. "T", "onGUIUpdate")
		self.gui:setButtonCallback(button .. "F", "onGUIUpdate")
	end

	BetterPlacementClass:linkCallback("onGUIUpdate", self.onGUIUpdate, -1)

	self:onGUIUpdate(nil)
end


function PlacementSettingsGUI:onGUIUpdate(data)
	
	self = PlacementSettingsGUI

	if type(data) == "string" then
		
		if data:sub(1, 12) == "RoundingMode" then

			for index, button in pairs(self.buttons.roundingMode) do
				if string.match(data, button) then
					BetterPlacementCoreV2.settings.roundingSetting = index
				end
			end
		else -- If it's ClickMode

			for index, button in pairs(self.buttons.clickMode) do
				
				if string.match(data, button) then
					BetterPlacementCoreV2.settings.doubleClick = index
				end
			end
		end
	end

	if type(data) == "number" then -- If it's PlacementRadius
		
		BetterPlacementCoreV2.settings.placementRadius = data
	end


	for index, button in pairs(self.buttons.clickMode) do
		
		if index == BetterPlacementCoreV2.settings.doubleClick then
			
			self.gui:setVisible(button .. "T", true)
			self.gui:setVisible(button .. "F", false)
		
		else
			self.gui:setVisible(button .. "T", false)
			self.gui:setVisible(button .. "F", true)
		end
	end

	for index, button in pairs(self.buttons.roundingMode) do
		
		if index == BetterPlacementCoreV2.settings.roundingSetting then
			
			self.gui:setVisible(button .. "T", true)
			self.gui:setVisible(button .. "F", false)
		
		else
			self.gui:setVisible(button .. "T", false)
			self.gui:setVisible(button .. "F", true)
		end
	end
end


function PlacementSettingsGUI:onToggle()

	self.gui:setButtonState(self.buttons.roundingMode[BetterPlacementCoreV2.settings.roundingSetting], true)

	self.gui:setButtonState(self.buttons.clickMode[BetterPlacementCoreV2.settings.doubleClick], true)
	
	self.gui:open()
end