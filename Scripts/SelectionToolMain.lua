
dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")
dofile("$CONTENT_DATA/Scripts/PieMenu.lua")
dofile("$CONTENT_DATA/Scripts/FakeCursor.lua")

SelectionToolTemplateClass = class()

function SelectionToolTemplateClass:client_onCreate()
    
    self.phases = {
        ["start"] = self.doPhase0,
        ["select"] = self.doPhase1,
        ["actionSelect"] = self.doActionSelect,
        ["execute"] = self.executeAction
    }

    self.currentPhase = "start"

    HighLightEffect = SmartEffect.new(sm.effect.createEffect("ShapeRenderable"))

    HighLightEffect:setScale(SubdivideRatio)

    HighLightEffect:setParameter("visualization", true)

    ActionSelectionPieMenu = PieMenu.new(sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/PieMenuGUI4.layout", false, {isHud = true, isInteractive = false}), 3, 0, {}, {}, 0)
end

function SelectionToolTemplateClass:client_onRefresh()
    
    self:client_onCreate()
end

function SelectionToolTemplateClass:client_onDestroy()
    
    HighLightEffect:stop()
end

function SelectionToolTemplateClass:doPhase0(isRisingEdge)

    -- print("start")

    sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select")
    sm.gui.setInteractionText("", sm.gui.getKeyBinding("ForceBuild", true), "Actions...")
    
    if self.raycastResult.type == "body" then

        self.shape = self.raycastResult:getShape()

        UsefulUtils.highlightShape(HighLightEffect, self.shape)
    
    else

        self.shape = nil
        
        HighLightEffect:stop()
    end
end

function SelectionToolTemplateClass:doPhase1(isRisingEdge)

    -- print("select")
    
    sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Release")
    sm.gui.setInteractionText("", sm.gui.getKeyBinding("ForceBuild", true), "Actions...")

    UsefulUtils.highlightShape(HighLightEffect, self.shape)
end

function SelectionToolTemplateClass:doActionSelect(isRisingEdge)

    if isRisingEdge then
        
        ActionSelectionPieMenu:open()
    end

    -- print("actionSelect")
end

function SelectionToolTemplateClass:executeAction(isRisingEdge)

    if isRisingEdge then
        
        ActionSelectionPieMenu:close()
    end
    
    -- print("execute")

    self.currentPhase = "start"
end

function SelectionToolTemplateClass.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)

    self.primaryState = primaryState
    self.secondaryState = secondaryState
    self.forceBuild = forceBuild

    local isRisingEdge

    if self.currentPhase == "start" and primaryState == 1 and self.shape ~= nil then
        self.currentPhase = "select"
        isRisingEdge = true

    elseif self.currentPhase == "select" and primaryState == 1 then
        self.currentPhase = "start"
        isRisingEdge = true
    end

    if (self.currentPhase == "start" or self.currentPhase == "select") and forceBuild then
        self.currentPhase = "actionSelect"
        isRisingEdge = true
    
    elseif self.currentPhase == "actionSelect" and not forceBuild then
        self.currentPhase = "execute"
        isRisingEdge = true
    end

    self.raycastSuccess, self.raycastResult = sm.localPlayer.getRaycast(7.5)

    self.phases[self.currentPhase](self, isRisingEdge)

    ActionSelectionPieMenu:doFrame()

    -- The first parameter doesn't work for some reason

    return false, false
    
end