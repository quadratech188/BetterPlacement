
PlacementSettingsGUI = class()

function PlacementSettingsGUI:initialize()

    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/PlacementSettingsGUI.layout")

    self.gui:createDropDown("PlacementSettingsDropdown", "onPlacementSettingsDropdownSelect", self.placementCore.settingsData.RoundingSettings)

    self.gui:createHorizontalSlider("PositionSelectionTimerSlider", self.placementCore.settingsData.MaxPositionSelectionTimer, self.placementCore.settings.PositionSelectionTimer, "onPositionSelectionTimerSliderSelect", true)

    self.gui:setText("PositionSelectionTimerTextBox", tostring(self.placementCore.settings.PositionSelectionTimer))

    self.gui:createHorizontalSlider("PlacementRadiiSlider", self.placementCore.settingsData.MaxPlacementRadii, self.placementCore.settings.PlacementRadii, "onPlacementRadiiSelect", true)

    self.gui:setText("PlacementRadiiTextBox", tostring(self.placementCore.settings.PlacementRadii))
end

function PlacementSettingsGUI:doFrame()
    

end

function PlacementSettingsGUI:onSelect(widget, value)

    if widget == "PlacementSettingsDropdown" then
        
        self.placementCore.settings.RoundingSetting = value

    elseif widget == "PositionSelectionTimerSlider" then

        self.placementCore.settings.PositionSelectionTimer = value

        self.gui:setText("PositionSelectionTimerTextBox", tostring(value))
        
    elseif widget == "PlacementRadiiSlider" then

        self.placementCore.settings.PlacementRadii = value

        self.gui:setText("PlacementRadiiTextBox", tostring(value))

    end
end


function PlacementSettingsGUI:onToggle()
    
    self.gui:open()
end