
dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")

dofile("$CONTENT_DATA/Scripts/PartVisualization.lua")

BetterPlacementCoreV2 = class()


function BetterPlacementCoreV2:initialize()
    
    self.phases = {
        [0] = self.doPhase0
    }

    self.partVisualization = PartVisualization.new(sm.uuid.getNil(), nil)

    self.phase0 = {}
    self.phase1 = {}

    self.constants = {
        supportedSurfaces = {
            "body",
            "joint"
        },
        centerSize = 0.45
    }

    self:createEffects()

    self:reset()

    -- Temporary

    self.settings = {

        roundingSetting = "SnapCornerToGrid", -- SnapCenterToGrid, DynamicSnapCornerToGrid, FixedSnapCornerToGrid
        positionSelectionTimer = 5, -- Ticks before advancing to position selection
        placementRadii = 7.5, -- Reach distance
    }
end


function BetterPlacementCoreV2:createEffects()
    
    local rotationGizmoUuids = {

        ["Base"] = "07ef9dbe-cf0d-4c18-a828-0092c1f50422",
        ["+X"] = "03422fac-1103-4f93-9206-5324c1406a86",
        ["+Y"] = "728e9744-9b40-45e7-9c0a-0e386f01e592",
        ["+Z"] = "d8fc440b-ad25-45db-b72b-36a99414435b",
        ["-X"] = "8cbaa03b-90f2-42fc-888b-1626650325c5",
        ["-Y"] = "01e9830e-4b80-47b5-9cbb-736024f12d53"
    }

    -- Create effects

    ---@type EffectSet
    self.rotationGizmo = EffectSet.new(rotationGizmoUuids)

    self.rotationGizmo:setParameter("Base", "color", InterfaceColorBase)
    self.rotationGizmo:setParameter("+X", "color", InterfaceColorHighlight)
    self.rotationGizmo:setParameter("+Y", "color", InterfaceColorHighlight)
    self.rotationGizmo:setParameter("+Z", "color", InterfaceColorHighlight)
    self.rotationGizmo:setParameter("-X", "color", InterfaceColorHighlight)
    self.rotationGizmo:setParameter("-Y", "color", InterfaceColorHighlight)

    self.rotationGizmo:setScale(SubdivideRatio)
end


function BetterPlacementCoreV2:reset()
    
    self.phase0.placementIsValid = false

    self.phase0.raycastStorage = nil

    self.status = {
        lockedSelection = false,
        verticalPositioning = false,
        phase = 0
    }

    self.partVisualization:visualize("None")
end


function BetterPlacementCoreV2:start()
    
end


function BetterPlacementCoreV2:stop()
    
    self:reset()
end


function BetterPlacementCoreV2:evaluateRaycast(raycastSuccess, raycastResult)
    
    if not raycastSuccess then
        return false
    end

    if not UsefulUtils.contains(raycastResult.type, self.constants.supportedSurfaces) then
        return false
    end

    if raycastResult.type == "joint" and sm.item.isJoint(self.currentItem) then
        return false
    end

    if not UsefulUtils.isPlaceableFace(raycastResult, sm.vec3.closestAxis(raycastResult.normalLocal)) then
        return false
    end

    return true
end


function BetterPlacementCoreV2:calculatePartPosition()
    

end


function BetterPlacementCoreV2:doPhase0()

    if not self.status.lockedSelection then

        self.phase0.placementIsValid = self:evaluateRaycast(self.raycastSuccess, self.raycastResult) and sm.item.isPart(self.currentItem)

        if self.phase0.placementIsValid then

            self.phase0.raycastStorage = self.raycastResult
        end
    end

    if not self.phase0.placementIsValid then
        
        self.partVisualization:visualize("None")
        self.rotationGizmo:hideAll()

    else

        self.phase0.faceData = UsefulUtils.getFaceDataFromRaycast(self.phase0.raycastStorage)

        local faceData = self.phase0.faceData

        local delta = self.phase0.faceData.surfaceDelta
        local x = delta.x
        local y = delta.y

        local a = x + y
        local b = x - y

        if math.max(math.abs(x), math.abs(y)) < SubdivideRatio_2 * self.constants.centerSize then
            
            -- Center
            self.placementAxis = "+Z"
        
        elseif a > 0 and b > 0 then
            
            -- Right
            self.placementAxis = "-X"

        elseif a > 0 and b <= 0 then

            -- Up
            self.placementAxis = "-Y"
        
        elseif a <= 0 and b > 0 then

            -- Down
            self.placementAxis = "+Y"
        
        else

            -- Left
            self.placementAxis = "+X"
        end

        -- Show Rotation Gizmo

        self.rotationGizmo:showOnly({self.placementAxis, "Base"})

        self.rotationGizmo:setPosition(faceData.localFaceCenterPos)

        self.rotationGizmo:setRotation(faceData.localFaceRot)

        -- Show Part preview

        self.partVisualization:visualize("Blue")

        self.partVisualization:setParent(UsefulUtils.getTransformBody(self.phase0.raycastStorage))

        self.partVisualization:setTransforms(self.phase0.localSurfacePos, self.phase0.localSurfaceRot)
    end
end


function BetterPlacementCoreV2:doFrame()
    
    self.raycastSuccess, self.raycastResult = sm.localPlayer.getRaycast(self.settings.placementRadii)

    local lastItem = self.currentItem

    self.currentItem = sm.localPlayer.getActiveItem()

    self.itemHasChanged = (lastItem ~= self.currentItem)

    if self.itemHasChanged then

        self.partVisualization:setPart(self.currentItem)
        
        self:reset()
    end
    
    self.phases[self.status.phase](self)
end