 
dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")

---@class PieMenu
---@field worldGui GuiInterface
---@field position Vec3
---@field new function
---@field initialize function
---@field setPosition function
---@field open function
---@field getSelection function
---@field doFrame function
---@field close function


PieMenu = class()


---@param guiPath string
---@param numberOfSegments integer
---@param deadzone number
---@return PieMenu
function PieMenu.new(guiPath, numberOfSegments, deadzone)

	---@type PieMenu
	local returnClass = class(PieMenu)

	returnClass:initialize(guiPath, numberOfSegments, deadzone)

	return returnClass
end


function PieMenu:initialize(guiPath, numberOfSegments, deadzone)
    
    self.worldGui = sm.gui.createWorldIconGui(1920, 1080, guiPath, false)

    self.numberOfSegments = numberOfSegments

    self.deadzone = deadzone

    self.position = sm.vec3.zero()

    self.debugEffect = SmartEffect.new(sm.uuid.new("4a91af39-7095-4497-8930-b9105e8a236d"))

    self.debugEffect:start()

    self.debugEffect:setOffsetTransforms({nil, nil, sm.vec3.new(1, 0.1, 1)})

    for i = 1, numberOfSegments, 1 do
        
        -- All buttons start as off
        self.worldGui:setVisible(tostring(i), false)
    end
end


function PieMenu:setPosition(pos)
    
    self.position = pos

    self.worldGui:setWorldPosition(self.position)
end


function PieMenu:open()
    
    self.worldGui:open()
end


function PieMenu:doFrame()

    self.worldGui:setVisible(tostring(self.index), false)
    
    local pos = sm.camera.getPosition()
    local rot = sm.camera.getRotation()
    local raycast = UsefulUtils.raycastToPlane(sm.camera.getPosition(), sm.camera.getDirection(), self.position, sm.camera.getRotation() * QuatPosY)
    local offset = raycast.pointLocal
    local distance = math.abs(raycast.distanceToPlane)

    -- math.atan doesn't work
    local angle = math.atan2(offset.y, offset.x) -- -pi to pi

    local angleFromFirst = angle + math.pi / 2 + math.pi / self.numberOfSegments

    if angleFromFirst < 0 then
        angleFromFirst = angleFromFirst + 2 * math.pi
    end

    self.index = math.ceil(angleFromFirst / (2 * math.pi) * self.numberOfSegments)

    if offset:length() < self.deadzone * distance then
        self.index = 0
    end

    self.worldGui:setVisible(tostring(self.index), true)

    return self.index
end


function PieMenu:close()
    
    self.worldGui:close()

    return self:doFrame()
end