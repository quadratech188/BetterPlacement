

dofile("$CONTENT_DATA/Scripts/AdvancedPlacementCore.lua")

dofile("$SURVIVAL_DATA/Scripts/game/survival_shapes.lua")

dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")

dofile("$CONTENT_DATA/Scripts/EffectSet.lua")

dofile("$CONTENT_DATA/Scripts/PlacementSettingsGUI.lua")

AdvancedPlacementTemplateClass = class()


function AdvancedPlacementTemplateClass:client_onCreate()

    sm.gui.chatMessage("Initializing AdvancedPlacement Mod")
    print("Initializing AdvancedPlacement Mod")

    -- References

    self.placementCore = AdvancedPlacementCore

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

    -- 'self' is actually not AdvancedPlacementTemplateClass, it's another object created by duplicating it and adding some extra parameters.
    -- We write the following line so that other classes can also refer to 'self'.

    AdvancedPlacementClass = self

     self.settings = sm.json.open("$CONTENT_DATA/Scripts/settings.json")

    self.placementCore:initialize()

    self.guiClass:initialize()

    sm.gui.chatMessage("Initialized AdvancedPlacement Mod")
    print("Initialized AdvancedPlacement Mod")
end


function AdvancedPlacementTemplateClass:client_onRefresh()

    self:client_onCreate()
end


function AdvancedPlacementTemplateClass:client_onDestroy()

end

-- On/Off

function AdvancedPlacementTemplateClass.client_onReload(self)
    
    -- Is the tool selected

    if self.isEquipped then
        self.on = not self.on

        if self.on then

            sm.gui.displayAlertText("Use Advanced Placement:\n#00ff00True", 2)
        else

            sm.gui.displayAlertText("Use Advanced Placement:\n#ff0000False", 2)
        end
    else

        self.placementCore:onReload()
    end

    return true
end

-- Rotation

function AdvancedPlacementTemplateClass.client_onToggle(self)

    if self.isEquipped then
        
        self.guiClass:onToggle()
    else

        self.placementCore:onToggle()
    end

    return true
end

function AdvancedPlacementTemplateClass.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)

    self.placementCore.primaryState = primaryState

    -- The first parameter doesn't work for some reason

    return false, false
end

function AdvancedPlacementTemplateClass:client_onUpdate()

    Item = sm.localPlayer.getActiveItem()

    if Item == self.toolUuid then
        
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Enable Advanced Placement")
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Open Settings GUI") -- https://scrapmechanictools.com/modding_help/Keybind_Names

        self.isEquipped = true
    else

        self.isEquipped = false
    end

    local forceTool = sm.item.isPart(Item) or Item == sm.uuid.getNil() or sm.item.isJoint(Item)

    if forceTool and self.on then
        
        sm.tool.forceTool(self.tool)
    else

        sm.tool.forceTool(nil)
    end

    if self.on then

        self.placementCore:doFrame()
    end
end
