include("autorun/sh_capitalism.lua")
include("autorun/sh_capitalism_util.lua")


surface.CreateFont("CAPMediumFont", {
    font = "Roboto",
    size = 24,
    weight = 700
})
surface.CreateFont("CAPBigFont", {
    font = "Trebuchet MS",
    size = 32,
    weight = 900
})

surface.CreateFont("CAPCashFont", {
    font = "Roboto",
    size = 60,
    weight = 700
})



local itemData = {}

function CAPClientGetItemEffect(itemRef)
    local model = itemRef.model

    itemData = {model,CurTime() + 1.5,itemRef.name,false}
    if IsValid(CAP.dmodelpanel) then
        CAP.dmodelpanel:SetModel(model)
    end
end
CAP.globalAngles = Angle(0,0,0)
local posX,posY = 0,0
local function CreateDMODELPANEL()
    if CAP.dmodelpanel and IsValid(CAP.dmodelpanel) then
        return
    end
    CAP.dmodelpanel = vgui.Create("DModelPanel")
    CAP.dmodelpanel:SetFOV(50)
    local function LayoutEntity(self,Entity)
    
        Entity:SetAngles(CAP.globalAngles)
        self:SetLookAt(Entity:WorldSpaceCenter())
    
    end
    CAP.dmodelpanel.LayoutEntity = LayoutEntity
    CAP.dmodelpanel:SetSize(300,300)
    CAP.dmodelpanel:Center()
    CAP.dmodelpanel:SetY(CAP.dmodelpanel:GetY() + 100)
    posX,posY = CAP.dmodelpanel:GetPos()
    CAP.dmodelpanel:SetModel("models/nova/w_headgear.mdl")
    CAP.dmodelpanel.PaintOver = function(s,w,h)
        draw.SimpleText(itemData[3],"CAPMediumFont",w/2,h/1.4,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM)
    end
end

net.Receive("toClient_CAPChatMessage",function()
    local msg = net.ReadString()
    chat.AddText(Color(20,220,20,255),msg)
end)

hook.Add("HUDPaint","CAP_GREENEFFECT",function()
    if not _G.CAP then return end
    CreateDMODELPANEL()
    CAP.Palette.GREENMODULATE.g = Lerp(math.sin(CurTime() * 4),CAP.Palette.GREENLIGHT.g + 10,CAP.Palette.GREENLIGHT.g - 80)
    
    draw.SimpleTextOutlined(
        tostring("$" .. LocalPlayer():GetCash()),"CAPCashFont",ScrW() - 40,40,CAP.Palette.GREENLIGHT,TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP,
        2,color_black)
    CAP.globalAngles.y = RealTime() * 100 % 360
    CAP.globalAngles.z = RealTime() * 200 % 360
    if CAP.dmodelpanel and IsValid(CAP.dmodelpanel) then
        if #itemData < 2 or itemData[4] == true then CAP.dmodelpanel:SetSize(0,0) return end
   
        if CurTime() > itemData[2] then
            local x,y = CAP.dmodelpanel:GetPos()
            local w,h = CAP.dmodelpanel:GetSize()
            local lerpX,lerpY = Lerp(FrameTime() *2.5,x,0),Lerp(FrameTime() *2.5,y,0)
            local lerpW,lerpH = Lerp(FrameTime() *2,w,0),Lerp(FrameTime() *2,h,0)
            CAP.dmodelpanel:SetPos(lerpX,lerpY)
            CAP.dmodelpanel:SetSize(lerpW,lerpH)
            if x < 120 and y < 120 then
                itemData[4] = true
            end
        else
   
            CAP.dmodelpanel:SetSize(300,300)
            CAP.dmodelpanel:SetPos(posX,posY)
        end
        
    end
    
end)


local lasttime = 0


concommand.Add("capitalism_testeq",function(ply,cmd,args)
    print("time " .. SysTime())
    print("diff " .. SysTime() - lasttime)
    lasttime = SysTime()

    local timeInterval = args[1]
    local stock = args[2]

    local mult = 0.25

    print("Time: ",timeInterval)
    print("Stock: ", stock,"\n")
    local equation = mult * (timeInterval / (stock / 2))
    print(equation)
end)