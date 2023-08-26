
---@diagnostic disable: need-check-nil

---@class BetterPlacementCore:ToolClass


BetterPlacementCore = class()


--- @param data table The table of data for the placement; {raycastResult, uuid, localPosition, localRotation, forceAccept}
function BetterPlacementCore:sv_createPart(data)

    local parent = data[1]
    local uuid = data[2]
    local localPosition = data[3]
    local localRotation = data[4]
    local forceAccept = data[5]
    
    if type(parent) == "Shape" then

        local xAxis = sm.vec3.closestAxis(sm.quat.getRight(localRotation))
        local yAxis = sm.vec3.closestAxis(sm.quat.getUp(localRotation))
        local zAxis = sm.vec3.closestAxis(sm.quat.getAt(localRotation))
        local shapeSize = localRotation * sm.item.getShapeSize(uuid)

        local localPlacementPosition = localPosition / SubdivideRatio - shapeSize * 0.5

        if sm.item.isPart(uuid) then
            
            parent:getBody():createPart(uuid, localPlacementPosition, zAxis, xAxis, forceAccept)
            
        elseif sm.item.isJoint(uuid) then

            --print(localPosition / SubdivideRatio)

            --local localSurfacePosition = UsefulUtils.roundVecToGrid(localPosition) / SubdivideRatio

            --print(localSurfacePosition)

            -- sm.shape.getShapeTitle( uuid )

            -- sm.shape.getShapeDescription( uuid )

            --parent:createJoint(uuid, localSurfacePosition, zAxis)
        end
    end
end

function BetterPlacementCore:onToggle()
    
    if self.primaryState == 0 then

        -- Shape rotation

        ItemRotationStorage[self.placementAxisAsString] = (ItemRotationStorage[self.placementAxisAsString] + 1) % 4

    elseif self.primaryState == 1 or self.primaryState == 2 then

        -- Vertical Positioning

        self.verticalPositioning = not self.verticalPositioning
    end
end


function BetterPlacementCore:onReload()
    
    if self.primaryState == 0 then
        
        self.lockedSelection = not self.lockedSelection
    end
end


