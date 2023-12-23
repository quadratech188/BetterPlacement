
function GetSelectionToolModules()
    
    local M = {sv = {}, cl = {}}


    function M.sv.sv_createPart(args)
        
        UsefulUtils.sv_createPart(nil, args)
    end


    function M.cl.move(sandBox)
        
        if sandBox.initialize == true then

            if sandBox.shape:getInteractable() ~= nil then
            end
            
            -- sandBox.initialize will be set to false by SelectionToolClass:duplicate, we don't do it yet
        end
        
        -- Use the duplicate function for controls
        M.cl.duplicate(sandBox, false)

        -- Add deletion indicator

        sandBox.highLightEffect:setParameter("valid", false)

        UsefulUtils.highlightShape(sandBox.highLightEffect, sandBox.shape)

        -- Overwrite Hotkeys

        sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Rotate Axis")
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Relocate")

        if sandBox.reloadState then
            
            sandBox.network:sendToServer("sv_move", {sandBox.shape, sandBox.partPos, sandBox.parentBody})
        end

        if sandBox.reloadState or sandBox.secondaryState ~= 0 then -- Reset conditions
            
            -- Return highLightEffect to normal
            sandBox.highLightEffect:stop()
            sandBox.highLightEffect:setParameter("valid", true)
        end
    end


    function M.sv.sv_move(args)

        print(args)
        
        ---@type Shape
        local originalShape = args[1]

        ---@type Vec3
        local newPosition = args[2]

        ---@type Body
        local parentBody = args[3]

        -- Create new shape
        ---@type Shape
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


    function M.cl.duplicate(sandBox, isMain)

        if isMain == nil then
            isMain = true
        end

        -- Compatibility for move
        if isMain == true then
            sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Rotate Axis")
            sm.gui.setInteractionText("", sm.gui.getKeyBinding("Reload", true), "Paste")
        end

        if sandBox.initialize then
            
            -- Create visualizationEffect

            sandBox.visualizationEffect = SmartEffect.new(sandBox.shape.uuid)

            sandBox.visualizationEffect:setParameter("color", sandBox.shape:getColor())
            sandBox.visualizationEffect:setScale(SubdivideRatio)
            sandBox.visualizationEffect:start()

            -- Create transformGizmo
            
            sandBox.transformGizmo = BPEffects.createTransformGizmo()

            -- We don't need highLightEffect

            sandBox.highLightEffect:stop()

            sandBox.parentBody = sandBox.shape:getBody()

            sandBox.directionNum = 0

            sandBox.vecDirections = {
                [0] = PosX,
                [1] = PosY,
                [2] = PosZ
            }

            sandBox.strDirections = {
                [0] = "X",
                [1] = "Y",
                [2] = "Z"
            }

            sandBox.direction = PosX
            sandBox.transformGizmo:showOnly({"X", "Base"})

            sandBox.partPos = UsefulUtils.getActualLocalPos(sandBox.shape)
            sandBox.cursorPos = sandBox.partPos
            sandBox.initialOffset = 0

            sandBox.initialize = false
        end

        local localRaycastOrigin = UsefulUtils.worldToLocalPos(sandBox.raycastResult.originWorld, sandBox.parentBody)

        local localRaycastDirection = UsefulUtils.worldToLocalDir(sandBox.raycastResult.directionWorld, sandBox.parentBody)
        
        if sandBox.toggleState then

            if sandBox.settings.onlySwitchAxisWhenMouseIsInActive and sandBox.primaryState ~= 0 then
                
                goto skip
            end
            
            sandBox.directionNum = sandBox.directionNum + 1
            
            if sandBox.directionNum == 3 then
                sandBox.directionNum = 0
            end
            
            sandBox.direction = sandBox.vecDirections[sandBox.directionNum]

            sandBox.transformGizmo:showOnly({sandBox.strDirections[sandBox.directionNum], "Base"})
        end
        
        ::skip::

        if sandBox.primaryState == 1 or sandBox.primaryState == 2 then -- If left mouse is clicked
            
            local offset = UsefulUtils.raycastToLine(localRaycastOrigin, localRaycastDirection, sandBox.cursorPos, sandBox.direction).pointLocal.z

            sandBox.cursorPos = sandBox.cursorPos + sandBox.direction * (offset - sandBox.initialOffset)

            sandBox.partPos = sandBox.partPos + UsefulUtils.roundVecToGrid(sandBox.cursorPos - sandBox.partPos)
        end

        -- Set position of visualizationEffect
        sandBox.visualizationEffect:setTransforms({sandBox.parentBody:transformPoint(sandBox.partPos), sandBox.shape.worldRotation, nil})

        -- Set position of transformGizmo
        sandBox.transformGizmo:setPositionAndRotation(sandBox.parentBody:transformPoint(sandBox.cursorPos), sandBox.parentBody.worldRotation)

        if sandBox.reloadState then -- If selection has ended

            if isMain then

                -- Build part
                
                sandBox.network:sendToServer("sv_createPart", {sandBox.shape.uuid, sandBox.parentBody, sandBox.partPos, sandBox.shape.localRotation, true, sandBox.shape.color})
            end
        end

        if sandBox.reloadState or sandBox.secondaryState ~= 0 then -- Reset conditions

            sandBox.visualizationEffect:destroy()
            sandBox.visualizationEffect = nil
            sandBox.transformGizmo:destroy()
            sandBox.transformGizmo = nil

            sandBox.reset()
        end
    end

    return M
end