
local Debugging = true

if BPLoadedBasics == nil or Debugging == true then
    
    dofile("$CONTENT_DATA/Scripts/UsefulUtils.lua")
    dofile("$CONTENT_DATA/Scripts/EffectSet.lua")
    dofile("$CONTENT_DATA/Scripts/DefaultBody.lua")
    dofile("$CONTENT_DATA/Scripts/Effects.lua")
    dofile("$CONTENT_DATA/Scripts/PartVisualization.lua")
    dofile("$CONTENT_DATA/Scripts/PieMenu.lua")

    BPLoadedBasics = true
end