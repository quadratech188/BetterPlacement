
PlacementSettingsGUI = class()

-- The next 3 functions recieve AdvancedPlacementClass as self

function PlacementSettingsGUI:onPlacementSettingsSelect(value)
    
    self.settings.RoundingSetting = value

    sm.json.save(self.settings, "$CONTENT_DATA/Scripts/settings.json")
end

function PlacementSettingsGUI:onPositionSelectionTimerSelect(value)
    self.settings.PositionSelectionTimer = value

    sm.json.save(self.settings, "$CONTENT_DATA/Scripts/settings.json")

    self.guiClass.gui:setText("PositionSelectionTimerTextBox", tostring(self.settings.PositionSelectionTimer))
end

function PlacementSettingsGUI:onPlacementRadiiSelect(value)

    self.settings.PlacementRadii = value

    sm.json.save(self.settings, "$CONTENT_DATA/Scripts/settings.json")

    self.guiClass.gui:setText("PlacementRadiiTextBox", tostring(self.settings.PlacementRadii))
end

function PlacementSettingsGUI:initialize()

    self.main = AdvancedPlacementClass

    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/PlacementSettingsGUI.layout")

    self.gui:createDropDown("PlacementSettingsDropdown", "onPlacementSettingsSelect", self.main.settingsData.RoundingSettings)

    self.main:linkCallback("onPlacementSettingsSelect", self.onPlacementSettingsSelect)

    self.gui:createHorizontalSlider("PositionSelectionTimerSlider", self.main.settingsData.MaxPositionSelectionTimer, self.main.settings.PositionSelectionTimer, "onPositionSelectionTimerSelect", true)

    self.main:linkCallback("onPositionSelectionTimerSelect", self.onPositionSelectionTimerSelect)

    self.gui:setText("PositionSelectionTimerTextBox", tostring(self.main.settings.PositionSelectionTimer))

    self.gui:createHorizontalSlider("PlacementRadiiSlider", self.main.settingsData.MaxPlacementRadii, self.main.settings.PlacementRadii, "onPlacementRadiiSelect", true)

    self.main:linkCallback("onPlacementRadiiSelect", self.onPlacementRadiiSelect)

    self.gui:setText("PlacementRadiiTextBox", tostring(self.main.settings.PlacementRadii))
end


function PlacementSettingsGUI:onToggle()
    
    self.gui:open()
end