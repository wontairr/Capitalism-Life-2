AddCSLuaFile()
if SERVER then
    util.AddNetworkString("toClient_CAPLaptopShowGUI")
    util.AddNetworkString("toServer_CAPLaptopStartUsing")
    util.AddNetworkString("toClient_CAPKILLTHEGHOSTSDIENOW")
end

SWEP.Base = "weapon_base"

SWEP.PrintName = "Laptop"
SWEP.Author = "Wontairr"

SWEP.Purpose = "Capitalism"

SWEP.Category = "Other"

SWEP.Spawnable = true 
SWEP.AdminOnly = false 

SWEP.ViewModel      = "models/thinkpad/v_thinkpad.mdl"
SWEP.ViewModelFOV   = 105
SWEP.WorldModel     = "models/weapons/w_slam.mdl"

SWEP.UseHands = true

SWEP.Slot    = 0
SWEP.SlotPos = 10

SWEP.Primary.Ammo           = "none"
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false 

SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false 

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false




function SWEP:SetupDataTables()
    self:NetworkVar( "Bool", "UsingItem" )
    self:NetworkVar("String","ItemName")
end


function SWEP:Holster()
    if self:GetUsingItem() then
        self:SetUsingItem(false)
        self:ReleaseGhostEntity()

    end
    return true
end

function SWEP:Deploy()
    self:SetHoldType("slam")
    if CLIENT then return end

    net.Start("toClient_CAPLaptopShowGUI")
        net.WriteEntity(self)
    net.Send(self:GetOwner())
 
end
function SWEP:PrimaryAttack()
    if CurTime() < self:GetNextPrimaryFire() then return end
    timer.Simple(0.1,function()
        if CLIENT then return end
        net.Start("toClient_CAPKILLTHEGHOSTSDIENOW")
        net.WriteEntity(self)
        net.Send(self:GetOwner())
    end)
    if SERVER then
        CAP.Debug("Using: " .. tostring(self:GetUsingItem()))
        if self:GetUsingItem() then
            self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
            
            CAP.Debug("Use request")
            for _, wep in ipairs(self:GetOwner():GetWeapons()) do
                if wep:GetClass() != "weapon_capitalismlaptop" then
                    self:GetOwner():SelectWeapon(wep:GetClass())
                    break
                end
            end
            CAPUseRequest(self:GetOwner(),self:GetItemName())
            self:SetUsingItem(false)

        end
    end


    self:SetNextPrimaryFire(CurTime() + 0.5)
end
function SWEP:SecondaryAttack()
    if CurTime() < self:GetNextSecondaryFire() then return end

    if self:GetUsingItem() then
        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
        CAP.Debug("Cancel use")
        self:SetUsingItem(false)
        self:ReleaseGhostEntity()
        net.Start("toClient_CAPLaptopShowGUI")
            net.WriteEntity(self)
        net.Send(self:GetOwner())
    end

    self:SetNextSecondaryFire(CurTime() + 0.5)
end


function SWEP:MakeGhostEntity( model, pos, angle )

	util.PrecacheModel( model )

	-- We do ghosting serverside in single player
	-- It's done clientside in multiplayer
	if ( SERVER && !game.SinglePlayer() ) then return end
	if ( CLIENT && game.SinglePlayer() ) then return end

	-- The reason we need this is because in multiplayer, when you holster a tool serverside,
	-- either by using the spawnnmenu's Weapons tab or by simply entering a vehicle,
	-- the Think hook is called once after Holster is called on the client, recreating the ghost entity right after it was removed.
	if ( !IsFirstTimePredicted() ) then return end

	-- Release the old ghost entity
	self:ReleaseGhostEntity()

	-- Don't allow ragdolls/effects to be ghosts
	if ( !util.IsValidProp( model ) ) then return end

	if ( CLIENT ) then
		self.GhostEntity = ents.CreateClientProp( model )
	else
		self.GhostEntity = ents.Create( "prop_physics" )
	end

	-- If there's too many entities we might not spawn..
	if ( !IsValid( self.GhostEntity ) ) then
		self.GhostEntity = nil
		return
	end

	self.GhostEntity:SetModel( model )
	self.GhostEntity:SetPos( pos )
	self.GhostEntity:SetAngles( angle )
	self.GhostEntity:Spawn()

	-- We do not want physics at all
	self.GhostEntity:PhysicsDestroy()

	-- SOLID_NONE causes issues with Entity.NearestPoint used by Wheel tool
	--self.GhostEntity:SetSolid( SOLID_NONE )
	self.GhostEntity:SetMoveType( MOVETYPE_NONE )
	self.GhostEntity:SetNotSolid( true )
	self.GhostEntity:SetRenderMode( RENDERMODE_TRANSCOLOR )
	self.GhostEntity:SetColor( Color( 255, 255, 255, 150 ) )

	-- Do not save this thing in saves/dupes
	self.GhostEntity.DoNotDuplicate = true

	-- Mark this entity as ghost prop for other code
	self.GhostEntity.IsToolGhost = true