function BetterPlacementCore:initialize()
    
    -- Set initial variables

    self.currentItem = nil

    self.lastAxisAsString = nil

    self.placementRotationStorage = {}

    self.main = BetterPlacementClass

    -- Constants

    ---@type number
    SubdivideRatio_2 = sm.construction.constants.subdivideRatio_2

    ---@type number
    SubdivideRatio = sm.construction.constants.subdivideRatio

    TransformUISize = sm.vec3.new(0.2, 0.2, 2) * sm.construction.constants.subdivideRatio -- Thickness and length of position selection UI
    
    BlockSize = sm.vec3.new(1, 1, 1) * SubdivideRatio
    CenterSize = 0.45

    PosX = sm.vec3.new(1,0,0)
    PosY = sm.vec3.new(0,1,0)
    PosZ = sm.vec3.new(0,0,1)
    NegX = sm.vec3.new(-1,0,0)
    NegY = sm.vec3.new(0,-1,0)
    NegZ = sm.vec3.new(0,0,-1)

    QuatPosX = sm.vec3.getRotation(PosZ, PosX)
    QuatPosY = sm.vec3.getRotation(PosZ, PosY)
    QuatPosZ = sm.quat.identity()
    QuatNegX = sm.vec3.getRotation(PosZ, NegX)
    QuatNegY = sm.vec3.getRotation(PosZ, NegY)
    QuatNegZ = sm.vec3.getRotation(PosZ, NegZ)

    Quat90 = sm.quat.angleAxis(- math.pi / 2, PosZ)

    RotationList = {

        [0] = sm.quat.identity(),
        [1] = Quat90,
        [2] = Quat90 * Quat90,
        [3] = Quat90 * Quat90 * Quat90
    }

    SupportedSurfaces = {"body", "joint"}

    -- uuids of UI mesh

    local placementUuids = {

        ["Base"] = "07ef9dbe-cf0d-4c18-a828-0092c1f50422",
        ["+X"] = "03422fac-1103-4f93-9206-5324c1406a86",
        ["+Y"] = "728e9744-9b40-45e7-9c0a-0e386f01e592",
        ["+Z"] = "d8fc440b-ad25-45db-b72b-36a99414435b",
        ["-X"] = "8cbaa03b-90f2-42fc-888b-1626650325c5",
        ["-Y"] = "01e9830e-4b80-47b5-9cbb-736024f12d53"
    }

    -- Create effects

    RotationEffects = EffectSet.new(placementUuids)

    RotationEffects:setParameter("+X", "color", sm.color.new(0,0,1,1))
    RotationEffects:setParameter("+Y", "color", sm.color.new(0,0,1,1))
    RotationEffects:setParameter("+Z", "color", sm.color.new(0,0,1,1))
    RotationEffects:setParameter("-X", "color", sm.color.new(0,0,1,1))
    RotationEffects:setParameter("-Y", "color", sm.color.new(0,0,1,1))

    RotationEffects:setScale(SubdivideRatio)

    -- Aluminum Block

    TransformEffects = EffectSet.new({

        ["X"] = "3e3242e4-1791-4f70-8d1d-0ae9ba3ee94c",
        ["Y"] = "3e3242e4-1791-4f70-8d1d-0ae9ba3ee94c",
        ["Z"] = "3e3242e4-1791-4f70-8d1d-0ae9ba3ee94c"
    })
    -- Set colour

    TransformEffects:setParameter("X", "color", sm.color.new(1,0,0,1))
    TransformEffects:setParameter("Y", "color", sm.color.new(0,1,0,1))
    TransformEffects:setParameter("Z", "color", sm.color.new(0,0,1,1))

    -- Create the axis shape

    TransformEffects:setOffsetTransforms({

        ["X"] = {QuatPosX * (TransformUISize * PosZ / 2), QuatPosX, TransformUISize},
        ["Y"] = {QuatPosY * (TransformUISize * PosZ / 2), QuatPosY, TransformUISize},
        ["Z"] = {QuatPosZ * (TransformUISize * PosZ / 2), QuatPosZ, TransformUISize}
    })
    
    -- Visualization effect

    VisualizationEffect = SmartEffect.new(sm.effect.createEffect("ShapeRenderable"))

    VisualizationEffect:setScale(SubdivideRatio)

    VisualizationEffect:setParameter("visualization", true)

    -- Set variables

    BetterPlacementCore:resetPlacement()

    -- Hook functions

    self.main:linkCallback("sv_createPart", BetterPlacementCore.sv_createPart, 1)
end


function BetterPlacementCore:resetPlacement()

    self.lockedSelection = false
            -- Whether selection is locked to a face
        
    RotationEffects:hideAll()

    TransformEffects:hideAll()

    self.lastAxisAsString = nil

    self.primaryState = nil

    self.verticalPositioning = false

    self.positionSelectionTime = 0

    VisualizationEffect:stop()
end


function BetterPlacementCore:calculateSurfacePosition()
    
    if self.lockedSelection == false then
        
        if self.raycastSuccess then
            
            -- Don't process unsupported types

            if not UsefulUtils.contains(self.raycastResult.type, SupportedSurfaces) then
                return false
            end

            -- Don't show joint on top of another joint

            if self.raycastResult.type == "joint" and sm.item.isJoint(self.currentItem) then
                return false
            end

            -- Get root body

            self.transformBody = UsefulUtils.getTransformBody(self.raycastResult)

            -- Update some variables

            self.raycastStorage = self.raycastResult

            self.localHitPos = self.raycastResult.pointLocal

            self.localNormal = sm.vec3.closestAxis(self.raycastResult.normalLocal)

            -- Can you build there?
            
            if UsefulUtils.isPlaceableFace(self.raycastResult, self.localNormal) == 1 then

                -- Get attached object(Shape, joint etc)

                self.attachedObject = UsefulUtils.getAttachedObject(self.raycastResult)

                -- Calculate the placement position and rotation

                self.localSurfacePos = UsefulUtils.roundVecToCenterGrid(self.localHitPos + self.localNormal * SubdivideRatio_2) - self.localNormal * SubdivideRatio_2

                self.localSurfaceRot = sm.vec3.getRotation(sm.vec3.new(0,0,1), self.localNormal)

                return true

            else
                return false
            end

        else
            return false
        end
    
    else

        -- Check I can still build there

        if not sm.exists(self.transformBody) then
            
            return false
        end

        return true
    end

