-- Functions that make gui creation faster

local PANEL = FindMetaTable("Panel")

-- If posX is not a number then it centers
function PANEL:PanelInit(width,height,posX,posY)
    self:SetSize(width,height)
    if not isnumber(posX) then self:Center() return end
    self:SetPos(posX,posY)
end

function PANEL:SetTransform(posX,posY,width,height)
    self:SetPos(posX,posY)
    self:SetSize(width,height)
end

-- if posX is not a number then posY will be treated as the parent and parent as name.
function vgui.FastMakeDFrame(popup,width,height,posX,posY,parent,name)
    if not isnumber(posX) then parent = posY name = parent end

    local frame = vgui.Create("DFrame",parent,name)
    frame:PanelInit(width,height,posX,posY)

    if popup then frame:MakePopup() end

    return frame
end

-- if posX is not a number then posY will be treated as the parent and parent as name.
function vgui.FastMakePanel(panelName,width,height,posX,posY,parent,name)
    if not isnumber(posX) then parent = posY name = parent end


    local panel = vgui.Create(panelName,parent,name)
    if not IsValid(panel) or panel == NULL then return nil end
    panel:PanelInit(width,height,posX,posY)
    return panel
end

