local dontDebug = false 
local function StopDebug() dontDebug = true end
local function StartDebug() dontDebug = false end

local function RegItemTag(nameIn,tag)
    CAP.RegisterItemTag(nameIn,tag)
end

local function RegItemRef(nameIn,basePriceIn,modelIn,data)
    CAP.Debug("Registering item: '" .. nameIn .. "'")
    local item = CAP.RegisterItemReference(nameIn,basePriceIn,modelIn,data)
    if not data then return end
    local func = data.func or nil
    if func then item.UseFunction = func end
end
local function RegPhysDrop(nameIn,basePriceIn,modelsIn,data)
    local firstModel = modelsIn[1] -- first model is the icon that represents it in inventory

    local msg = "Registering Pickup Drop: '" .. nameIn .. "' for Model: '" .. firstModel .. "'"
    if #modelsIn > 1 then
        msg = msg .. " with " .. #modelsIn .. " aliases."
    end
    CAP.Debug(msg)
    CAP.RegisterItemReference(nameIn,basePriceIn,firstModel,{tags = "noeco"}) -- noeco tag so economy doesnt apply

    for _, model in ipairs(modelsIn) do
        CAP.RegisterPhysicsPickupDrop(model,nameIn,data)
    end
end

local function RegWeapon(nameIn,basePriceIn, className,tagsIn)
    -- Try to find the weapon entity by its class name
    local weapon = weapons.Get(className)

    if weapon then
        if istable(tagsIn) then
            tagsIn = table.Merge({"useable","dontremove","swep","@" .. className},tagsIn)
        else
            local tags = {"useable","dontremove","swep","@" .. className}
            if tagsIn then
                table.insert(tags,tagsIn)
            end
            tagsIn = tags
        end
        RegItemRef(nameIn,basePriceIn,weapon.WorldModel,{tags = tagsIn,func = CAPItemSWEP})
    end

end

local function RegWeapons()
    //          Name      --          BasePrice     --  Model
    RegItemRef("Metrofriend",       150,    "models/police.mdl",{tags = {"useable"}, func = CAPItemMetroFriend})


    RegItemRef("Orbital Strike",    5000,    "models/weapons/w_binos.mdl",{tags = {"useable"}, func = CAPItemOrbitalStrike})
    RegWeapon("M202",               750,"m9k_m202","medfov")
    RegWeapon("Nitro Glycerine",    450,"m9k_nitro","lowfov")
    RegWeapon("RPG-7",              350,"m9k_rpg7","lowfov")
    RegWeapon("AK-47",              300,"m9k_ak47")
    RegWeapon("HK-416",             250,"m9k_m416")
    RegWeapon("F2000",              250,"m9k_f2000")
    RegWeapon("Harpoon",            50,"m9k_harpoon")

    RegWeapon("Snarks",             50,"weapon_hl1_snark")
    
    RegWeapon("Proximity Mine",     100,"m9k_proxy_mine")

    RegWeapon("Gluon Gun",          750,"weapon_hl1_egon","medfov")
    RegWeapon("Tau Cannon",         550,"weapon_hl1_gauss","lowfov")
    RegWeapon("Tripmine",           200,"weapon_hl1_tripmine","lowfov")
    RegWeapon("Satchels",           75,"weapon_hl1_satchel","lowfov")

    RegWeapon("Chainsaw",           500,"weapon_doom3_chainsaw","medfov")
    RegWeapon("Chaingun",           300,"weapon_doom3_chaingun")
    RegWeapon("BFG 9000",           1000,"weapon_doom3_bfg")

    RegWeapon("Shield Gun",         180,"weapon_ut2004_shieldgun")

    RegWeapon("Link Gun",           300,"weapon_ut2004_linkgun")
    RegWeapon("Super Shotgun",      250,"weapon_doom3_doublebarrel")
end

