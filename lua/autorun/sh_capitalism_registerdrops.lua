local function RegNPCDrop(npcClass,itemName,data)
    CAP.Debug("Registering NPC Drop: '" .. itemName .. "' for NPC: '" .. npcClass .. "'")

    CAP.RegisterNPCItemDrop(npcClass,itemName,data)
end

local function isPlainCitizen( ent )
    local modelLower = string.lower( ent:GetModel() )
    if string.find( modelLower, "group01" ) or string.find( modelLower, "group02" ) then return true end

end

hook.Add("CapitalismRegisterDrops","CapitalismRegisterDropsBase",function()

    //          NPC Class      --   Item Name                   -- data
    RegNPCDrop("npc_metropolice",   "Metrocop Helmet",          { chance = 0.5,   count = 1 })
    RegNPCDrop("npc_cscanner",      "Camera",                   { chance = 0.75,  count = 1 })
    RegNPCDrop("npc_combine_camera","Camera",                   { chance = 0.8,     count = 2 })
    RegNPCDrop("npc_citizen",       "Ration",                   { checkFunc = isPlainCitizen, chance = 0.45,  count = 1 })
    RegNPCDrop("npc_headcrab",      "Headcrab Fang",            { chance = 0.5,   count = 1})
    RegNPCDrop("npc_antlion",       "Antlion Head",            { chance = 0.5,   count = 1})
    RegNPCDrop("npc_zombie",        "Zombie's Headcrab",       { chance = 0.2,   count = 1})
    RegNPCDrop("npc_combine_s",     "Combine Kevlar",           { chance = 0.3,     count = 1})
end)

