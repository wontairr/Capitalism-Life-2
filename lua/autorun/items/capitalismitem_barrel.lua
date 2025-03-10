AddCSLuaFile()

function CAPItemBarrel(ply,itemName,trace)

    if SERVER then
        local barrel = ents.Create("prop_physics")
        barrel:SetPos(trace.HitPos + trace.HitNormal * 1.5)
        barrel:SetModel("models/props_c17/oildrum001_explosive.mdl")
        barrel:Spawn()
        barrel:SetOwner(ply)
    end

end