AddCSLuaFile()

function CAPItemSWEP(ply,itemName,trace)

    if SERVER then
        if not CAP.HasTag(itemName,"swep") then return end
        local class = CAP.GetSpecialTag(itemName,'@')
        local had = ply:HasWeapon(class)
        ply:Give(class)
        ply:SelectWeapon(class)

        local wep = ply:GetActiveWeapon()
        if not had and IsValid(wep) and wep.Primary and wep.Primary.Ammo and wep.Primary.DefaultClip then
            local ammo = wep.Primary.Ammo
            local clip = wep.Primary.DefaultClip
            ply:GiveAmmo(clip * 3,ammo,false)
        end
    end

end