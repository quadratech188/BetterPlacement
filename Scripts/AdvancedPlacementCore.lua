
---@diagnostic disable: need-check-nil

---@class AdvancedPlacementCore:ToolClass

dofile("$SURVIVAL_DATA/Scripts/game/survival_shapes.lua")

dofile("$CONTENT_DATA/Scripts/PlacementUtils.lua")

dofile("$CONTENT_DATA/Scripts/EffectSet.lua")


AdvancedPlacementCore = class()


--- @param data table The table of data for the placement; {raycastResult, uuid, localPosition, localRotation, forceAccept}
function AdvancedPlacementCore:sv_createPart(data)

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

            parent:createJoint(uuid, localPlacementPosition / SubdivideRatio, zAxis)
        end
    end
end

function AdvancedPlacementCore:onToggle()
    
    if self.primaryState == 0 then

        -- Shape rotation

        ItemRotationStorage[self.placementAxisAsString] = (ItemRotationStorage[self.placementAxisAsString] + 1) % 4

    elseif self.primaryState == 1 or self.primaryState == 2 then

        -- Vertical Positioning

        self.verticalPositioning = not self.verticalPositioning
    end
end


function AdvancedPlacementCore:onReload()
    
    if self.primaryState == 0 then
        
        self.lockedSelection = not self.lockedSelection
    end
end


function AdvancedPlacementCore:initializeMod()

    sm.gui.chatMessage("Initializing AdvancedPlacement Mod")
    print("Initializing AdvancedPlacement Mod")
    
    -- Set initial variables

    self.currentItem = nil

    self.lastAxisAsString = nil

    self.placementRotationStorage = {}

    -- Constants

    ---@type number
    SubdivideRatio_2 = sm.construction.constants.subdivideRatio_2

    ---@type number
    SubdivideRatio = sm.construction.constants.subdivideRatio
    
    BlockSize = sm.vec3.new(1, 1, 1) * SubdivideRatio
    CenterSize = 0.46875

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

    -- Settings

    UsePositionOnPhase1 = false
    RoundToGridOnPhase1 = true
    PositionSelectionTimer = 5 -- Ticks before advancing to position selection
    PlacementRadii = 7.5 -- Reach distance
    TransformUISize = sm.vec3.new(0.2, 0.2, 2) * SubdivideRatio -- Thickness and length of position selection UI


    RotationList = {

        [0] = sm.quat.identity(),
        [1] = Quat90,
        [2] = Quat90 * Quat90,
        [3] = Quat90 * Quat90 * Quat90
    }

    SupportedSurfaces = {"body", "joint"}

    -- Initialize placement selection effects

    local placementUuids = {

        ["+X"] = "03422fac-1103-4f93-9206-5324c1406a86",
        ["+Y"] = "728e9744-9b40-45e7-9c0a-0e386f01e592",
        ["+Z"] = "d8fc440b-ad25-45db-b72b-36a99414435b",
        ["-X"] = "8cbaa03b-90f2-42fc-888b-1626650325c5",
        ["-Y"] = "01e9830e-4b80-47b5-9cbb-736024f12d53"
    }

    RotationEffects = EffectSet.new(placementUuids)

    RotationEffects:setScale(BlockSize)

    TransformEffects = EffectSet.new({

        ["X"] = "3e3242e4-1791-4f70-8d1d-0ae9ba3ee94c",
        ["Y"] = "3e3242e4-1791-4f70-8d1d-0ae9ba3ee94c",
        ["Z"] = "3e3242e4-1791-4f70-8d1d-0ae9ba3ee94c" -- Aluminum Block
    })

    TransformEffects:getEffect("X"):setParameter("color", sm.color.new(1,0,0,1))
    TransformEffects:getEffect("Y"):setParameter("color", sm.color.new(0,1,0,1))
    TransformEffects:getEffect("Z"):setParameter("color", sm.color.new(0,0,1,1))

    TransformEffects:setOffsetTransforms({

        ["X"] = {QuatPosX * (TransformUISize * PosZ / 2), QuatPosX, TransformUISize},
        ["Y"] = {QuatPosY * (TransformUISize * PosZ / 2), QuatPosY, TransformUISize},
        ["Z"] = {QuatPosZ * (TransformUISize * PosZ / 2), QuatPosZ, TransformUISize}
    })

    -- Visualization effect

    VisualizationEffect = EffectSet.new()

    VisualizationEffect = sm.effect.createEffect("ShapeRenderable")
    VisualizationEffect:setScale(BlockSize)
    VisualizationEffect:setParameter("visualization", true)

    -- Initialize placement

    AdvancedPlacementCore:resetPlacement()

    sm.gui.chatMessage("Initialized AdvancedPlacement Mod")
    print("Initialized AdvancedPlacement Mod")
