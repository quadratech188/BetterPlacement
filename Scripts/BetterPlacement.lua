
---@class BetterPlacement:ToolClass

dofile("$SURVIVAL_DATA/Scripts/game/survival_shapes.lua")

dofile("$CONTENT_DATA/Scripts/PlacementUtils.lua")


BetterPlacement = class()


function BetterPlacement:refreshRotationStorage(hotbar)

    if not hotbar:hasChanged(sm.game.getServerTick() - 1) then
        
        return
    end

    for key, item in pairs(self.currentHotbar) do

        print(self.currentHotbar)

        -- Create entries for new items

        if not sm.util.contains(item, self.lastHotbar) then

            print(item)
            
            PlacementRotationStorage[tostring(item)] = {
                ["+X"] = 0,
                ["+Y"] = 0,
                ["+Z"] = 0,
                ["-X"] = 0,
                ["-Y"] = 0
            }
        end
    end

    for key, item in pairs(self.lastHotbar) do

        -- Delete entries for nonexistant items

        if not sm.util.contains(item, self.currentHotbar) then
            
            PlacementRotationStorage[tostring(item)] = nil
        end
    end
end


function BetterPlacement:showSelectionEffect()
    
    if self.lastAxisAsString == nil then

        PlacementEffects[self.placementAxisAsString]:start()

    elseif self.lastAxisAsString ~= self.placementAxisAsString then

        PlacementEffects[self.lastAxisAsString]:stop()
        PlacementEffects[self.placementAxisAsString]:start()
    end

    PlacementEffects[self.placementAxisAsString]:setPosition(self.worldSurfacePos)
    PlacementEffects[self.placementAxisAsString]:setRotation(self.worldNormalRot)

    self.lastAxisAsString = self.placementAxisAsString
    
end

--- @param data table The table of data for the placement; {raycastResult, uuid, localPosition, localRotation, forceAccept}
function BetterPlacement:sv_createPart(data)

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

        print(localPlacementPosition)

        if sm.item.isPart(uuid) then
            
            parent:getBody():createPart(uuid, localPlacementPosition, zAxis, xAxis, forceAccept)
            
        elseif sm.item.isJoint(uuid) then

            parent:createJoint(uuid, localPlacementPosition / SubdivideRatio, zAxis)
        end
    end
end

function BetterPlacement:onToggle()
    
    if self.primaryState == 0 then

        -- Shape rotation

        PlacementRotationStorage[self.currentItemAsString][self.placementAxisAsString] = (PlacementRotationStorage[self.currentItemAsString][self.placementAxisAsString] + 1) % 4

    elseif self.primaryState == 1 or self.primaryState == 2 then

        -- Vertical Positioning

        self.verticalPositioning = not self.verticalPositioning
    end
end


function BetterPlacement:onReload()
    
    if self.primaryState == 0 then
        
        self.lockedSelection = not self.lockedSelection
    end
end


function BetterPlacement:initializeMod()

    sm.gui.chatMessage("Initializing BetterPlacement Mod")
    print("Initializing BetterPlacement Mod")
    
    -- Set initial variables

    self.currentItem = nil

    self.currentHotbar = {"placeholder"}

    self.lastAxisAsString = nil

    PlacementRotationStorage = {}

    -- Set constants

    SubdivideRatio_2 = sm.construction.constants.subdivideRatio_2
    SubdivideRatio = sm.construction.constants.subdivideRatio
    
    BlockSize = sm.vec3.new(1, 1, 1) * SubdivideRatio
    PlacementRadii = 7.5
    CenterSize = 0.46875
    PositionSelectionTimer = 5

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

    Quat90 = sm.quat.angleAxis(- math.pi / 2, PosZ)

    RotationList = {
        [0] = sm.quat.identity(),
        [1] = Quat90,
        [2] = Quat90 * Quat90,
        [3] = Quat90 * Quat90 * Quat90
    }

    SupportedSurfaces = {"body", "joint", "terrainSurface", "terrainAsset"}

    -- Initialize placement selection effects

    local placementUuids = {
        ["+X"] =  "03422fac-1103-4f93-9206-5324c1406a86",
        ["+Y"] = "728e9744-9b40-45e7-9c0a-0e386f01e592",
        ["+Z"] = "d8fc440b-ad25-45db-b72b-36a99414435b",
        ["-X"] = "8cbaa03b-90f2-42fc-888b-1626650325c5",
        ["-Y"] = "01e9830e-4b80-47b5-9cbb-736024f12d53"

    }

    PlacementEffects = {}

    for direction, uuid in pairs(placementUuids) do

        local effect = sm.effect.createEffect("ShapeRenderable")

        effect:setParameter("uuid", sm.uuid.new(uuid))
        effect:setScale(BlockSize)
        
        PlacementEffects[direction] = effect
    end
    
    -- Start at +Z effect

    PlacementEffects["+Z"]:start()

    -- visualization effect

    VisualizationEffect = sm.effect.createEffect("ShapeRenderable")
    VisualizationEffect:setScale(BlockSize)
    VisualizationEffect:setParameter("visualization", true)

    -- Testing purposes

    TestEffect = sm.effect.createEffect("ShapeRenderable")
    TestEffect:setParameter("uuid", sm.uuid.new("ed27f5e2-cac5-4a32-a5d9-49f116acc6af"))
    TestEffect:setScale(BlockSize)
    TestEffect:setParameter("visualization", true)
    TestEffect:start()

    -- Initialize placement

    BetterPlacement.resetPlacement(self)

    sm.gui.chatMessage("Initialized BetterPlacement Mod")
    print("Initialized BetterPlacement Mod")
