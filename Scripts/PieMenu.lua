 
dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")

---@class PieMenu
---@field worldGui GuiInterface
---@field position Vec3
---@field new function
---@field initialize function
---@field setPosition function
---@field open function
---@field getSelection function
---@field close function


PieMenu = class()


---@param effects table
---@return PieMenu
function PieMenu.new(guiPath, numberOfSegments)

	---@type PieMenu
	local returnClass = class(PieMenu)

	returnClass:initialize(guiPath, numberOfSegments)

	return returnClass
end


function PieMenu:initialize(guiPath, numberOfSegments)
    
    self.worldGui = sm.gui.createWorldIconGui(1920, 1080, guiPath, false)

    self.position = sm.vec3.zero()

    self.debugeffect = SmartEffect.new(sm.uuid.new("4a91af39-7095-4497-8930-b9105e8a236d"))

    self.debugeffect:start()

    self.debugeffect:setOffsetTransforms({nil, nil, sm.vec3.new(1, 0.1, 1)})
end


function PieMenu:setPosition(pos)
    
    self.position = pos
end


function PieMenu:open()
    
    self.worldGui:open()
end


function PieMenu:doFrame()
    
    local pos = sm.camera.getPosition()
    local rot = sm.camera.getRotation()
    local offset = UsefulUtils.raycastToPlane(sm.camera.getPosition(), sm.camera.getDirection(), self.position, sm.camera.getRotation() * QuatPosY).pointLocal

    local angle = math.atan2(offset.y, offset.x)

    print(angle)
end


function PieMenu:close()
    
    self.worldGui:open()

    return PieMenu:doFrame()
end