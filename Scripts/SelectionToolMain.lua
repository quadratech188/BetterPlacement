
dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")

SelectionToolTemplateClass = class()

function SelectionToolTemplateClass:client_onCreate()
    
    self.phases = {
        ["start"] = self.doPhase0,
        ["select"] = self.doPhase1,
        ["actionSelect"] = self.doActionSelect
    }

    self.currentPhase = "start"

    HighLightEffect = SmartEffect.new(sm.effect.createEffect("ShapeRenderable"))

    HighLightEffect:setScale(SubdivideRatio)

    HighLightEffect:setParameter("visualization", true)
end

function SelectionToolTemplateClass:client_onRefresh()
    
    self:client_onCreate()
end

function SelectionToolTemplateClass:client_onDestroy()
    
    HighLightEffect:stop()
end

function SelectionToolTemplateClass:doPhase0()

    print("start")

    sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select")
    sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Actions...")
    
    if self.raycastResult.type == "body" then

        self.shape = self.raycastResult:getShape()

        UsefulUtils.highlightShape(HighLightEffect, self.shape)
    
    else

        self.shape = nil
        
        HighLightEffect:stop()
    end
end

function SelectionToolTemplateClass:doPhase1()

    print("select")
    
    sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Release")
    sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Actions...")

    UsefulUtils.highlightShape(HighLightEffect, self.shape)
end

function SelectionToolTemplateClass:doActionSelect()
    
    print("actionSelect")

    self.currentPhase = "select"
end

function SelectionToolTemplateClass:client_onReload()

    if self.currentPhase == "start" or self.currentPhase == "select" then
        self.currentPhase = "actionSelect"
    end
    
    return true
end

function SelectionToolTemplateClass.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)

    if self.currentPhase == "start" and primaryState == 1 and self.shape ~= nil then
        self.currentPhase = "select"
    elseif self.currentPhase == "select" and primaryState == 1 then
        self.currentPhase = "start"
    end

    self.raycastSuccess, self.raycastResult = sm.localPlayer.getRaycast(7.5)

    self.phases[self.currentPhase](self)

    -- The first parameter doesn't work for some reason

    return false, false
end