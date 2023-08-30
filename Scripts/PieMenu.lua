
dofile("$CONTENT_DATA/Scripts/FakeCursor.lua")

PieMenu = class()


---Initialize
---@param gui GuiInterface The GUI that is opened when the Pie Menu is opened
---@param numberOfSegments integer The number of segments(options) in the Pie Menu
---@param startAngle number The angle(in degrees) that the clockwise edge of the 0th option is facing
---@param highlightActions table The actions to be called when a certain pie menu item is hovered over. e.g. {[0] = function() {print("0")}, [1] = ...}
---@param returnActions table The actions to be called when the PieMenu is closed while a certain pie menu item is being hovered over.
---@param deadzone number The pie menu won't do anything if the distance between the curser and the center of the screen is less than the deadzone (pixels)
function PieMenu:initialize(gui, numberOfSegments, startAngle, highlightActions, returnActions, deadzone)
    
    self.gui = gui
    self.numberOfSegments = numberOfSegments
    self.startAngle = startAngle
    self.highlightActions = highlightActions
    self.returnActions = returnActions
    self.deadzone = deadzone

    self.gui:createHorizontalSlider("cursor", 1, 1, "")
    
    self.opened = false

    self.cursor = FakeCursor.new()
end


---Create and return a new PieMenu 
---@param gui GuiInterface The GUI that is opened when the Pie Menu is opened. requires a widget called 'cursor'
---@param numberOfSegments integer The number of segments(options) in the Pie Menu
---@param startAngle number The angle(in degrees) that the clockwise edge of the 0th option is facing
---@param highlightActions table The actions to be called when a certain pie menu item is hovered over. e.g. {[0] = function() {print("0")}, [1] = ...}
---@param returnActions any
---@param deadzone any
function PieMenu.new(gui, numberOfSegments, startAngle, highlightActions, returnActions, deadzone)
    
    local returnClass = class(PieMenu)

    returnClass:initialize(gui, numberOfSegments, startAngle, highlightActions, returnActions, deadzone)

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