end


function AdvancedPlacementCore:resetPlacement()

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


function AdvancedPlacementCore:calculateSurfacePosition()
    
    if self.lockedSelection == false then
        
        if RaycastSuccess then
            
            -- Don't process unsupported types

            if not PlacementUtils.contains(RaycastResult.type, SupportedSurfaces) then
                return false
            end

            -- Don't show joint on top of another joint

            if RaycastResult.type == "joint" and sm.item.isJoint(self.currentItem) then
                return false
            end

            -- Get root body

            self.transformBody = PlacementUtils.getTransformBody(RaycastResult)

            -- Update some variables

            self.raycastStorage = RaycastResult

            self.localHitPos = RaycastResult.pointLocal

            self.localNormal = sm.vec3.closestAxis(RaycastResult.normalLocal)

            -- Can you build there?
            
            if PlacementUtils.isPlaceableFace(RaycastResult, self.localNormal) == 1 then

                -- Get attached object(Shape, joint etc)

                self.attachedObject = PlacementUtils.getAttachedObject(RaycastResult)

                -- Calculate the placement position and rotation

                self.localSurfacePos = PlacementUtils.roundVecToCenterGrid(self.localHitPos + self.localNormal * SubdivideRatio_2) - self.localNormal * SubdivideRatio_2

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


function AdvancedPlacementCore:updateValues()

    self.worldNormal = self.transformBody.worldRotation * self.localNormal

    self.worldSurfacePos = self.transformBody:transformPoint(self.localSurfacePos)

    self.worldSurfaceRot = self.transformBody.worldRotation * self.localSurfaceRot

    local raycastToPlane = PlacementUtils.raycastToPlane(sm.localPlayer.getRaycastStart(), RaycastResult.directionWorld, self.worldSurfacePos, self.worldNormal)

    self.worldDeltaPlacement = raycastToPlane + sm.localPlayer.getRaycastStart() - self.worldSurfacePos

    self.localDeltaPlacement = sm.quat.inverse(self.worldSurfaceRot) * self.worldDeltaPlacement
end


---@param item Uuid
---@param rawItemRotation Quat
---@param planePosition Vec3
---@param planeRotation Quat
---@param relativePosition Vec3
---@param calculateHorizontalDelta boolean
---@param roundUncalculatedHorizontalDelta boolean
---@return Vec3
---@return Quat
function AdvancedPlacementCore.calculatePlacementOnPlane(item, rawItemRotation, planePosition, planeRotation, relativePosition, calculateHorizontalDelta, roundUncalculatedHorizontalDelta)

    if calculateHorizontalDelta == nil then
        
        calculateHorizontalDelta = true
    end

    local localPlacementRot = planeRotation * rawItemRotation
        
    local shapeSize = sm.item.getShapeSize(item) * SubdivideRatio

    local rotatedShapeSize = rawItemRotation * shapeSize

    local roundedOffset = sm.vec3.zero()
    
    if calculateHorizontalDelta then

        roundedOffset = PlacementUtils.roundVecToCenterGrid(relativePosition - rotatedShapeSize / 2) + rotatedShapeSize / 2

    elseif roundUncalculatedHorizontalDelta then
        
        local itemPivotPoint = PlacementUtils.roundVecToCenterGrid(shapeSize / 2) - shapeSize / 2

        roundedOffset = PlacementUtils.roundVecToGrid(relativePosition) + rawItemRotation * itemPivotPoint
    else

        roundedOffset = PlacementUtils.roundVecToGrid(relativePosition)
    end

    roundedOffset.z = math.abs(rotatedShapeSize.z / 2)

    local localPlacementPos = planePosition + planeRotation * roundedOffset

    return localPlacementPos, localPlacementRot
end


