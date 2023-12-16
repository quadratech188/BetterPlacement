
BPDebug = true

if BPLoaded == nil or BPDebug == true then
    
    dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")
    dofile("$CONTENT_DATA/Scripts/EffectSet.lua")
    dofile("$CONTENT_DATA/Scripts/DefaultBody.lua")
    dofile("$CONTENT_DATA/Scripts/Effects.lua")
    dofile("$CONTENT_DATA/Scripts/PartVisualization.lua")
    dofile("$CONTENT_DATA/Scripts/PieMenu.lua")

    BPLoaded = true
end