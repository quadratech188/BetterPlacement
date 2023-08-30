
FakeCursor = class()

function FakeCursor:initialize()
    self.position = {
        x = 0,
        y = 0
    }
end

function FakeCursor.new()
    
    local returnClass = class(FakeCursor)

    returnClass:initialize()

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
    
end