function AdvancedPlacementCore:doPhase0()
    
    if PlacementUtils.is6Way(self.currentItem) then

        -- Use 6-Way Interface
    else
        
        -- Which face is the curser pointing at

        -- "placementAxis" is the axis the block is placed on

        local clampedDeltaPlacement = PlacementUtils.clampVec(self.localDeltaPlacement, SubdivideRatio_2 * 0.99)

        local x = clampedDeltaPlacement.x
        local y = clampedDeltaPlacement.y

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

        RotationEffects:showOnly(self.placementAxisAsString)

        RotationEffects:setPosition(self.worldSurfacePos)

        RotationEffects:setRotation(self.worldSurfaceRot)

        -- Calculate Visualization position

        local rawPlacementRot = self.placementAxis * RotationList[ItemRotationStorage[self.placementAxisAsString]]

        self.localPlacementPos, self.localPlacementRot = self.calculatePlacementOnPlane(self.currentItem, rawPlacementRot, self.localSurfacePos, self.localSurfaceRot, clampedDeltaPlacement, UsePositionOnPhase1, RoundToGridOnPhase1)

        -- Show placement visualization

        self.worldPlacementPos = self.transformBody:transformPoint(self.localPlacementPos)

        self.worldPlacementRot = self.transformBody.worldRotation * self.localPlacementRot

        PlacementUtils.setTransforms(VisualizationEffect, self.worldPlacementPos, self.worldPlacementRot)
    end
end


function AdvancedPlacementCore:startPhase1()
    
    self.lockedSelection = true

    RotationEffects:hideAll()
end


function AdvancedPlacementCore:doPhase1()
    
    if self.verticalPositioning == true then

        TransformEffects:showOnly("Z")
        
        local delta = PlacementUtils.roundToGrid(PlacementUtils.raycastToLine(sm.localPlayer.getRaycastStart(), RaycastResult.directionWorld, self.worldPlacementPos, self.worldNormal))

        self.localSurfacePos = self.localSurfacePos + self.localNormal * delta

        self.localPlacementPos = self.localPlacementPos + self.localNormal * delta
    else

        TransformEffects:showOnly({"X", "Y"})

        local rawPlacementRot = self.placementAxis * RotationList[ItemRotationStorage[self.placementAxisAsString]]

        self.localPlacementPos, self.localPlacementRot = self.calculatePlacementOnPlane(self.currentItem, rawPlacementRot, self.localSurfacePos, self.localSurfaceRot, self.localDeltaPlacement, true, false)
    end

    self.worldPlacementPos = self.transformBody:transformPoint(self.localPlacementPos)

    self.worldPlacementRot = self.transformBody.worldRotation * self.localPlacementRot

    TransformEffects:setPositionAndRotation(self.worldPlacementPos, self.worldSurfaceRot)

    PlacementUtils.setTransforms(VisualizationEffect, self.worldPlacementPos, self.worldPlacementRot)
end


function AdvancedPlacementCore:doPhase2()

    TransformEffects:hideAll()

    if self.raycastStorage.type == "body" then
        self.network:sendToServer("sv_createPart", {self.raycastStorage:getShape(), self.currentItem, self.localPlacementPos, self.localPlacementRot, true})
    
    elseif self.raycastStorage.type == "joint" then
        self.network:sendToServer("sv_createPart", {self.raycastStorage:getJoint(), self.currentItem, self.localPlacementPos, self.localPlacementPos, true})
    end

    self:resetPlacement()
end

function AdvancedPlacementCore:managePhases()
    
    if self.primaryState == 0 then
        
        self:doPhase0()

    elseif self.primaryState == 1 then

        self.positionSelectionTime = sm.game.getCurrentTick()
        
        self:startPhase1()
    
    elseif self.primaryState == 2 then
        
        if sm.game.getCurrentTick() >= self.positionSelectionTime + PositionSelectionTimer then 

            self:doPhase1()
        end
    
    elseif self.primaryState == 3 then

        self:doPhase2()
    end
end


function AdvancedPlacementCore:doFrame()
    
    RaycastSuccess, RaycastResult = sm.localPlayer.getRaycast(PlacementRadii)

    local lastItem = self.currentItem

    self.currentItem = sm.localPlayer.getActiveItem()

    self.currentItemAsString = tostring(self.currentItem)

    if lastItem ~= self.currentItem then

        self.placementRotationStorage[tostring(lastItem)] = ItemRotationStorage

        ItemRotationStorage = self.placementRotationStorage[self.currentItemAsString]
        
        self.itemHasChanged = true
        self.isPart = sm.item.isPart(self.currentItem)-- or sm.item.isJoint(self.currentItem)

        self:resetPlacement()

        VisualizationEffect:stop()

        VisualizationEffect:setParameter("uuid", self.currentItem)
    else
        self.itemHasChanged = false
    end

    
    self.doingPlacement = self:calculateSurfacePosition() and self.isPart

    if self.doingPlacement then

        VisualizationEffect:stop()

        VisualizationEffect:start()

        self:updateValues()
            
        self:managePhases()
    else

        VisualizationEffect:stop()

        -- Don't show the effect

        self:resetPlacement()
    end
end