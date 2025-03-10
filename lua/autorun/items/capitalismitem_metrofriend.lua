AddCSLuaFile()

function CAPItemMetroFriend(ply,itemName,trace)

    if SERVER then
        local copFriend = ents.Create("npc_metropolice")
        if not IsValid(copFriend) then return end
    
        copFriend:SetPos(trace.HitPos)
        copFriend:Spawn()
    
        -- Generate a unique targetname
        local uniqueName = "copfriend_" .. copFriend:EntIndex()
        copFriend:SetKeyValue("targetname", uniqueName)
    
        -- Set relationships
        copFriend:AddRelationship("!player D_LI 99")  -- Friendly to player
        copFriend:AddRelationship("npc_metropolice D_HT 99")  -- Hates metrocops
        copFriend:AddRelationship("npc_combine_s D_HT 99")  -- Hates combine
        copFriend:AddRelationship(uniqueName .." D_LI 99")  -- LIKES SELF
    
        -- Make enemies specifically target the unique copFriend
        for _, enemyClass in ipairs({"npc_metropolice", "npc_combine_s"}) do
            for _, enemy in ipairs(ents.FindByClass(enemyClass)) do
                if IsValid(enemy) then
                    enemy:AddRelationship(uniqueName .. " D_HT 99")
                end
            end
        end
    
        -- Set color and weapon
        copFriend:SetColor(Color(0, 255, 0, 255))
        copFriend:Give("weapon_pistol")
        copFriend:SelectWeapon("weapon_pistol")
    end
    
end