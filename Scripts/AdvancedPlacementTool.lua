
dofile("$CONTENT_DATA/Scripts/AdvancedPlacementCore.lua")



AdvancedPlacementTool = class()

AdvancedPlacementTool.placementCore = AdvancedPlacementCore

function AdvancedPlacementTool:client_onCreate()

    self:initialize()
end

function AdvancedPlacementTool:client_onRefresh()

    self:initialize()
end

function AdvancedPlacementTool:client_onDestroy()
    
    self.placementCore:initializeMod()
end

function AdvancedPlacementTool:initialize()
    
    self.placementCore:initializeMod()

    self.on = false

    self.toolUuid = sm.uuid.new("74febb3f-cc08-4e02-89c8-9fd0d0a1aa3c")

    self.placementCore.network = self.network

    DisplayDuration = 2
end

-- On/Off

function AdvancedPlacementTool.client_onReload(self)
    
    -- Is the tool selected

    if Item == self.toolUuid then
        self.on = not self.on

        if self.on then

            sm.gui.displayAlertText("Use BetterPlacement:\n#00ff00True", DisplayDuration)
        else

            sm.gui.displayAlertText("Use BetterPlacement:\n#ff0000False", DisplayDuration)
        end
    else

        self.placementCore:onReload()
    end

    return false
end

-- Rotation

function AdvancedPlacementTool.client_onToggle(self)

    self.placementCore:onToggle()

    return true
end

function AdvancedPlacementTool.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)

    self.placementCore.primaryState = primaryState

    -- The first parameter doesn't work for some reason

    return false, false
end

function AdvancedPlacementTool:client_onUpdate(dt)

    DeltaTime = dt

    Item = sm.localPlayer.getActiveItem()

    local forceTool = sm.item.isPart(Item) or Item == sm.uuid.getNil()-- or sm.item.isJoint(Item)

    if forceTool and self.on then
        
        sm.tool.forceTool(self.tool)
    else

        sm.tool.forceTool(nil)
    end

    if Item == self.toolUuid then
        
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Enable BetterPlacement")
    end

    if self.on then

        self.placementCore:doFrame()
    end
end

function AdvancedPlacementTool:sv_createPart(data)
    
    self.placementCore:sv_createPart(data)
end