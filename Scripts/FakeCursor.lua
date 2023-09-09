
FakeCursor = class()


---See FakeCursor.new
function FakeCursor:initialize(cursorGui)
    self.position = {
        x = 0,
        y = 0
    }

    self.gui = cursorGui
end

---Creates a new FakeCursor
---@param cursorGui GuiInterface GUI for the cursor (requires isHud = true)
function FakeCursor.new(cursorGui)
    
    local returnClass = class(FakeCursor)

    returnClass:initialize(cursorGui)

    return returnClass
end

function FakeCursor:doFrame()

    local mouseDeltaX, mouseDeltaY = sm.localPlayer.getMouseDelta()
    
    self.position.x = self.position.x + mouseDeltaX
    self.position.y = self.position.y + mouseDeltaY

    print(self.position)
end

function FakeCursor:setPosition(pos)
    
    self.position = pos
end

function FakeCursor:getPosition()
    
    return self.position
end