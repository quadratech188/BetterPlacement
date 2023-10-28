
PlacementSettingsGUI = class()

-- The next 3 functions recieve BetterPlacementClass as self


function PlacementSettingsGUI:initialize()

	self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/PlacementSettingsGUI.layout")

	self.gui:createHorizontalSlider("PlacementRadius", 20, 7.5, "onGUIUpdate", true)

	self.roundingModeButtons = {
		["Center"] = "RoundingMode_Center",
		["Fixed"] = "RoundingMode_Fixed",
		["Dynamic"] = "RoundingMode_Dynamic"
	}

	for _, button in pairs(self.roundingModeButtons) do
		self.gui:setButtonCallback(button, "onGUIUpdate")
	end

	BetterPlacementClass:linkCallback("onGUIUpdate", self.onGUIUpdate, -1)
end


function PlacementSettingsGUI:onGUIUpdate(data)
	
	self = PlacementSettingsGUI
	
	if data:sub(1, 12) == "RoundingMode" then -- If it's RoundingMode
		
		for index, button in pairs(self.roundingModeButtons) do
			
			if button == data then
				self.gui:setButtonState(button, true)
				BetterPlacementCoreV2.settings.roundingSetting = index
			else
				self.gui:setButtonState(button, false)
			end
		end
	end

	
end


function PlacementSettingsGUI:onToggle()
	
	self.gui:open()
end