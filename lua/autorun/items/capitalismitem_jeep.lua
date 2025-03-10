AddCSLuaFile()

function CAPItemJeep(ply,itemName,trace)

    if SERVER then
        local jeep = ents.Create("prop_vehicle_jeep")
        jeep:SetModel("models/buggy.mdl")
        jeep:Spawn()
        local min,max = jeep:GetCollisionBounds()
        local size = (min - max):Length()
        jeep:SetPos(trace.HitPos + trace.HitNormal * size)
        jeep:Fire("enablegun","1",0,nil,nil)
    end

end