end


function BetterPlacementCore:updateValues()

    self.worldNormal = self.transformBody.worldRotation * self.localNormal

    self.worldSurfacePos = self.transformBody:transformPoint(self.localSurfacePos)

    self.worldSurfaceRot = self.transformBody.worldRotation * self.localSurfaceRot

    local raycastToPlane = UsefulUtils.raycastToPlane(sm.localPlayer.getRaycastStart(), self.raycastResult.directionWorld, self.worldSurfacePos, self.worldNormal)

    self.worldDeltaPlacement = raycastToPlane + sm.localPlayer.getRaycastStart() - self.worldSurfacePos

    self.localDeltaPlacement = sm.quat.inverse(self.worldSurfaceRot) * self.worldDeltaPlacement
end


---@param item Uuid
---@param rawItemRotation Quat
---@param planePosition Vec3
---@param planeRotation Quat
---@param relativePosition Vec3
---@param roundingSetting string|nil DynamicSnapCornerToGrid, FixedSnapCornerToGrid, SnapCenterToGrid
---@return Vec3
---@return Quat
function BetterPlacementCore.calculatePlacementOnPlane(item, rawItemRotation, planePosition, planeRotation, relativePosition, roundingSetting)

    if roundingSetting == nil then
        
        roundingSetting = "DynamicSnapCornerToGrid"
    end

    local localPlacementRot = planeRotation * rawItemRotation
        
    local shapeSize = sm.item.getShapeSize(item) * SubdivideRatio

    local rotatedShapeSize = rawItemRotation * shapeSize

    local roundedOffset = sm.vec3.zero()
    
    if roundingSetting == "DynamicSnapCornerToGrid" then

        roundedOffset = UsefulUtils.roundVecToCenterGrid(relativePosition - rotatedShapeSize / 2) + rotatedShapeSize / 2

    elseif roundingSetting == "FixedSnapCornerToGrid" then
        
        local itemPivotPoint = UsefulUtils.roundVecToCenterGrid(shapeSize / 2) - shapeSize / 2

        roundedOffset = UsefulUtils.roundVecToGrid(relativePosition) + rawItemRotation * itemPivotPoint
    
    else -- SnapCenterToGrid

        roundedOffset = UsefulUtils.roundVecToGrid(relativePosition)
    end

    roundedOffset.z = math.abs(rotatedShapeSize.z / 2)

    local localPlacementPos = planePosition + planeRotation * roundedOffset

    return localPlacementPos, localPlacementRot
end


function BetterPlacementCore:doPhase0()
    
    if UsefulUtils.is6Way(self.currentItem) then

        -- Use 6-Way Interface
    else
        
        -- Which face is the curser pointing at

        -- "placementAxis" is the axis the block is placed on

        local x = self.localDeltaPlacement.x
        local y = self.localDeltaPlacement.y

        local a = x + y
        local b = x - y

        if math.max(math.abs(x), math.abs(y)) < SubdivideRatio_2 * CenterSize then
            
            -- Center
            self.placementAxis = QuatPosZ
            self.placementAxisAsString = "+Z"
        
        elseif a > 0 and b > 0 then
            
            -- Right
            self.placementAxis = QuatNegX
            self.placementAxisAsString = "-X"

        elseif a > 0 and b <= 0 then

            -- Up
            self.placementAxis = QuatNegY
            self.placementAxisAsString = "-Y"
        
        elseif a <= 0 and b > 0 then

            -- Down
            self.placementAxis = QuatPosY
            self.placementAxisAsString = "+Y"
        
        else

            -- Left
            self.placementAxis = QuatPosX
            self.placementAxisAsString = "+X"
        end

        if ItemRotationStorage == nil then
            
            ItemRotationStorage = {

                ["+X"] = 0,
                ["+Y"] = 0,
                ["+Z"] = 0,
                ["-X"] = 0,
                ["-Y"] = 0
            }
        end

        -- Show selection effect

        RotationEffects:showOnly({self.placementAxisAsString, "Base"})

        RotationEffects:setPosition(self.worldSurfacePos)

        RotationEffects:setRotation(self.worldSurfaceRot)

        -- Calculate Visualization position

        local rawPlacementRot = self.placementAxis * RotationList[ItemRotationStorage[self.placementAxisAsString]]

        self.localPlacementPos, self.localPlacementRot = self.calculatePlacementOnPlane(self.currentItem, rawPlacementRot, self.localSurfacePos, self.localSurfaceRot, UsefulUtils.clampVec(self.localDeltaPlacement, SubdivideRatio_2 * 0.99), self.main.settings.RoundingSetting)

        -- Show placement visualization

        self.worldPlacementPos = self.transformBody:transformPoint(self.localPlacementPos)

        self.worldPlacementRot = self.transformBody.worldRotation * self.localPlacementRot

        VisualizationEffect:setTransforms({self.worldPlacementPos, self.worldPlacementRot})
    end