end


function BetterPlacement:resetPlacement()

    self.lockedSelection = false
            -- Whether selection is locked to a face

    if self.lastAxisAsString ~= nil then
        
        PlacementEffects[self.lastAxisAsString]:stop()
    end

    self.lastAxisAsString = nil

    self.primaryState = nil

    self.verticalPositioning = false

    VisualizationEffect:stop()
end


function BetterPlacement:calculatePlacementPosition(delta)

    local placementDeltaRot = self.placementAxis * RotationList[PlacementRotationStorage[self.currentItemAsString][self.placementAxisAsString]]

    self.localPlacementRot = self.localNormalRot * placementDeltaRot
    
    self.worldPlacementRot = self.transformBody.worldRotation * self.localPlacementRot

    -- Find Relative Placement Position
        
    local shapeSize = sm.item.getShapeSize(self.currentItem) * SubdivideRatio

    local rotatedShapeSize = placementDeltaRot * shapeSize

    local roundedOffset = PlacementUtils.roundVecToCenterGrid(delta - rotatedShapeSize / 2) + rotatedShapeSize / 2

    roundedOffset.z = math.abs(rotatedShapeSize.z / 2)

    self.localPlacementPos = self.localSurfacePos + self.localNormalRot * roundedOffset

    self.worldPlacementPos = self.transformBody:transformPoint(self.localPlacementPos)
end


function BetterPlacement:calculateSurfacePosition()
    
    if self.lockedSelection == false then
        
        if RaycastSuccess then
            
            -- Don't process unsupported types

            if not sm.util.contains(RaycastResult.type, SupportedSurfaces) then
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

            self.worldNormal = self.transformBody.worldRotation * self.localNormal

            -- Can you build there?
            
            if PlacementUtils.isPlaceableFace(RaycastResult, self.localNormal) == 1 then

                -- Get attached object(Shape, joint etc)

                self.attachedObject = PlacementUtils.getAttachedObject(RaycastResult)

                -- Calculate the placement position and rotation

                self.localSurfacePos = PlacementUtils.roundVecToCenterGrid(self.localHitPos + self.localNormal * SubdivideRatio_2) - self.localNormal * SubdivideRatio_2

                self.worldSurfacePos = self.transformBody:transformPoint(self.localSurfacePos)

                self.localNormalRot = sm.vec3.getRotation(sm.vec3.new(0,0,1), self.localNormal)

                self.worldNormalRot = self.transformBody.worldRotation * self.localNormalRot

                -- Figure out where the curser is pointing to on the plane

                local raycastToPlane = PlacementUtils.raycastToPlane(sm.localPlayer.getRaycastStart(), RaycastResult.directionWorld, self.worldSurfacePos, self.worldNormal)
    
                self.worldDeltaPlacement = raycastToPlane + sm.localPlayer.getRaycastStart() - self.worldSurfacePos

                self.localDeltaPlacement = sm.quat.inverse(self.worldNormalRot) * self.worldDeltaPlacement

                return true

            else
                return false
            end

        else
            return false
        end
    
    else

        -- Check I can still build there

        if not sm.exists(self.attachedObject) then
            
            return false
        end

        -- I just copied these bits lol

        self.worldNormal = self.transformBody.worldRotation * self.localNormal

        self.worldSurfacePos = self.transformBody:transformPoint(self.localSurfacePos)

        self.worldNormalRot = self.transformBody.worldRotation * self.localNormalRot

        local raycastToPlane = PlacementUtils.raycastToPlane(sm.localPlayer.getRaycastStart(), RaycastResult.directionWorld, self.worldSurfacePos, self.worldNormal)

        self.worldDeltaPlacement = raycastToPlane + sm.localPlayer.getRaycastStart() - self.worldSurfacePos

        self.localDeltaPlacement = sm.quat.inverse(self.worldNormalRot) * self.worldDeltaPlacement

        return true
    end

