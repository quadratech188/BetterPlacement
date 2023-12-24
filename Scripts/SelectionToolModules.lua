
function GetSelectionToolModules()
    
    local M = {modules = {}, cl_callbacks = {}, sv_callbacks = {}}

    --[[
    # Modules

    Callbacks:
    start(self): Called when the module is first loaded
    doFrame(self): Called every frame when the module is loaded
    stop(self): Called when the module is terminated externally

    Functions:
    terminate: Asks for the module to be terminated
    
    Attributes:
    network: A network object for sending data to serverside functions
    shape: The targeted shape
    highLightEffect: A preexisting effect that highlights the targeted shape
    primaryState, secondaryState, toggleState, reloadState, forceBuild: The states of the corresponding buttons
    raycastResult: The current raycast result of the player
    settings: General settings (TBD)
    ]]

    function M.sv_callbacks.sv_createPart(args)
        
        UsefulUtils.sv_createPart(nil, args)
    end


    function M.sv_callbacks.sv_move(args)

        print(args)
        
        ---@type Shape
        local originalShape = args[1]

        ---@type Vec3
        local newPosition = args[2]

        ---@type Body
        local parentBody = args[3]

        -- Create new shape
        ---@type Shape
        ---@diagnostic disable-next-line: assign-type-mismatch
        local newShape = UsefulUtils.sv_createPart(nil, {originalShape.uuid, parentBody, newPosition, originalShape.localRotation, true, originalShape.color})
        
        print(originalShape)
        print(newShape)

        if originalShape.interactable ~= nil then -- Copy over interactable properties

            local children = originalShape.interactable:getChildren()
            
            for _, child in pairs(children) do

                newShape.interactable:connect(child)
            end

            local parents = originalShape.interactable:getParents()

            for _, parent in pairs(parents) do
                
                parent:connect(newShape.interactable)
            end

            local joints = originalShape.interactable:getJoints()

            for _, joint in pairs(joints) do
                
                -- newShape.interactable:connectToJoint(joint)
            end
        end

        -- Destroy originalShape
        originalShape:destroyPart(0)
    end


    M.modules.move = {

        start = function (self)
            
            M.modules.duplicate.start(self)
        end,

        doFrame = function (self)

            -- Use the duplicate function for controls
            M.modules.duplicate.doFrame(self, false)

            -- Add deletion indicator

            self.highLightEffect:setParameter("valid", false)

            UsefulUtils.highlightShape(self.highLightEffect, self.shape)

            -- Overwrite Hotkeys

            sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Rotate Axis")
            sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Relocate")

            -- Copy over connections, create new shape, delete original shape

            if self.reloadState then
            
                self.network:sendToServer("sv_move", {self.shape, self.partPos, self.parentBody})
            end

            if self.reloadState or self.secondaryState ~= 0 then -- Reset conditions

                self:stop()
            end
        end,

        stop = function (self)

            -- Return highLightEffect to normal
            self.highLightEffect:stop()
            self.highLightEffect:setParameter("valid", true)
            
            M.modules.duplicate.stop(self) -- This terminates the module
        end
    }


    M.modules.duplicate = {

        start = function (self)

            -- Create visualizationEffect

            self.visualizationEffect = SmartEffect.new(self.shape.uuid)

            self.visualizationEffect:setParameter("color", self.shape:getColor())
            self.visualizationEffect:setScale(SubdivideRatio)
            self.visualizationEffect:start()

            -- Create transformGizmo
            
            self.transformGizmo = BPEffects.createTransformGizmo()

            -- We don't need highLightEffect

            self.highLightEffect:stop()

            self.parentBody = self.shape:getBody()

            self.directionNum = 0

            self.vecDirections = {
                [0] = PosX,
                [1] = PosY,
                [2] = PosZ
            }

            self.strDirections = {
                [0] = "X",
                [1] = "Y",
                [2] = "Z"
            }

            self.direction = PosX
            self.transformGizmo:showOnly({"X", "Base"})

            self.partPos = UsefulUtils.getActualLocalPos(self.shape)
            self.cursorPos = self.partPos
            self.initialOffset = 0
        end,

        doFrame = function (self, isMain)
            
            if isMain == nil then
                isMain = true
            end
    
            -- Compatibility for move
            if isMain == true then
                sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Rotate Axis")
                sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Paste")
            end
    
            local localRaycastOrigin = UsefulUtils.worldToLocalPos(self.raycastResult.originWorld, self.parentBody)
    
            local localRaycastDirection = UsefulUtils.worldToLocalDir(self.raycastResult.directionWorld, self.parentBody)
            
            if self.toggleState then
    
                if self.settings.onlySwitchAxisWhenMouseIsInActive and self.primaryState ~= 0 then
                    
                    goto skip
                end
                
                self.directionNum = self.directionNum + 1
                
                if self.directionNum == 3 then
                    self.directionNum = 0
                end
                
                self.direction = self.vecDirections[self.directionNum]
    
                self.transformGizmo:showOnly({self.strDirections[self.directionNum], "Base"})
            end
            
            ::skip::
    
            if self.primaryState == 1 or self.primaryState == 2 then -- If left mouse is clicked
                
                local offset = UsefulUtils.raycastToLine(localRaycastOrigin, localRaycastDirection, self.cursorPos, self.direction).pointLocal.z
    
                self.cursorPos = self.cursorPos + self.direction * (offset - self.initialOffset)
    
                self.partPos = self.partPos + UsefulUtils.roundVecToGrid(self.cursorPos - self.partPos)
            end
    
            -- Set position of visualizationEffect
            self.visualizationEffect:setTransforms({self.parentBody:transformPoint(self.partPos), self.shape.worldRotation, nil})
    
            -- Set position of transformGizmo
            self.transformGizmo:setPositionAndRotation(self.parentBody:transformPoint(self.cursorPos), self.parentBody.worldRotation)
    
            if self.reloadState then -- If selection has ended
    
                if isMain then
    
                    -- Build part
                    
                    self.network:sendToServer("sv_createPart", {self.shape.uuid, self.parentBody, self.partPos, self.shape.localRotation, true, self.shape.color})

                    self:stop()
                end
            end
        end,

        stop = function (self)

            self.visualizationEffect:destroy()
            self.visualizationEffect = nil
            self.transformGizmo:destroy()
            self.transformGizmo = nil

            self.terminate()
        end
    }

    M.modules.back = {

        start = function (self)
            
        end,

        doFrame = function (self)
            
            self:stop()
        end,

        stop = function (self)
            
            self.terminate(self)
        end
    }

    return M
end