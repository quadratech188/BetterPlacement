
local Debugging = true

if BPLoaded == nil or Debugging == true then
    
    dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")
    dofile("$CONTENT_DATA/Scripts/EffectSet.lua")
    dofile("$CONTENT_DATA/Scripts/DefaultBody.lua")
    dofile("$CONTENT_DATA/Scripts/Effects.lua")
    dofile("$CONTENT_DATA/Scripts/PartVisualization.lua")
    dofile("$CONTENT_DATA/Scripts/PieMenu.lua")

    BPLoaded = true
end