end


function BetterPlacement:doPhase0()
    
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
    
        -- Make selection effect
        
        BetterPlacement.showSelectionEffect(self)

        -- Calculate Visualization position

        BetterPlacement.calculatePlacementPosition(self, clampedDeltaPlacement)

        -- Show placement visualization

        VisualizationEffect:setPosition(self.worldPlacementPos)
        
        VisualizationEffect:setRotation(self.worldPlacementRot)
    end
end


function BetterPlacement:startPhase1()
    
    self.lockedSelection = true

    PlacementEffects[self.placementAxisAsString]:stop()
end


function BetterPlacement:doPhase1()
    
    if self.verticalPositioning == true then
        
        local delta = PlacementUtils.roundToGrid(PlacementUtils.raycastToLine(sm.localPlayer.getRaycastStart(), RaycastResult.directionWorld, self.worldPlacementPos, self.worldNormal))

        self.localSurfacePos = self.localSurfacePos + self.localNormal * delta

        self.localPlacementPos = self.localPlacementPos + self.localNormal * delta

        self.worldPlacementPos = self.transformBody:transformPoint(self.localPlacementPos)

        self.worldPlacementRot = self.transformBody.worldRotation * self.localPlacementRot
    else

        BetterPlacement.calculatePlacementPosition(self, self.localDeltaPlacement)
    end

    VisualizationEffect:setPosition(self.worldPlacementPos)
            
    VisualizationEffect:setRotation(self.worldPlacementRot)
end


function BetterPlacement:doPhase2()

    if self.raycastStorage.type == "body" then
        self.network:sendToServer("sv_createPart", {self.raycastStorage:getShape(), self.currentItem, self.localPlacementPos, self.localPlacementRot, true})
    
    elseif self.raycastStorage.type == "joint" then
        self.network:sendToServer("sv_createPart", {self.raycastStorage:getJoint(), self.currentItem, self.localPlacementPos, self.localPlacementPos, true})
    end

    BetterPlacement.resetPlacement(self)
end

function BetterPlacement:managePhases()
    
    if self.primaryState == 0 then
        
        BetterPlacement.doPhase0(self)

    elseif self.primaryState == 1 then

        self.positionSelectionTime = sm.game.getCurrentTick()
        
        BetterPlacement.startPhase1(self)
    
    elseif self.primaryState == 2 then
        
        if sm.game.getCurrentTick() >= self.positionSelectionTime + PositionSelectionTimer then 

            BetterPlacement.doPhase1(self)
        end
    
    elseif self.primaryState == 3 then

        BetterPlacement.doPhase2(self)
    end



end


function BetterPlacement:doFrame()
    
    RaycastSuccess, RaycastResult = sm.localPlayer.getRaycast(PlacementRadii)

    self.lastItem = self.currentItem

    self.currentItem = sm.localPlayer.getActiveItem()
    self.currentItemAsString = tostring(self.currentItem)
    
    if self.lastItem ~= self.currentItem then
        
        self.itemHasChanged = true
        self.isPart = sm.item.isPart(self.currentItem) or sm.item.isJoint(self.currentItem)

        BetterPlacement.resetPlacement(self)

        VisualizationEffect:stop()

        VisualizationEffect:setParameter("uuid", self.currentItem)
    else
        self.itemHasChanged = false
    end

    local currentHotbar = sm.localPlayer.getHotbar()

    BetterPlacement:refreshRotationStorage(currentHotbar)
    
    self.doingPlacement = BetterPlacement.calculateSurfacePosition(self) and self.isPart

    if self.doingPlacement then

        VisualizationEffect:stop()

        VisualizationEffect:start()
            
        BetterPlacement.managePhases(self)
    else

        VisualizationEffect:stop()

        -- Don't show the effect

        BetterPlacement.resetPlacement(self)
    end
end