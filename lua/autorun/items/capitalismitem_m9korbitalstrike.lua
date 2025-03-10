AddCSLuaFile()

function CAPItemOrbitalStrike(ply,itemName,trace)

    if SERVER then
        local camera = ents.Create("m9k_orbital_strike")
        camera:SetPos(trace.HitPos)
        camera:Spawn()
    end

end