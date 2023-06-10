
PlacementSettingsGUI = class()

function PlacementSettingsGUI:initialize()

    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/PlacementSettingsGUI.layout")
end

function PlacementSettingsGUI:doFrame()
    

end

function PlacementSettingsGUI:onToggle()
    
    self.gui:open()
end