
dofile("$CONTENT_DATA/Scripts/BetterPlacement.lua")



BetterPlacementTool = class(BetterPlacement)

function BetterPlacementTool:client_onCreate()

    BetterPlacementTool.initialize(self)
end

function BetterPlacementTool:client_onRefresh()

    BetterPlacementTool.initialize(self)
end

function BetterPlacementTool:client_onDestroy()
    
    BetterPlacement.resetPlacement(self)
end

function BetterPlacementTool:initialize()
    
    BetterPlacement.initializeMod(self)

    self.on = false

    self.toolUuid = sm.uuid.new("74febb3f-cc08-4e02-89c8-9fd0d0a1aa3c")

    DisplayDuration = 2
end

-- On/Off

function BetterPlacementTool.client_onReload(self)
    
    -- Is the tool selected

    if Item == self.toolUuid then
        self.on = not self.on

        if self.on then

            sm.gui.displayAlertText("Use BetterPlacement:\n#00ff00True", DisplayDuration)
        else

            sm.gui.displayAlertText("Use BetterPlacement:\n#ff0000False", DisplayDuration)
        end
    else

        BetterPlacement.onReload(self)
    end

    return false
end

-- Rotation

function BetterPlacementTool.client_onToggle(self)

    BetterPlacement.onToggle(self)

    return true
end

function BetterPlacementTool.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)

    self.primaryState = primaryState

    -- The first parameter ddoesn't work for some reason

    return false, false
end

function BetterPlacementTool:client_onUpdate()

    Item = sm.localPlayer.getActiveItem()

    local forceTool = sm.item.isPart(Item) or sm.item.isJoint(Item) or Item == sm.uuid.getNil()

    if forceTool and self.on then
        
        sm.tool.forceTool(self.tool)
    else

        sm.tool.forceTool(nil)
    end

    if self.on then

        BetterPlacement.doFrame(self)
    end
end
