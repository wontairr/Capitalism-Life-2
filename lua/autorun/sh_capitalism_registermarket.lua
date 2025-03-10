local function RegMarketItem(itemName,originalCount)
    CAP.Debug("Registering Market Item: " .. itemName .. " (" .. originalCount .. ")")

    CAP.RegisterMarketItem(itemName,originalCount)
end

hook.Add("CapitalismRegisterMarketItems","CapitalismRegisterMarketItems",function()
    
    //            Name                  --         OriginalCount
    RegMarketItem("Metrocop Helmet"             ,   5)
    RegMarketItem("Pop Can"                     ,   5)
    //RegMarketItem("Jeep"                        ,   3)

    RegMarketItem("Metrofriend"                 ,   25)
    RegMarketItem("Explosive Barrel"            ,   20)
    
    RegMarketItem("Sweet Bike"                  ,   5)
    // weapons
    RegMarketItem("Orbital Strike"              ,   1)
    RegMarketItem("M202"                        ,   4)
    RegMarketItem("Nitro Glycerine"             ,   4)
    RegMarketItem("RPG-7"                       ,   6)
    RegMarketItem("AK-47"                       ,   8)
    RegMarketItem("HK-416"                      ,   6)
    RegMarketItem("F2000"                       ,   6)
    RegMarketItem("Harpoon"                     ,   12)
    RegMarketItem("Snarks"                      ,   8)


    RegMarketItem("Gluon Gun"                   ,   3)
    RegMarketItem("Tau Cannon"                  ,   5)
    RegMarketItem("Satchels"                    ,   22)
    RegMarketItem("Tripmine"                    ,   12)

    RegMarketItem("Chaingun"                    ,   6)
    RegMarketItem("Chainsaw"                    ,   2)
    RegMarketItem("BFG 9000"                    ,   1)
    
    RegMarketItem("Shield Gun"                  ,   6)

    RegMarketItem("Link Gun"                    ,   4)

    RegMarketItem("Super Shotgun"               ,   4)

    RegMarketItem("Proximity Mine",                 10)
end)