end

function SWEP:ReleaseGhostEntity()

	if ( self.GhostEntity ) then
		if ( !IsValid( self.GhostEntity ) ) then self.GhostEntity = nil return end
		self.GhostEntity:Remove()
		self.GhostEntity = nil
	end

	-- This is unused!
	if ( self.GhostEntities ) then

		for k, v in pairs( self.GhostEntities ) do
			if ( IsValid( v ) ) then v:Remove() end
			self.GhostEntities[ k ] = nil
		end

		self.GhostEntities = nil
	end

	-- This is unused!
	if ( self.GhostOffset ) then

		for k, v in pairs( self.GhostOffset ) do
			self.GhostOffset[ k ] = nil
		end

	end

end

--[[---------------------------------------------------------
	Update the ghost entity
-----------------------------------------------------------]]
function SWEP:UpdateGhostEntity()

	if ( self.GhostEntity == nil ) then return end
	if ( !IsValid( self.GhostEntity ) ) then self.GhostEntity = nil return end

	local trace = self:GetOwner():GetEyeTrace()
	if ( !trace.Hit ) then return end

	local Ang1, Ang2 = ( trace.HitNormal * -1 ),( trace.HitNormal * -1 )
	local TargetAngle = angle_zero


	self.GhostEntity:SetAngles( TargetAngle )

	local TargetPos = trace.HitPos + trace.HitNormal

	self.GhostEntity:SetPos( TargetPos )

end
if SERVER then
    net.Receive("toServer_CAPLaptopStartUsing",function(len,ply)
        local plyWep = ply:GetActiveWeapon()
        if not IsValid(plyWep) or plyWep:GetClass() != "weapon_capitalismlaptop" then return end
        local item = net.ReadString()
        if ply:GetItemCount(item) <= 0 then return end
        CAP.Debug("this")
        plyWep:SetUsingItem(true)
        plyWep:SetItemName(item)
        plyWep:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    end)
end

if SERVER then return end

net.Receive("toClient_CAPKILLTHEGHOSTSDIENOW",function()
    local ent = net.ReadEntity()
    if IsValid(ent) then ent:ReleaseGhostEntity() end
end)

local lastModel = ""


function SWEP:Think()
    if self:GetUsingItem() then
 
        if ( !IsValid( self.GhostEntity ) and lastModel != "" ) then
            self:MakeGhostEntity(lastModel, vector_origin, angle_zero )
        end
    
        self:UpdateGhostEntity()
    else
        if  IsValid( self.GhostEntity ) then self:ReleaseGhostEntity() end
    end

end

local baseFrame = nil
local tabs = {}
local lastTab = "  Inventory  "


local globalAngles = Angle(0,0,0)
local function GetTabHeight(self)
    
    return self:IsActive() and 90 or 80
end

local function LayoutEntity(self,Entity)
    Entity:SetAngles(globalAngles)
    if self.Small then Entity:SetModelScale(0.5) end
    self:SetLookAt(Entity:WorldSpaceCenter())
    if not self.Entity then self.Entity = Entity end
end
local function RichTextPerformLayout(ref)
    ref:SetFontInternal("CAPBigFont") -- Change to any font you prefer
    ref:SetTall(32)
    ref:SetY(ref:GetParent():GetTall()/2 - 32/2)
    ref:SetVerticalScrollbarEnabled(false) -- Hide scrollbar
