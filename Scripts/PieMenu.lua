
dofile("$CONTENT_DATA/Scripts/FakeCursor.lua")

PieMenu = class()

---See PieMenu.new
---@param gui GuiInterface
---@param numberOfSegments integer
---@param startAngle number
---@param deadzone number
---@param callback function
function PieMenu:initialize(gui, numberOfSegments, startAngle, deadzone, callback)
    
    self.gui = gui
    self.numberOfSegments = numberOfSegments
    self.startAngle = startAngle
    self.deadzone = deadzone
    self.callback = callback

    self.gui:createHorizontalSlider("cursor", 1, 1, "")
    
    self.opened = false

    self.cursor = FakeCursor.new(sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/FakeCursorGUI.layout", false, {isHud = true}))
end


---Create and return a new PieMenu 
---@param gui GuiInterface The GUI that is opened when the Pie Menu is opened.
---@param numberOfSegments integer The number of segments(options) in the Pie Menu
---@param startAngle number The angle(in degrees) that the clockwise edge of the 0th option is facing
---@param deadzone number The pie menu won't do anything if the distance between the curser and the center of the screen is less than the deadzone (pixels)
---@param callback function Is called when the menu is closed
function PieMenu.new(gui, numberOfSegments, startAngle, deadzone, callback)
    
    local returnClass = class(PieMenu)

    returnClass:initialize(gui, numberOfSegments, startAngle, deadzone, callback)

    return returnClass
end


function PieMenu:open()
    
    self.gui:open()
    self.opened = true
end


function PieMenu:doFrame()
    if self.opened then

        self.cursor:doFrame()
    end
end


function PieMenu:close()
    
    self.gui:close()
    self.opened = false
end


function PieMenu:getLocation()
    

end