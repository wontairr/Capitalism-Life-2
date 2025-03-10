
if CLIENT then
    function CAPServerDebug(code)
        net.Start("toServer_CAPDebug")
            net.WriteString(code)
        net.SendToServer()
    end
end

sv_capitalism_economy_multiplier = CreateConVar("sv_capitalism_economy_multiplier","1.5",{FCVAR_ARCHIVE,FCVAR_REPLICATED},"Price change multiplier",0.01,10.0)
sv_capitalism_economy_timerlength = CreateConVar("sv_capitalism_economy_timerlength","60",{FCVAR_ARCHIVE,FCVAR_REPLICATED},"Time between economy updates",1,1000)



// Globals VVV

local settings = {
    serverTime = 0,
}



-- Combines last servertime with now servertime. 
local function GetWholeSysTime()
    return (CAP.lastSave != {} and settings.serverTime + RealTime() or RealTime())
end

if not _G.CAP then
    CAP = {}
    CAP.lastSave = {}
    CAP.ITEM_REFERENCES = {}
    CAP.MARKET_ITEMS = {}

    CAP.NPC_ITEM_DROPS = {}
    CAP.PHYSICS_PICKUP_DROPS = {}

    CAP.ECONOMY_ITEMS = {}
    
    -- there are too many of these tables by this point but i think this is the last
    CAP.ITEM_TAGS = {}



end


CAP.LoadPlayerData = function(ply)
    if CAP.lastSave == {} then return end
    if not IsValid(ply) then return end

    local plyData = CAP.lastSave.plyData

    local data = plyData[tostring(ply:SteamID64())]

    if data == nil then CAP.Debug("Tried to load player data for ply: " .. ply:Name() .. " but it wasnt there!") return end
    ply:SetCash(data.cash)
    local db = 0
    for itemName,itemCount in pairs(data.items) do
        db = db + 1
        ply:AddItem(itemName,itemCount)
    end
    CAP.Debug("Loaded " ..  db .. " items for ply " .. ply:Name())

end

CAP.Save = function(saveName)
    if CLIENT then return end
    local savePath = "capitalism/" .. saveName .. ".txt"
    if not file.IsDir("capitalism","DATA") then file.CreateDir("capitalism") end
    CAP.Debug("Saving to file: " .. savePath)

    local saveFile = {
        settings = {serverTime = GetWholeSysTime()},
        marketItems = {},
        economyItems = CAP.ECONOMY_ITEMS,
        plyData = {

        }
    }
    for _, ply in ipairs(player.GetAll()) do
        local steamID = tostring(ply:SteamID64())
        saveFile.plyData[steamID] = {
            cash = ply:GetCash(),
            items = {}
        }
        for itemName, value in pairs(ply.CInventory) do
            saveFile.plyData[steamID].items[itemName] = value[2] -- count
        end
    end
    for itemName, data in pairs(CAP.MARKET_ITEMS) do
        saveFile.marketItems[itemName] = data[2]
    end
    local json = util.TableToJSON(saveFile,true)
    file.Write(savePath,json)

end
CAP.SaveExists = function(saveName)
    local savePath = "capitalism/" .. saveName .. ".txt"
    if not file.Exists(savePath,"DATA") then return false else return true end
    return false
end    
CAP.Load = function(saveName,manual)
    if CLIENT then return end
    local savePath = "capitalism/" .. saveName .. ".txt"
    if not file.Exists(savePath,"DATA") then CAP.Debug("ERROR: SAVEFILE AT '" .. savePath .. "' DOES NOT EXIST!") return end
    CAP.Debug("Loading save file: " .. savePath)
    local save = file.Read(savePath,"DATA")
    if save == nil then CAP.Debug("ERROR: TRIED TO OPEN SAVEFILE '" .. savePath .. "' BUT IT WAS NIL!") return end
    CAP.lastSave = util.JSONToTable(save,false,true)

    settings = CAP.lastSave.settings

    CAP.ECONOMY_ITEMS = CAP.lastSave.economyItems

    -- load market
    for itemName,count in pairs(CAP.lastSave.marketItems) do
        CAP.MARKET_ITEMS[itemName] = {
            CAP.GetItemRef(itemName),
            count
        }
    end

    -- Player loading happens after players load (odd but yea)
    if not manual then return end

    local plyData = CAP.lastSave.plyData

    for _, ply in ipairs(player.GetAll()) do
        CAP.LoadPlayerData(ply)
    end
    
