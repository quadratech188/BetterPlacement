
---@class TerrainBody

TerrainBody = class()

TerrainBody.worldPosition = sm.vec3.zero()

TerrainBody.worldRotation = sm.quat.identity()

TerrainBody.type = "TerrainBody"


function TerrainBody:transformPoint(pos)
	
	return pos
end


function TerrainBody:createPart(a, b, c, d, e)
	
	--sm.shape.createPart(a, b, c, d, e)

	print("Ignored!")
end

--------------------------------------------------------------------------------------------

LiftBody = class(TerrainBody)


function LiftBody:createPart(a, b, c, d, e)
	

end