
dofile("$CONTENT_DATA/Scripts/FakeCursor.lua")
dofile("$CONTENT_DATA/Scripts/FakeScreenGUI.lua")

SelectionToolPieMenu = class()


function SelectionToolPieMenu:open()
    
    self.gui:open()
    self.opened = true
end


function SelectionToolPieMenu:doFrame()

end


function SelectionToolPieMenu:close()
    
    self.gui:close()
    self.opened = false
end