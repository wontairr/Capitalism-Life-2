AddCSLuaFile()

function CAPItemSpeed(ply,itemName,trace)

    if SERVER then
        ply:SetMaxSpeed(500)
    end

end