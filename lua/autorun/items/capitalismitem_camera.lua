AddCSLuaFile()

function CAPItemCamera(ply,itemName,trace)

    if SERVER then
        local camera = ents.Create("gmod_camera")
        camera:SetPos(trace.HitPos)
        camera:Spawn()
    end

end