end

function SWEP:GetHelp(sheet)
    local help = vgui.FastMakePanel("RichText",2,2,0,0,sheet)
    help:Dock(FILL)
    help:InsertColorChange(0,200,0,255)
    help.PerformLayout = function(s)
        s:SetFontInternal("CAPMediumFont")
    end
    help:AppendText("-CAPITALISM OS V1.0-\n\nWelcome to your HOME for Capitalism.\n\n")
    help:AppendText("Some props can be sold, see if you can pick them up with ALT + E!\n\n")
    help:AppendText("The less an item is dropped, the higher the theoretical rarity!\n\n")
    help:AppendText("Weapons can be equipped by buying the weapon, then in your inventory clicking USE, then click anywhere in the world!!\n\n")
    help:AppendText("Other useable items normally function by clicking use, then clicking anywhere in the world!!\n\n")
    return help
end

function SWEP:GetPlayers(sheet)
    local playerList = vgui.FastMakePanel("DScrollPanel",2,2,0,0,sheet)


    playerList:Dock(FILL)


    playerList.Paint = function(self,w,h)
        globalAngles.y = RealTime() * 100 % 360
        globalAngles.z = RealTime() * 200 % 360
    end
    local sortedPlayers = player.GetAll()

  
    table.sort(sortedPlayers, function(a, b)
        return a:GetCash() > b:GetCash()
    end)
    
    
    -- Iterate over sorted inventory
    for _, ply in ipairs(sortedPlayers) do
        
        local itemPanel = playerList:Add("DPanel")
        itemPanel:Dock(TOP)
        itemPanel:DockMargin(0,0,0,5)
        itemPanel:SetSize(100,75)
        itemPanel.Paint = CAP.Palette.PaintBoxOutlinedModulate

        -- Icon
        local itemIcon = vgui.Create("DModelPanel",itemPanel)
        itemIcon:SetModel(ply:GetModel())


        itemIcon.LayoutEntity = LayoutEntity
        local modelBoundsX,modelBoundsY = itemIcon.Entity:GetModelBounds()
        local fov = (modelBoundsX - modelBoundsY):Length()

        itemIcon:SetFOV(fov)

        itemIcon:Dock(LEFT)

        itemIcon:SetSize(itemPanel:GetTall(),itemPanel:GetTall())

        -- Label
        local itemName = vgui.Create("RichText",itemPanel)
        itemName:Dock(FILL)
        itemName:SetMouseInputEnabled(false)

        itemName:InsertColorChange(255,255,255,255)
        itemName:AppendText("| " .. ply:Name() .. " | ")

        
        itemName:InsertColorChange(0,210,0,255)
        itemName:AppendText("\t$" .. tostring(ply:GetCash()))
  

        itemName.PerformLayout = RichTextPerformLayout
        

   
       
    end
    return playerList
end