end

if CLIENT then
    CAP.PreviousItemPrices = {}
    CAP.IsPriceLowerNow = function(itemName)
        local tbl = CAP.PreviousItemPrices[itemName]
        if tbl != nil and #tbl > 1 then
            if tbl[#tbl - 1] == CAP.GetCurrentPrice(itemName) then return 0 end
            return tbl[#tbl - 1] > CAP.GetCurrentPrice(itemName)
        end
        return 0 -- hasnt changed
    end
end


CAP.Palette = {
    GREENLIGHT      = Color(0,210,0),
    GREENMODULATE   = Color(0,210,0),
    GREENDARK       = Color(0,102,0),
    GREENGLASS      = Color(0,175,0,100),
    GREENGLASSDARK  = Color(0,102,0,100),
    RED             = Color(200,70,0,255),

    
    PaintBoxOutlinedModulate = function(self,w,h)
        surface.SetDrawColor(color_black)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(CAP.Palette.GREENMODULATE)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end,
    PaintBoxOutlinedGlass = function(self,w,h)
        surface.SetDrawColor(CAP.Palette.GREENGLASSDARK)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(CAP.Palette.GREENDARK)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end,
    PaintBoxOutlinedGlassBlur = function(self,w,h)
        if not self.startTime then self.startTime = SysTime() end
        //Derma_DrawBackgroundBlur(self, self.startTime)
        surface.SetDrawColor(CAP.Palette.GREENGLASSDARK)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(CAP.Palette.GREENDARK)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end,
    PaintBoxOutlinedLight = function(self,w,h)
        surface.SetDrawColor(color_black)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(CAP.Palette.GREENLIGHT)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end,
    PaintBoxOutlinedDark = function(self,w,h)
        surface.SetDrawColor(color_black)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(CAP.Palette.GREENDARK)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end,


    PaintButton = function(self,w,h)
        local buttonOver = CAP.Palette.GREENMODULATE
        local buttonOff = CAP.Palette.GREENDARK
        surface.SetDrawColor(self:IsHovered() and buttonOver or buttonOff)
 

        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(self:IsHovered() and buttonOff or buttonOver)
        surface.DrawOutlinedRect(0,0,w,h,(self:IsHovered() and Lerp(math.abs(math.sin(CurTime() * 2)),1,10) or 3))
        draw.SimpleText(self.Text,"CAPBigFont",w/2,h/2,color_black,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
}



CAP.ClientRefresh = function()
    if CLIENT then return end
    net.Start("toClient_CAPRefreshLaptop")
    net.Broadcast()
end

local dev = GetConVar("developer")

local blue = Color(92,139,233)
local yellorange = Color(229,197,100)

CAP.Debug = function (...)
    if (CLIENT and dev:GetInt() == 0) then return end
    local args = {...}
    local output = "*CAPITALISM DEBUG* >>> "
    local sendOutput = ""
    local color = yellorange 
    for _, v in ipairs(args) do
        if _ == 1 and v == "$sv" then
            color = blue
            continue
        end
        output = output .. " " .. tostring(v)
        sendOutput = sendOutput .. " " .. tostring(v)
    end
    if color != blue then
        output = output .. "\n"
    end
    sendOutput = sendOutput .. "\n"

    -- Print the final formatted string
    MsgC(color,output)
    //print(output)
    if SERVER then
        net.Start("toClient_CAPSyncDebug",true)
            net.WriteString(sendOutput)
        net.Broadcast()
    end
end
if CLIENT then
    net.Receive("toClient_CAPSyncDebug",function() CAP.Debug("$sv", net.ReadString()) end)
end


CAP.GetItemRef = function(itemName)
    local realName = string.DirtyName(itemName)
    if not CAP.ITEM_REFERENCES[realName] then return nil end
    return CAP.ITEM_REFERENCES[realName]
end
CAP.GetItemName = function(itemName)
    local item = CAP.GetItemRef(itemName)
    if item != nil then return item.name end
    return "NULL NAME (INVALID ITEM)"
end

CAP.IsValidItem = function(itemName)  return CAP.ITEM_REFERENCES[string.DirtyName(itemName)] != nil end
CAP.IsValidDrop = function(className) return CAP.NPC_ITEM_DROPS[className] != nil end

-- Returns a npc specific drop if you're lucky.
CAP.GetNPCDrop = function(className)
    if not CAP.NPC_ITEM_DROPS[className] then CAP.Debug("NO ITEM NPC DROPS FOR " .. className) return nil,nil end
    local dropTable = CAP.NPC_ITEM_DROPS[className]
    local random = math.random()
    for i, drop in ipairs(dropTable) do
        local chance = drop.chance or 1
        local count = drop.count or 1

        if random >= chance then continue end
        return drop.identifier,count,drop.data

    end
    return nil,nil
end

-- Returns a model specific drop, for when an entity is picked up
CAP.GetPhysicsPickupDrop = function(modelName)
    if not CAP.PHYSICS_PICKUP_DROPS[modelName] then CAP.Debug("NO ITEM PICKUP DROPS FOR " .. modelName) return nil,nil end
    local dropTable = CAP.PHYSICS_PICKUP_DROPS[modelName]
    for i, drop in ipairs(dropTable) do
        return drop.identifier,drop.count,drop.data
    end
    return nil,nil
end



CAP.RegisterItemTag = function(nameIn,tag)
    
    nameIn = string.DirtyName(nameIn)
    if not CAP.ITEM_TAGS[nameIn] then CAP.ITEM_TAGS[nameIn] = {} end
    if istable(tag) then
        for _, t in ipairs(tag) do
      
            -- T IS INDIVIDUAL TAG
            CAP.ITEM_TAGS[nameIn][t] = true

        end
    else

        CAP.ITEM_TAGS[nameIn][tag] = true
    end
end


CAP.RegisterItemReference = function(nameIn,basePriceIn,modelIn,data)
    if not data then data = {} end

    local item = {
        name        = nameIn,
        basePrice   = basePriceIn,
        model       = modelIn,
    }
    nameIn = string.DirtyName(nameIn)


    CAP.ITEM_REFERENCES[nameIn] = item
    local tags = data.tags
    if tags then
        CAP.RegisterItemTag(nameIn,tags)
    end
    //if CAP.ITEM_TAGS[nameIn]["noeco"] then return CAP.ITEM_REFERENCES[nameIn] end
    -- register the item in the economy table
    if SERVER then        
        CAP.ECONOMY_ITEMS[nameIn] = {
            basePriceIn, -- this is the price that will change
            basePriceIn, -- this is the base price, very redundant but faster
            -1 -- Point in time when it last dropped. GetWholeSysTime()
        }
    elseif CLIENT then
        CAP.ECONOMY_ITEMS[nameIn] = basePriceIn
    end
    return CAP.ITEM_REFERENCES[nameIn]
end

CAP.RegisterNPCItemDrop = function(npcClass,itemName,data)
    local count = data.count or 1
    local chance = data.chance or 1
    local drop = {
        identifier = string.DirtyName(itemName),
        chance = math.Clamp(chance,0,1),
        count = count
    }
    if not CAP.NPC_ITEM_DROPS[npcClass] then CAP.NPC_ITEM_DROPS[npcClass] = {} end

    table.insert(CAP.NPC_ITEM_DROPS[npcClass],drop)
end

CAP.RegisterPhysicsPickupDrop = function(model,itemName,data)
    data = data or {}
    local count = data.count or 1
    local drop = {
        identifier = string.DirtyName(itemName),
        count = count,
        data = data,
    }
    if not CAP.PHYSICS_PICKUP_DROPS[model] then CAP.PHYSICS_PICKUP_DROPS[model] = {} end

    table.insert(CAP.PHYSICS_PICKUP_DROPS[model],drop)
end

CAP.RegisterPhysicsPickupDropAlias = function(model,itemName)
    data = data or {}
    local count = data.count or 1
    local drop = {
        identifier = string.DirtyName(itemName),
        count = count,
        data = data,
    }
    if not CAP.PHYSICS_PICKUP_DROPS[model] then CAP.PHYSICS_PICKUP_DROPS[model] = {} end

    table.insert(CAP.PHYSICS_PICKUP_DROPS[model],drop)
end

-- Must happen AFTER item registration
CAP.RegisterMarketItem = function(itemName,originalCount)
    local item = CAP.GetItemRef(itemName)
    if item == nil then CAP.Debug("ERROR: TRIED TO REGISTER INVALID MARKET ITEM: " .. itemName) return end

    local marketItem = {
        item,
        originalCount
    }

    CAP.MARKET_ITEMS[string.DirtyName(itemName)] = marketItem
end

CAP.UpdateMarketItem = function(itemName,newCount)
    local fixedName = string.DirtyName(itemName)
    if not CAP.MARKET_ITEMS[fixedName] then
        CAP.Debug("ERROR: TRIED TO UPDATE INVALID MARKET ITEM: '" .. itemName .. "'")
        if not CAP.IsValidItem(fixedName) then return end
        CAP.Debug("^ ITEM NAME IS VALID ANYWAYS SO CREATING MANUALLY.")
        CAP.RegisterMarketItem(fixedName,newCount)
    end
    CAP.MARKET_ITEMS[fixedName][2] = newCount
    if newCount <= 0 then CAP.MARKET_ITEMS[fixedName] = nil end
    
    if CLIENT then return end
    CAP.Debug("Changing count for '" .. fixedName .. "' to: " .. newCount)
    net.Start("toClient_CAPChangeMarketItemCount")
        net.WriteString(fixedName)
        net.WriteUInt(newCount,16)
    net.Broadcast()
    
end

CAP.GetMarketItemCount = function(itemName)
    itemName = string.DirtyName(itemName)
    if CAP.MARKET_ITEMS[itemName] then return CAP.MARKET_ITEMS[itemName][2] end
    return 0
end

local function CAPPriceCalculator(basePrice,timeInterval,stock)
    local stockWasZero = stock == 0
    stock = math.Clamp(stock,1,99999)
    local mult = sv_capitalism_economy_multiplier:GetFloat() * (timeInterval / (stock / 2))
    
    if stockWasZero then mult = math.Clamp(mult,0.1,2.5) else mult = math.Clamp(mult,0.01,300) end
    basePrice = math.Clamp(math.Round(basePrice * mult),1,99999)
    return basePrice
end

CAP.UpdateEconomy = function(loadingASave)
    if CLIENT then return end
    if loadingASave == nil then loadingASave = false end
    CAP.Debug("Updating Economy...")
    local time = sv_capitalism_economy_timerlength:GetInt()
    local curSysTime = GetWholeSysTime()
    local sendTable = {}
    for name, ecoItem in pairs(CAP.ECONOMY_ITEMS) do
        local marketCount = CAP.GetMarketItemCount(name)
         -- dont do economy on props and stuff that would be diabolical (and also if the item hasnt been dropped)
        if CAP.HasTag(name,"noeco") or ecoItem[3] == -1 or loadingASave then
            sendTable[name] = ecoItem[1]
            continue
        end
        -- 1 is current price, 2 is baseprice, 3 is last drop point.
        local newPrice = CAPPriceCalculator(
            ecoItem[2],                         -- Base price
            (curSysTime - ecoItem[3]) / time,   -- Time interval between last drop point and now (in minutes)
            marketCount                         -- Stock
        )
        CAP.Debug("Last time: " .. (curSysTime - ecoItem[3]) / time)
        CAP.Debug(name ..  "| Before: " .. ecoItem[1] .. ", After: " .. newPrice)
        ecoItem[1] = newPrice
        sendTable[name] = newPrice
    end

    
    if loadingASave then return sendTable end
    net.Start("toClient_CAPUpdateEconomy")
        net.WriteCompressedTable(sendTable)
    net.Broadcast()
    CAP.ClientRefresh()
end
if CLIENT then
    net.Receive("toClient_CAPUpdateEconomy",function(len)
        CAP.Debug("Recieved Economy Update! Check out the data size: " .. tostring(len))
        local newTable = net.ReadCompressedTable()


        
        CAP.ECONOMY_ITEMS = newTable
        for item, price in pairs(CAP.ECONOMY_ITEMS) do
            if not CAP.PreviousItemPrices[item] then CAP.PreviousItemPrices[item] = {} end
            //if price == newTable[item] then continue end
            table.insert(CAP.PreviousItemPrices[item],price)
            if #CAP.PreviousItemPrices[item] > 5 then
                table.remove(CAP.PreviousItemPrices[item],1)
            end
        end
    end)
end

CAP.EcoSetLastDrop = function(itemName)
    if not CAP.ECONOMY_ITEMS[itemName] then CAP.Debug("Tried to set the last drop point of invalid item '" .. itemName .. "'") return end
    CAP.ECONOMY_ITEMS[itemName][3] = GetWholeSysTime()
end

CAP.CreateEconomyTimer = function()
    CAP.Debug("Started Economy Timer!")
    timer.Create("CAP_EconomyUpdateTimer",sv_capitalism_economy_timerlength:GetInt(),0,function()
        CAP.UpdateEconomy()
    end)
end

CAP.HasTag = function(itemName,tagName)
    return (CAP.ITEM_TAGS[itemName] != nil and CAP.ITEM_TAGS[itemName][tagName] != nil)
end
CAP.GetSpecialTag = function(itemName,char)
    if not CAP.ITEM_TAGS[itemName] then return end
    for key, value in pairs(CAP.ITEM_TAGS[itemName]) do
        if string.find(key,char) then return string.Replace(key,char,"") end
    end
    return ""
end


-- Gets the current price based off the economy
CAP.GetCurrentPrice = function(itemName)
    itemName = string.DirtyName(itemName)
    if CAP.ECONOMY_ITEMS[itemName] != nil then
        if SERVER then
            return CAP.ECONOMY_ITEMS[itemName][1]
        else
            return CAP.ECONOMY_ITEMS[itemName]
        end
    else
        if CAP.ITEM_REFERENCES[itemName] != nil then
            return CAP.ITEM_REFERENCES[itemName].basePrice
        end
    end
    return 0
end
CAP.GetBasePrice = function(itemName)
    local itemRef = CAP.GetItemRef(itemName)
    return itemRef.basePrice 
end

if CLIENT then

    net.Receive("toClient_CAPChangeMarketItemCount",function()
        local item = net.ReadString()
        local count = net.ReadUInt(16)
        CAP.UpdateMarketItem(item,count)
    end)
end


// Globals ^^^

local PLAYER = FindMetaTable("Player")

if SERVER then
    CAP.JoinedPlayers = {}
end

gameevent.Listen( "player_activate" )
hook.Add("player_activate","CAP_PlayerInitialSpawn",function(data)
    local id = data.userid

    local ply = Player(id)
    if not IsValid(ply) then return end

   
    ply.CInventory = {}
    ply:SetNWInt("CCash",0)
    if CLIENT then return end
    net.Start("toClient_CAPPlayerInitSpawn")
        net.WriteUInt(id,8)
    net.Broadcast()
    local saveExists = CAP.SaveExists("manualsave")

    if CAP.finishedLoadingSave == true then
        CAP.Debug("Allowing ply " .. ply:Name() .. " to register.")
        net.Start("toClient_CAPAllowPlayerRegister")
            net.WriteBool(saveExists)
        net.Send(ply)
        return
    end
    table.insert(CAP.JoinedPlayers,ply)


end)

if CLIENT then
    CAP.registerInstructions = {
        canRegister = false,
        dontRegMarket = false,
    }

    net.Receive("toClient_CAPAllowPlayerRegister",function()
        local dontDoMarket = net.ReadBool()
        CAP.registerInstructions.canRegister = true
        CAP.registerInstructions.dontRegMarket = dontDoMarket

    end)
    net.Receive("toClient_CAPRecieveSaveTables",function()
        local marketTable = net.ReadCompressedTable()
        local economy = net.ReadCompressedTable()
        for itemName,count in pairs(marketTable) do
            CAP.MARKET_ITEMS[itemName] = {
                CAP.GetItemRef(itemName),
                count
            }
        end
        CAP.ECONOMY_ITEMS = economy
        CAP.Debug("Recieved save tables economy and market!")
        
    end)
end

hook.Add("ShutDown","CAP_PreShutDown",function()
    if CLIENT then return end
    CAP.Save("manualsave")
end)
hook.Add("PlayerDisconnected","CAP_PlayerDisconnect",function(ply)
    CAP.Save("manualsave")
end)

hook.Add("InitPostEntity","CAP_PlayerInitPostEntity",function()
    
    -- REGISTER EVERYTHANG
    timer.Simple(1.0420,function()
        -- These things dont change
        hook.Run("CapitalismRegisterItems")
        hook.Run("CapitalismRegisterDrops")

        if SERVER then
            CAP.Load("manualsave")

            

            local saveExists = CAP.SaveExists("manualsave")
            CAP.Debug("INITPOSTENTITY: SAVE EXISTS == " .. tostring(saveExists))
            if not saveExists then
                hook.Run("CapitalismRegisterMarketItems")
            end
            CAP.finishedLoadingSave = true 

            CAP.Debug("Finished loading save, allowing joined players to register")
            
            net.Start("toClient_CAPAllowPlayerRegister")
                net.WriteBool(saveExists)
            net.Send(CAP.JoinedPlayers)


            CAP.CreateEconomyTimer()
        else

            timer.Create("CAPClientRegCheck",0.1,0,function()
                if CAP.registerInstructions.canRegister then
                    if not CAP.registerInstructions.dontRegMarket and not LocalPlayer().capsent then
                        if LocalPlayer().capsent then return end
                        LocalPlayer().capsent = true
                        hook.Run("CapitalismRegisterMarketItems")
                    else
                        if LocalPlayer().capsent then return end
                        LocalPlayer().capsent = true
                        net.Start("toServer_CAPPlayerCanRecieveSaveTables")
                        net.SendToServer()
                        timer.Remove("CAPClientRegCheck")
                    end
                end
            end)
        end
    end)

    

    -- HACK: During PlayerInitialSpawn, Client Players are NULL or something, that is until this hook.
    if CLIENT then
        for _, plyId in ipairs(CAP.playerSpawnQueue) do
            local ply = Player(plyId)
            if not IsValid(ply) then continue end
            -- BROADCAST
            ply.CInventory = {}
            ply:SetNWInt("CCash",0)
    
            if ply != LocalPlayer() then continue end
            -- LOCALPLAYER
            
        end
    end
    
end)

if CLIENT then
    CAP.playerSpawnQueue = {}

    net.Receive("toClient_CAPPlayerInitSpawn",function()
        local plyId = net.ReadUInt(8)
        
        table.insert(CAP.playerSpawnQueue,plyId)
    end)

    hook.Add( "OnPlayerChat", "CAPDebugCommands", function( ply, strText, bTeam, bDead ) 
  
 
        strText = string.lower( strText ) -- make the string lower case
    
        if ( strText == "!cregister" ) then 
            CAPServerDebug("registerall")
            
            hook.Run("CapitalismRegisterItems")
            hook.Run("CapitalismRegisterDrops")
            hook.Run("CapitalismRegisterMarketItems")
            
            return true -- this suppresses the message from being shown
        elseif (strText == "!crestarteco") then
            CAPServerDebug("createecotimer")
        elseif (strText == "!caddmoney") then
            CAPServerDebug("addmoney")
        elseif (strText == "!csave") then
            CAPServerDebug("manualsave")
        elseif (strText == "!cload") then
            CAPServerDebug("manualload")
        elseif (strText == "!voteskip") then
            net.Start("toServer_submitSkipAhead")
            net.SendToServer()
        end
    end )
end


hook.Add("OnNPCKilled","CAP_OnNPCKilled",function(npc,attacker,inflictor)
    if not attacker:IsPlayer() then return end

    local class = npc:GetClass()
    local drop,count,data = CAP.GetNPCDrop(class)
    -- little amount for getting the enemy
    attacker:ModCash(true,math.Round(npc:GetMaxHealth()/11))
    if drop == nil then return end
    CAP.EcoSetLastDrop(drop)

    local name = CAP.GetItemName(drop)
    attacker:AddItem(drop,count)
    attacker:ChatPrint("Got " .. count .. " " .. name)
end)

local PICKUP_KEY = IN_WALK

hook.Add("OnPlayerPhysicsPickup","CAP_HandlePhysicsPickupDrops",function(ply,pickedUp)
    local isHoldingPickup = ply:KeyDown( PICKUP_KEY )
    if not isHoldingPickup then return end

    local mdl = pickedUp:GetModel()
    local drop,count,data = CAP.GetPhysicsPickupDrop(mdl)

    if drop == nil then return end

    local itemsInsideProp = pickedUp.CAP_itemsInsideProp or data.itemsInsideProp or 1
    local deletes = true
    if data.deletes != nil then
        deletes = data.deletes
    end

    if itemsInsideProp <= 0 and deletes then
        ply:DropObject() -- viewmodel bug, happened once
        SafeRemoveEntityDelayed( pickedUp, 0 )
        return
    end

    ply:AddItem(drop,count)
    local name = CAP.GetItemName(drop)
    ply:ChatPrint("Got " .. count .. " " .. name)

    itemsInsideProp = itemsInsideProp + -1
    pickedUp.CAP_itemsInsideProp = itemsInsideProp

    if itemsInsideProp <= 0 and deletes then
        ply:DropObject() -- viewmodel bug, happened once
        SafeRemoveEntityDelayed( pickedUp, 0 )
    end
end)
--[[
    concommand.Add("capitalism_debug_setupinventory",function(ply)
    ply.CInventory = {}
    ply:AddItem("Example",1)
end)
]]
if SERVER then
    concommand.Add("capitalism_debug_addmoney",function(ply)

        ply:SetCash(60)
        ply:SendLua("LocalPlayer().CInventory = {}")
        ply.CInventory = {}

    end)
    concommand.Add("capitalism_debug_clearinv",function(ply)
        ply:SendLua("LocalPlayer().CInventory = {}")
        ply.CInventory = {}

    end)
    concommand.Add("capitalism_debug_additem",function(ply,cmd,args)
        local item = args[1]
        local count = args[2] or 1
        if not CAP.IsValidItem(item) then return end
        ply:AddItem(item,count)
    end)
end



function PLAYER:AddItemMultiple(itemsAndCounts)
    for itemName,count in pairs(itemsAndCounts) do
        self:AddItem(itemName,count)
    end
end

function PLAYER:AddItem(item,countIn)
    if not self.CInventory then self.CInventory = {} end
    if not countIn then countIn = 1 end
    local fixedName = string.DirtyName(item)
    
    -- Adds a table with a reference to the item data to the players inventory
    if not self.CInventory[fixedName] then
        self.CInventory[fixedName] = {CAP.ITEM_REFERENCES[fixedName],countIn}
    else
        local preCount = self.CInventory[fixedName][2]
        self.CInventory[fixedName][2] = preCount + countIn
    end    

    if SERVER then
        net.Start("toClient_CAPAddItem")
            net.WriteString(item)
            net.WriteUInt(countIn,8)
        net.Send(self)
    else
        CAPClientGetItemEffect(CAP.ITEM_REFERENCES[fixedName])
    end

end

function PLAYER:ModifyItem(itemName,newCount,subtract)
    itemName = string.DirtyName(itemName)
    if self.CInventory[itemName] then
        if subtract then
            self.CInventory[itemName][2] = self.CInventory[itemName][2] - newCount
        else
            self.CInventory[itemName][2] = newCount
        end
        -- Remove when no mo'
        if self.CInventory[itemName][2] <= 0 then self.CInventory[itemName] = nil end
    end
    if SERVER then
        CAP.ClientRefresh()
        net.Start("toClient_CAPModifyItem")
            net.WriteString(itemName)
            net.WriteUInt(newCount,8)
            net.WriteBool(subtract)
        net.Send(self)
    end

end
function PLAYER:GetItemCount(itemName)
    itemName = string.DirtyName(itemName)
    if self.CInventory[itemName] then
        return self.CInventory[itemName][2]
    else
        return 0
    end
end

function PLAYER:GetCash()
    return self:GetNWInt("CCash",0)
end
function PLAYER:SetCash(new)
    if CLIENT then return end
    self:SetNWInt("CCash",new)
end
function PLAYER:ModCash(add,amount)
    if CLIENT then return end
    local cash = self:GetCash()
    local final = (add and cash + amount or cash - amount)
    self:SetNWInt("CCash",math.Clamp(final,0,9999999))
end

if CLIENT then
    -- Only is sent to the player its gonna be added to.
    net.Receive("toClient_CAPAddItem",function()
        local item = net.ReadString()
        local count = net.ReadUInt(8)
        LocalPlayer():AddItem(item,count)
    end)

    net.Receive("toClient_CAPModifyItem",function()
        local item = net.ReadString()
        local count = net.ReadUInt(8)
        local subtract = net.ReadBool()
        LocalPlayer():ModifyItem(item,count,subtract)
    end)
    
end

if SERVER then

    net.Receive("toServer_CAPBuyRequest",function()
        local ply      = net.ReadPlayer()
        local marketId = net.ReadString() -- Item name
        if not IsValid(ply) then return end
        local marketItem = CAP.MARKET_ITEMS[marketId]
        local price = CAP.GetCurrentPrice(marketId)
        if ply:GetCash() < price then return end
        ply:ModCash(false,price)
        ply:AddItem(marketId,1)


        marketItem[2] = marketItem[2] - 1
        CAP.UpdateMarketItem(marketId,marketItem[2])
        

        CAP.ClientRefresh()
    end)

    net.Receive("toServer_CAPSellRequest",function()

        local ply       = net.ReadPlayer()
        local item      = net.ReadString()

        if not IsValid(ply) or ply:GetItemCount(item) <= 0 then return end
        
        CAP.UpdateMarketItem(item, CAP.GetMarketItemCount(item) + 1)
        if CAP.HasTag(item,"swep") then
            local class = CAP.GetSpecialTag(item,'@')
            ply:StripWeapon(class)
        end
        -- Uses client refresh internally
        ply:ModifyItem(item,1,true)
        --give cash
        ply:ModCash(true,CAP.GetCurrentPrice(item))
        CAP.ClientRefresh()
    end)
    function CAPUseRequest(ply,item)
        if not IsValid(ply) or ply:GetItemCount(item) <= 0 then return end
 
        if not CAP.HasTag(item,"useable") then return end

        local itemRef = CAP.GetItemRef(item)
        if itemRef != nil then
            itemRef.UseFunction(ply,item,ply:GetEyeTrace())
        end
        if CAP.HasTag(item,"dontremove") then return end
        ply:ModifyItem(item,1,true)
    end
    net.Receive("toServer_CAPUseRequest",function()
        local ply           = net.ReadPlayer()
        local item          = net.ReadString()
        CAPUseRequest(ply,item)
    end)

end