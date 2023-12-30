

function GetPlacementSettingsGUI()

	local M = {}
	
	function M:onGUIUpdate(data)
	
		if type(data) == "string" then
			
			if data:sub(1, 12) == "RoundingMode" then
	
				for index, button in pairs(M.buttons.roundingMode) do
					if string.match(data, button) then
						BetterPlacementCoreV2.settings.roundingSetting = index
					end
				end
			else -- If it's ClickMode
	
				for index, button in pairs(M.buttons.clickMode) do
					
					if string.match(data, button) then
						BetterPlacementCoreV2.settings.doubleClick = index
					end
				end
			end
		end
	
		if type(data) == "number" then -- If it's PlacementRadius
			
			BetterPlacementCoreV2.settings.placementRadius = data
		end
	
	
		for index, button in pairs(M.buttons.clickMode) do
			
			if index == BetterPlacementCoreV2.settings.doubleClick then
				
				M.gui:setVisible(button .. "T", true)
				M.gui:setVisible(button .. "F", false)
			
			else
				M.gui:setVisible(button .. "T", false)
				M.gui:setVisible(button .. "F", true)
			end
		end
	
		for index, button in pairs(M.buttons.roundingMode) do
			
			if index == BetterPlacementCoreV2.settings.roundingSetting then
				
				M.gui:setVisible(button .. "T", true)
				M.gui:setVisible(button .. "F", false)
			
			else
				M.gui:setVisible(button .. "T", false)
				M.gui:setVisible(button .. "F", true)
			end
		end
	end
	
	
	function M:onToggle()
	
		M.gui:setButtonState(M.buttons.roundingMode[BetterPlacementCoreV2.settings.roundingSetting], true)
	
		M.gui:setButtonState(M.buttons.clickMode[BetterPlacementCoreV2.settings.doubleClick], true)
		
		M.gui:open()
	end

	-- Initialize

	M.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/PlacementSettingsGUI.layout")

	M.gui:createHorizontalSlider("PlacementRadius", 20, 7.5, "onGUIUpdate", true)

	M.buttons = {
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

	for _, button in pairs(M.buttons.roundingMode) do
		M.gui:setButtonCallback(button .. "T", "onGUIUpdate")
		M.gui:setButtonCallback(button .. "F", "onGUIUpdate")
	end

	for _, button in pairs(M.buttons.clickMode) do
		M.gui:setButtonCallback(button .. "T", "onGUIUpdate")
		M.gui:setButtonCallback(button .. "F", "onGUIUpdate")
	end

	M:onGUIUpdate(nil)

	return M
end