function SWEP:GetInventory(sheet)
    local itemList = vgui.FastMakePanel("DScrollPanel",2,2,0,0,sheet)


    itemList:Dock(FILL)


    itemList.Paint = function(self,w,h)
        globalAngles.y = RealTime() * 100 % 360
        globalAngles.z = RealTime() * 200 % 360
    end
    local sortedInventory = {}

    for idIn, item in pairs(self:GetOwner().CInventory) do
        table.insert(sortedInventory, {idIn,item})
    end
  
    table.sort(sortedInventory, function(a, b)
        
        return CAP.GetCurrentPrice(a[1]) > CAP.GetCurrentPrice(b[1])
    end)
    
    
    -- Iterate over sorted inventory
    for _, data in ipairs(sortedInventory) do
        local itemID = data[1]
        local item = data[2]
        local itemPanel = itemList:Add("DPanel")
        itemPanel:Dock(TOP)
        itemPanel:DockMargin(0,0,0,5)
        itemPanel:SetSize(100,75)
        itemPanel.Paint = CAP.Palette.PaintBoxOutlinedModulate

        -- Icon
        local itemIcon = vgui.Create("DModelPanel",itemPanel)
        itemIcon:SetModel(item[1].model)
        itemIcon.PaintOver = function(self,w,h)
            draw.SimpleText(tostring(item[2]), "CAPMediumFont",6,h,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
        end

        itemIcon.LayoutEntity = LayoutEntity
        local modelBoundsX,modelBoundsY = itemIcon.Entity:GetModelBounds()
        local fov = (modelBoundsX - modelBoundsY):Length()
        if CAP.HasTag(itemID,"highfov") then fov = fov + 75 end
        if CAP.HasTag(itemID,"lowfov") then fov = fov - 60 end
        if CAP.HasTag(itemID,"medfov") then fov = fov - 35 end
        itemIcon:SetFOV(fov)

        itemIcon:Dock(LEFT)

        itemIcon:SetSize(itemPanel:GetTall(),itemPanel:GetTall())

        -- Label
        local itemName = vgui.Create("RichText",itemPanel)
        itemName:Dock(FILL)
        itemName:SetMouseInputEnabled(false)

        itemName:InsertColorChange(255,255,255,255)
        itemName:AppendText("| " .. item[1].name .. " | ")

        local lower = CAP.IsPriceLowerNow(itemID)
        if lower == true then
            itemName:InsertColorChange(200,70,0,255)
        else
            itemName:InsertColorChange(0,210,0,255)
        end
        itemName:AppendText("\t$" .. tostring(CAP.GetCurrentPrice(itemID)))
        if lower == true then itemName:AppendText("↘") elseif lower == false then itemName:AppendText("↗") end


        itemName.PerformLayout = RichTextPerformLayout
        
        local sellButton = vgui.Create("DButton",itemPanel)

        sellButton:SetFontInternal("CAPBigFont")
        sellButton:SetText("")
        sellButton.Text = "SELL"
        sellButton:Dock(RIGHT)
        sellButton.PerformLayout = function()
            sellButton:SetSize(itemPanel:GetTall(),itemPanel:GetTall())
        end
        sellButton.Paint = CAP.Palette.PaintButton
        sellButton.DoClick = function()
            surface.PlaySound("buttons/button9.wav")
            net.Start("toServer_CAPSellRequest")
                net.WritePlayer(LocalPlayer())
                net.WriteString(itemID)
            net.SendToServer()
        end
        
        if not CAP.HasTag(itemID,"useable") then continue end
        local useButton = vgui.Create("DButton",itemPanel)

        useButton:SetFontInternal("CAPBigFont")
        useButton:SetText("")
        useButton.Text = "USE"
        useButton:Dock(RIGHT)
        useButton.PerformLayout = function()
            useButton:SetSize(itemPanel:GetTall(),itemPanel:GetTall())
        end
        useButton.Paint = CAP.Palette.PaintButton
        useButton.DoClick = function()
            surface.PlaySound("buttons/button9.wav")
            net.Start("toServer_CAPLaptopStartUsing")
                net.WriteString(itemID)
            net.SendToServer()
       
            lastModel = item[1].model
            self:MakeGhostEntity(item[1].model,LocalPlayer():GetEyeTrace().HitPos,Angle(0,0,0))
            baseFrame.dontDoClose = true
            baseFrame:Close()
        end
       
    end
    return itemList
end

function SWEP:GetMarket()
    local marketList = vgui.FastMakePanel("DScrollPanel",2,2,0,0,sheet)


    marketList:Dock(FILL)

    marketList.Paint = function(self,w,h)
        globalAngles.y = RealTime() * 100 % 360
        globalAngles.z = RealTime() * 200 % 360
    end

    local sortedMarket = {}


    for idIn, item in pairs(CAP.MARKET_ITEMS) do
        table.insert(sortedMarket, {idIn,item})
    end
  
    table.sort(sortedMarket, function(a, b)
        
        return CAP.GetCurrentPrice(a[1]) > CAP.GetCurrentPrice(b[1])
    end)
    
    -- Iterate over sorted inventory
    for _, data in ipairs(sortedMarket) do
        local itemID = data[1]
        local item = data[2]
        local itemPanel = marketList:Add("DPanel")
        itemPanel:Dock(TOP)
        itemPanel:DockMargin(0,0,0,5)
        itemPanel:SetSize(100,75)
        itemPanel.Paint = CAP.Palette.PaintBoxOutlinedModulate

        -- Icon
        local itemIcon = vgui.Create("DModelPanel",itemPanel)
        itemIcon:SetModel(item[1].model)
        if CAP.HasTag(itemID,"smallmodel") then itemIcon.Small = true end
        itemIcon.PaintOver = function(self,w,h)
            draw.SimpleText(tostring(item[2]), "CAPMediumFont",6,h,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
        end

        itemIcon.LayoutEntity = LayoutEntity
        local modelBoundsX,modelBoundsY = itemIcon.Entity:GetModelBounds()
        local fov = (modelBoundsX - modelBoundsY):Length()

        if CAP.HasTag(itemID,"highfov") then fov = fov + 75 end
        if CAP.HasTag(itemID,"lowfov") then fov = fov - 50 end
        if CAP.HasTag(itemID,"medfov") then fov = fov - 40 end

        itemIcon:SetFOV(fov)

        itemIcon:Dock(LEFT)

        itemIcon:SetSize(itemPanel:GetTall(),itemPanel:GetTall())

        -- Label
        local itemName = vgui.Create("RichText",itemPanel)
        itemName:Dock(FILL)
        itemName:SetMouseInputEnabled(false)

        itemName:InsertColorChange(255,255,255,255)
        itemName:AppendText("| " .. item[1].name .. " | " )
        local lower = CAP.IsPriceLowerNow(itemID)
        if lower == true then
            itemName:InsertColorChange(200,70,0,255)
        else
            itemName:InsertColorChange(0,210,0,255)
        end
        itemName:AppendText("\t$" .. tostring(CAP.GetCurrentPrice(itemID)))
        if lower == true then itemName:AppendText("↘") elseif lower == false then itemName:AppendText("↗") end


        itemName.PerformLayout = RichTextPerformLayout
        

        local buyButton = vgui.Create("DButton",itemPanel)
        buyButton:SetFontInternal("CAPBigFont")
        buyButton:SetText("")
        buyButton.Text = "BUY"
        buyButton:Dock(RIGHT)
        buyButton.PerformLayout = function()
            buyButton:SetSize(itemPanel:GetTall(),itemPanel:GetTall())
        end
        local sellButton = vgui.Create("DButton",itemPanel)

        sellButton:SetFontInternal("CAPBigFont")
        sellButton:SetText("")
        sellButton.Text = "SELL"
        sellButton:Dock(RIGHT)
        sellButton.PerformLayout = function()
            sellButton:SetSize(itemPanel:GetTall(),itemPanel:GetTall())
        end
        sellButton.Paint = CAP.Palette.PaintButton
        buyButton.Paint = CAP.Palette.PaintButton


        buyButton.DoClick = function()
            surface.PlaySound("buttons/button9.wav")
            net.Start("toServer_CAPBuyRequest")
                net.WritePlayer(LocalPlayer())
                net.WriteString(itemID)
            net.SendToServer()
        end
        sellButton.DoClick = function()
            surface.PlaySound("buttons/button9.wav")
            net.Start("toServer_CAPSellRequest")
                net.WritePlayer(LocalPlayer())
                net.WriteString(itemID)
            net.SendToServer()
        end

        local itemPriceHistory = CAP.PreviousItemPrices[itemID]
        if itemPriceHistory == nil then continue end

        local peak = itemPriceHistory[1]
        for i = 1, #itemPriceHistory do
            if itemPriceHistory[i] > peak then peak = itemPriceHistory[i] end
        end 
        local normalized = {}
        for i = 1, #itemPriceHistory do
            normalized[i] = itemPriceHistory[i] / peak
        end


        local graph = vgui.Create("DPanel",itemPanel)
        graph:Dock(RIGHT)
        graph:SetSize(200,itemPanel:GetTall())

        local normalizedLength = #normalized
        graph.Paint = function(s, w, h)
            -- Paint background
            CAP.Palette.PaintBoxOutlinedGlass(s, w, h)
        
            -- Draw line graph
            -- Loop through the normalized data to draw the line graph
            for i = 1, normalizedLength - 1 do
                local x1 = (i - 1) / (normalizedLength - 1) * w  -- scale x-axis based on panel width
                local y1 = h - normalized[i] * h  -- scale y-axis based on panel height
                local x2 = i / (normalizedLength - 1) * w  -- scale x-axis for the next point
                local y2 = h - normalized[i + 1] * h  -- scale y-axis for the next point
                surface.SetDrawColor(y2 > y1 and CAP.Palette.RED or CAP.Palette.GREENLIGHT )
                
                -- Draw line from (x1, y1) to (x2, y2)
                surface.DrawLine(x1, y1, x2, y2)
            end
        end
        
    
    end
    return marketList
end


function CAPRefreshLaptop()
    if IsValid(baseFrame) and IsValid(baseFrame.SWEP) then
        baseFrame.SWEP:ShowGUI(lastTab)
    end
end

net.Receive("toClient_CAPRefreshLaptop",CAPRefreshLaptop)

function SWEP:ShowGUI()
    if not self:GetOwner().CInventory then self:GetOwner().CInventory = {} end
    if IsValid(baseFrame) then
        baseFrame.dontDoClose = true
        baseFrame:Close()
    end

    
    baseFrame = vgui.FastMakeDFrame(true,ScrW()/2,ScrH()/2,false)
    baseFrame.OnClose = function()
        if baseFrame.dontDoClose then return end
        for _, wep in ipairs(self:GetOwner():GetWeapons()) do
            if wep:GetClass() != "weapon_capitalismlaptop" then
                input.SelectWeapon(wep)
                break
            end
        end
    end
    baseFrame.SWEP = self

    baseFrame.Paint =  CAP.Palette.PaintBoxOutlinedGlassBlur
    local sheet = vgui.Create( "DPropertySheet", baseFrame )
    sheet:Dock( FILL )
    sheet.Paint = CAP.Palette.PaintBoxOutlinedDark
    sheet:SetFadeTime(0.05)
    --[[
    local topBar = vgui.Create("DHorizontalScroller",baseFrame)
    topBar:Dock(TOP)
    topBar:SetTall(80)
    topBar:SetOverlap(-5)
    ]]


   
    
    -- Inventory
    local itemList = self:GetInventory(sheet)
    local invTab = sheet:AddSheet("  Inventory  ",itemList).Tab
    invTab.GetTabHeight = GetTabHeight

    invTab:SetFontInternal("DermaLarge")

    invTab.Paint = CAP.Palette.PaintBoxOutlinedModulate


    -- Market
    local marketList = self:GetMarket(sheet)
    local marketTab = sheet:AddSheet("  Market  ",marketList).Tab
    marketTab:SetFontInternal("DermaLarge")
    marketTab.GetTabHeight = GetTabHeight
    marketTab.Paint = CAP.Palette.PaintBoxOutlinedModulate

    local playerList = self:GetPlayers(sheet)
    local playerTab = sheet:AddSheet("  Players  ",playerList).Tab
    playerTab:SetFontInternal("DermaLarge")
    playerTab.GetTabHeight = GetTabHeight
    playerTab.Paint = CAP.Palette.PaintBoxOutlinedModulate

    local helpList = self:GetHelp(sheet)
    local helpTab = sheet:AddSheet("  Help  ",helpList).Tab
    helpTab:SetFontInternal("DermaLarge")
    helpTab.GetTabHeight = GetTabHeight
    helpTab.Paint = CAP.Palette.PaintBoxOutlinedModulate

    tabs[marketTab:GetText()]   = marketTab
    tabs[invTab:GetText()]      = invTab
    tabs[playerTab:GetText()]   = playerTab
    tabs[helpTab:GetText()]     = helpTab

    sheet:SetActiveTab(tabs[lastTab])
    
    
    sheet.OnActiveTabChanged = function(self,old,new)
        lastTab = new:GetText()
        surface.PlaySound("buttons/button7.wav")
    end

end


net.Receive("toClient_CAPLaptopShowGUI",function()
   local weapon = net.ReadEntity()
   if not IsValid(weapon) then return end
   weapon:ShowGUI()
end)
