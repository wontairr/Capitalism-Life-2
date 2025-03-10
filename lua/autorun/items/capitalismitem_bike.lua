AddCSLuaFile()

function CAPItemBike(ply,itemName,trace)

    if SERVER then
        local bike = ents.Create("gtav_sanchez")
        bike:SetPos(trace.HitPos + trace.HitNormal * 1.5)
        bike:Spawn()
        bike:SetOwner(ply)
    end

end