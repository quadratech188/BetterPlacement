
BPEffects = {}

BPEffects.colours = {
    white = sm.color.new(0.8, 0.8, 0.8, 1),
    highlight = sm.color.new(0, 0, 0.8, 1),
    red = sm.color.new("9F0000"),
    green = sm.color.new("009F00"),
    blue = sm.color.new("00008F")
}

function BPEffects.createTransformGizmo()

    local cubeUuid = sm.uuid.new("4a91af39-7095-4497-8930-b9105e8a236d")

	local transformGizmoUuids = {
		["Base"] = cubeUuid,
		["X"] = cubeUuid,
		["Y"] = cubeUuid,
		["Z"] = cubeUuid
	}

	local centerThickness = 0.35
	local thickness = 0.2
	local length = 1.5

	local transformGizmo = EffectSet.new(transformGizmoUuids)

	transformGizmo:setOffsetTransforms({
		["Base"] = {nil, nil, sm.vec3.one() * centerThickness},
		["X"] = {PosX * length / 2, nil, sm.vec3.new(length, thickness, thickness)},
		["Y"] = {PosY * length / 2, nil, sm.vec3.new(thickness, length, thickness)},
		["Z"] = {PosZ * length / 2, nil, sm.vec3.new(thickness, thickness, length)}
	})

	transformGizmo:setParameter("Base", "color", BPEffects.colours.white)
	transformGizmo:setParameter("X", "color", BPEffects.colours.red)
	transformGizmo:setParameter("Y", "color", BPEffects.colours.green)
	transformGizmo:setParameter("Z", "color", BPEffects.colours.blue)

	transformGizmo:setScale(SubdivideRatio)

    return transformGizmo
end