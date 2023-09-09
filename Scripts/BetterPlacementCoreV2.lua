
dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")

BetterPlacementCoreV2 = class()


function BetterPlacementCoreV2:initialize()
    
    self.phases = {
        [0] = self:doPhase0()
    }
end


function BetterPlacementCoreV2:reset()
    
    self.phase0.placementIsValid = false

    self.phase0.raycastStorage = nil

    self.status = {
        lockedSelection = false,
        verticalPositioning = false,
        phase = 0
    }

    self.itemIsValid = sm.item.isPart(self.currentItem)
end


function BetterPlacementCoreV2:start()
    
end


function BetterPlacementCoreV2:stop()
    
end


function BetterPlacementCoreV2:evaluateRaycast(raycastSuccess, raycastResult)
    
    if not raycastSuccess then
        return false
    end

    if not UsefulUtils.contains(raycastResult.type, self.constants.supportedSurfaces) then
        return false
    end

    if raycastResult.type == "joint" and self.currentItem then
        return false
    end

    if not UsefulUtils.isPlaceableFace(raycastResult, sm.vec3.closestAxis(raycastResult.normalLocal)) then
        return false
    end

    return true
end


function BetterPlacementCoreV2:updateValues()
    
    self.phase0.localSurfacePos = self.phase0.raycastResult.pointLocal

    self.phase0.localSurfaceRot = sm.vec3.getRotation(sm.vec3.new(0,0,1), self.localNormal)
end


function BetterPlacementCoreV2:doPhase0()

    if not self.status.lockedSelection then
        -- Update raycast data

        self.phase0.placementIsValid = self:evaluateRaycast() and sm.item.isPart(self.currentItem)

        self.phase0.raycastStorage = self.raycastResult

        self:updateValues()
    end

    if self.phase0.placementIsValid then
        
    end
end


function BetterPlacementCoreV2:doFrame()
    
    self.raycastSuccess, self.raycastResult = sm.localPlayer.getRaycast(self.settings.placementRadii)

    local lastItem = self.currentItem

    self.currentItem = sm.localPlayer.getActiveItem()

    self.itemHasChanged = (lastItem ~= self.currentItem)

    if self.itemHasChanged then
        
        self:reset()
    end
    


end