end


function BetterPlacementCore:startPhase1()


    
    self.lockedSelection = true

    RotationEffects:hideAll()
end


function BetterPlacementCore:doPhase1()
    
    if self.verticalPositioning == true then

        TransformEffects:showOnly("Z")
        
        local delta = UsefulUtils.roundToGrid(UsefulUtils.raycastToLine(sm.localPlayer.getRaycastStart(), self.raycastResult.directionWorld, self.worldPlacementPos, self.worldNormal))

        self.localSurfacePos = self.localSurfacePos + self.localNormal * delta

        self.localPlacementPos = self.localPlacementPos + self.localNormal * delta
    else

        TransformEffects:showOnly({"X", "Y"})

        local rawPlacementRot = self.placementAxis * RotationList[ItemRotationStorage[self.placementAxisAsString]]

        self.localPlacementPos, self.localPlacementRot = self.calculatePlacementOnPlane(self.currentItem, rawPlacementRot, self.localSurfacePos, self.localSurfaceRot, self.localDeltaPlacement)
    end

    self.worldPlacementPos = self.transformBody:transformPoint(self.localPlacementPos)

    self.worldPlacementRot = self.transformBody.worldRotation * self.localPlacementRot

    TransformEffects:setPositionAndRotation(self.worldPlacementPos, self.worldSurfaceRot)

    VisualizationEffect:setTransforms({self.worldPlacementPos, self.worldPlacementRot})
end


function BetterPlacementCore:doPhase2()

    TransformEffects:hideAll()

    if self.raycastStorage.type == "body" then
        self.main.network:sendToServer("sv_createPart", {self.raycastStorage:getShape(), self.currentItem, self.localPlacementPos, self.localPlacementRot, true})
    
    elseif self.raycastStorage.type == "joint" then
        self.main.network:sendToServer("sv_createPart", {self.raycastStorage:getJoint(), self.currentItem, self.localPlacementPos, self.localPlacementPos, true})
    end

    self:resetPlacement()
end

function BetterPlacementCore:managePhases()
    
    if self.primaryState == 0 then
        
        self:doPhase0()

    elseif self.primaryState == 1 then

        self.positionSelectionTime = sm.game.getCurrentTick()
        
        self:startPhase1()
    
    elseif self.primaryState == 2 then
        
        if sm.game.getCurrentTick() >= self.positionSelectionTime + self.main.settings.PositionSelectionTimer then 

            self:doPhase1()
        end
    
    elseif self.primaryState == 3 then

        self:doPhase2()
    end
end


function BetterPlacementCore:doFrame()
    
    self.raycastSuccess, self.raycastResult = sm.localPlayer.getRaycast(self.main.settings.PlacementRadii)

    local lastItem = self.currentItem

    self.currentItem = sm.localPlayer.getActiveItem()

    self.currentItemAsString = tostring(self.currentItem)

    if lastItem ~= self.currentItem then

        self.placementRotationStorage[tostring(lastItem)] = ItemRotationStorage

        ItemRotationStorage = self.placementRotationStorage[self.currentItemAsString]
        
        self.itemHasChanged = true
        self.usable = sm.item.isPart(self.currentItem) or sm.item.isJoint(self.currentItem)

        self:resetPlacement()

        VisualizationEffect:stop()

        VisualizationEffect:setParameter("uuid", self.currentItem)
    else
        self.itemHasChanged = false
    end

    
    self.doingPlacement = self:calculateSurfacePosition() and self.usable

    if self.doingPlacement then

        VisualizationEffect:start()

        self:updateValues()
            
        self:managePhases()
    else

        self:resetPlacement()
    end
end