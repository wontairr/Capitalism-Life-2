AddCSLuaFile("autorun/client/cl_capitalism.lua")
AddCSLuaFile("autorun/sh_capitalism.lua")
AddCSLuaFile("autorun/sh_capitalism_util.lua")

AddCSLuaFile("autorun/sh_capitalism_registeritems.lua")
AddCSLuaFile("autorun/sh_capitalism_registerdrops.lua")
AddCSLuaFile("autorun/sh_capitalism_registermarket.lua")

-- thinkpad
resource.AddWorkshop("3440884377")

include("autorun/sh_capitalism.lua")

include("autorun/sh_capitalism_util.lua")

local USEABLE_ITEMS = {
    "capitalismitem_camera",
    "capitalismitem_jeep",
    "capitalismitem_m9korbitalstrike",
    "capitalismitem_swep",
    "capitalismitem_metrofriend",
    "capitalismitem_barrel",
    "capitalismitem_bike"
} 
for _, item in ipairs(USEABLE_ITEMS) do
    include("autorun/items/" .. item .. ".lua")
end


util.AddNetworkString("toClient_CAPPlayerInitSpawn")
util.AddNetworkString("toClient_CAPAddItem")
util.AddNetworkString("toClient_CAPModifyItem")

util.AddNetworkString("toClient_CAPAllowPlayerRegister")

util.AddNetworkString("toClient_CAPSyncDebug")

util.AddNetworkString("toClient_CAPRefreshLaptop")


util.AddNetworkString("toClient_CAPChangeMarketItemCount")
util.AddNetworkString("toClient_CAPUpdateEconomy")

util.AddNetworkString("toServer_CAPBuyRequest")
util.AddNetworkString("toServer_CAPSellRequest")
util.AddNetworkString("toServer_CAPUseRequest")

util.AddNetworkString("toServer_CAPDebug")

util.AddNetworkString("toServer_CAPPlayerCanRecieveSaveTables")
util.AddNetworkString("toClient_CAPRecieveSaveTables")

local skipAheadCount = 0
local skippers = {}
local skippingAhead = false
util.AddNetworkString("toServer_submitSkipAhead")

util.AddNetworkString("toClient_CAPChatMessage")
local function BroadcastChat(msg)
    net.Start("toClient_CAPChatMessage")
        net.WriteString(msg)
    net.Broadcast()
end

net.Receive("toServer_submitSkipAhead",function(len,ply)
    if skippingAhead or skippers[tostring(ply:SteamID64())] then
        if skippers[tostring(ply:SteamID64())] then
            ply:ChatPrint("You already voted!")
        end
        return
    end
    skippers[tostring(ply:SteamID64())] = true
    skipAheadCount = skipAheadCount + 1
    BroadcastChat("Skip vote in progress, " .. skipAheadCount .. "/" .. #player.GetAll() -1)
    if skipAheadCount >= #player.GetAll() - 1 then
        skippingAhead = true
        BroadcastChat("SKIPPING AHEAD FOR 10 SECONDS!!")
        game.SetTimeScale(10)
        timer.Simple(55,function()
            BroadcastChat("SKIPPING IS NOW OVER.")
            game.SetTimeScale(1)
            skippingAhead = false
        end)
    else
        timer.Create("skippingResetTimer",25,1,function()
            BroadcastChat("Skip vote failed.")
            skipAheadCount = 0
            skippers = {}
        end)
    end
end)

net.Receive("toServer_CAPDebug",function(len,ply)
    //if not ply:IsAdmin() then return end
    local debugCode = net.ReadString()

    if debugCode == "registerall" then
        hook.Run("CapitalismRegisterItems")
        hook.Run("CapitalismRegisterDrops")
        hook.Run("CapitalismRegisterMarketItems") 
    elseif debugCode == "createecotimer" then
        CAP.CreateEconomyTimer()
    elseif debugCode == "addmoney" then
        if IsValid(ply) then ply:ModCash(true,1000) end
    elseif debugCode == "manualsave" then
        CAP.Debug("this")
        CAP.Save("manualsave")
    elseif debugCode == "manualload" then
        CAP.Load("manualsave",true)
    end
end)

net.Receive("toServer_CAPPlayerCanRecieveSaveTables",function(len,ply)
    if CAP.lastSave == {} then CAP.Debug("ERROR: tried to send save tables to a client but none were loaded!") return end
    local economy = CAP.UpdateEconomy(true)
    local marketItems = CAP.lastSave.marketItems
    CAP.Debug("Sending Save tables to ply")
    net.Start("toClient_CAPRecieveSaveTables")
        net.WriteCompressedTable(marketItems)
        net.WriteCompressedTable(economy)
    net.Send(ply)
    CAP.LoadPlayerData(ply)
end)

hook.Add("PlayerTick","CAPHACKSUITLAPTOP",function(ply)

    if not IsFirstTimePredicted() or ply:HasWeapon("weapon_capitalismlaptop") or not ply:IsSuitEquipped() or not ply:HasWeapon("weapon_crowbar") then return end
    ply:Give("weapon_capitalismlaptop")
end)