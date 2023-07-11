
PlacementSettingsGUI = class()

function PlacementSettingsGUI:initialize()

    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/PlacementSettingsGUI.layout")

    self.gui:createDropDown("PlacementSettingsDropdown", "onPlacementSettingsDropdownSelect", self.placementCore.settingsData.RoundingSettings)

    self.gui:createHorizontalSlider("PositionSelectionTimerSlider", self.placementCore.settingsData.MaxPositionSelectionTimer, self.placementCore.settings.PositionSelectionTimer, "onPositionSelectionTimerSliderSelect", true)

    self.gui:setText("PositionSelectionTimerTextBox", tostring(self.placementCore.settings.PositionSelectionTimer))
end

function PlacementSettingsGUI:doFrame()
    

end

function PlacementSettingsGUI:onSelect(widget, value)

    if widget == "PlacementSettingsDropdown" then
        
        self.placementCore.settings.RoundingSetting = value

    elseif widget == "PositionSelectionTimerSlider" then

        self.placementCore.settings.PositionSelectionTimer = value

        self.gui:setText("PositionSelectionTimerTextBox", tostring(value))

    elseif widget == "PositionSelectionTimerEditBox" then

        print(value)

        local number = tonumber(value)

        if number == nil then
            
            self.gui:setText("PositionSelectionTimerEditBox", tostring(self.placementCore.settings.PositionSelectionTimer))
        
        else
            self.placementCore.settings.PositionSelectionTimer = value

            self.gui:setSliderPosition("PositionSelectionTimerSlider", value)
        end
    end
end


function PlacementSettingsGUI:onToggle()
    
    self.gui:open()
end