hook.Add("CapitalismRegisterItems","CapitalismRegisterItemsBase",function()

    //          Name      --          BasePrice     --  Model
    RegItemRef("Example",           50,     "models/props_c17/oildrum001_explosive.mdl")
    RegItemRef("Metrocop Helmet",   25,     "models/nova/w_headgear.mdl")
    RegItemRef("Camera",            25,     "models/maxofs2d/camera.mdl",{func = CAPItemCamera})

    RegItemRef("Jeep",              400,    "models/buggy.mdl",{tags = {"useable","highfov","smallmodel"}, func = CAPItemJeep})

    RegItemRef("Explosive Barrel",  100,    "models/props_c17/oildrum001_explosive.mdl",{tags = {"useable"},func = CAPItemBarrel})
    CAP.RegisterPhysicsPickupDrop("models/props_c17/oildrum001_explosive.mdl","Explosive Barrel")

    RegItemRef("Sweet Bike",        500,    "models/gta5/vehicles/sanchez/chassis.mdl",{tags = {"useable"},func = CAPItemBike})

    RegItemRef("Headcrab Fang",     15,     "models/gibs/antlion_gib_small_1.mdl")
    RegItemRef("Antlion Head",      15,     "models/gibs/antlion_gib_large_2.mdl")

    RegItemRef("Zombie's Headcrab", 5,      "models/headcrabclassic.mdl")

    RegItemRef("Combine Kevlar",    25,     "models/gibs/helicopter_brokenpiece_03.mdl")

    RegWeapons()

    // PhysDrops

    RegPhysDrop("Ration",           15,     { "models/weapons/w_package.mdl" })
    RegPhysDrop("Pop Can",          2,      { "models/props_junk/popcan01a.mdl" })
    RegPhysDrop("Melon",            10,     { "models/props_junk/watermelon01.mdl" })

    RegPhysDrop("Beer Bottle",      3,      { 
        "models/props_junk/garbage_glassbottle003a.mdl",
        "models/props_junk/garbage_glassbottle001a.mdl",
        "models/props_junk/garbage_glassbottle002a.mdl",
        "models/props_junk/glassbottle01a.mdl"
    })

    RegPhysDrop("Whiskey Bottle",   15,     { "models/props_junk/glassjug01.mdl" })



    RegPhysDrop("Plastic Bottle",   1,      {
        "models/props_junk/garbage_plasticbottle001a.mdl",
        "models/props_junk/garbage_plasticbottle002a.mdl",
        "models/props_junk/garbage_plasticbottle003a.mdl",
        "models/props_junk/garbage_milkcarton001a.mdl"
    })

    RegPhysDrop("Newspaper",        1,      { "models/props_junk/garbage_newspaper001a.mdl" })
    RegPhysDrop("Traffic Cone",     5,      { "models/props_junk/trafficcone001a.mdl" })
    RegPhysDrop("Metal Bucket",     2,      { "models/props_junk/metalbucket01a.mdl" })
    RegPhysDrop("Doll",             15,     { "models/props_c17/doll01.mdl" })
    RegPhysDrop("Plant Pot",        5,      { "models/props_junk/terracotta01.mdl" })
    RegPhysDrop("Left Shoe",        2,      { "models/props_junk/shoe001a.mdl" })
    RegPhysDrop("Skull",            5,      { "models/gibs/hgibs.mdl" })
    RegPhysDrop("Spine",            5,      { "models/gibs/hgibs_spine.mdl" })
    RegPhysDrop("Rib",              1,      { "models/gibs/hgibs_rib.mdl" })
    RegPhysDrop("Scapula",          1,      { "models/gibs/hgibs_scapula.mdl" })

    RegPhysDrop("Luggage",        2,      {
        "models/props_c17/suitcase001a.mdl",
        "models/props_c17/suitcase_passenger_physics.mdl",
    })

    RegPhysDrop("Trash",            1,      {
        "models/props_junk/garbage_takeoutcarton001a.mdl",
        "models/props_junk/garbage_bag001a.mdl",
        "models/props_junk/garbage_carboard002a.mdl",
        "models/props_junk/garbage_coffeemug001a.mdl",
        "models/props_junk/garbage_metalcan001a.mdl",
        "models/props_junk/garbage_metalcan002a.mdl",
        "models/props_junk/garbage_milkcarton002a.mdl",
        "models/props_lab/box01a.mdl",
        "models/props_junk/cardboard_box004a.mdl",
    })

    RegPhysDrop("Paint Can",        5,      {
        "models/props_junk/metal_paintcan001a.mdl",
        "models/props_junk/metal_paintcan001b.mdl",
        "models/props_junk/plasticbucket001a.mdl",
    })

    RegPhysDrop("HEV Charger",      100,    { "models/props_lab/hevplate.mdl" })

end)