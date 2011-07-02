
local LBF = LibStub("LibButtonFacade", true)
local LMB = LibMasque and LibMasque("Button")
if not (LBF or LMB) then return end
local addonName = ...
local f = CreateFrame("Frame")
local parents = {}
local skinned = {}
local isSet, db
local pairs, wipe =
	  pairs, wipe

local function SetVertexColor(border, r, g, b, a)
	if r == .6 and g == .6 and b == .6 then
		a = 0
	else
		a = 1
	end
	border:setvertexcolor(r, g, b, a)
end
local function onupdate()
	for frame, buttons in pairs(parents) do
		local groupName = ShadowUF.L.units[frame.parent.unitType]
		local group = LBF:Group("ShadowedUF", groupName)
		for _, button in pairs(buttons) do
			if not skinned[button] then
				local border = button.border
				border.button = button
				
				border.setvertexcolor = border.SetVertexColor
				border.SetVertexColor = SetVertexColor
				local r, g, b = border:GetVertexColor()
				border:SetVertexColor(floor(r*100+0.5)/100, floor(g*100+0.5)/100, floor(b*100+0.5)/100) -- round it, because ugly numbers come out of GetVertexColor
				
				group:AddButton(button, {
					Icon = button.icon,
					Cooldown = button.cooldown,
					Border = button.border,
					Count = button.stack,
				})
				
				skinned[button] = 1
			end
		end
	end
	wipe(parents)
	f:SetScript("OnUpdate", nil)
	isSet = nil
end


hooksecurefunc("CreateFrame",
    function(_, _, parent)
        if parent and parent.buttons and parent.type and parent.totalAuras then -- make sure the parent is a SUF frame and not something else
            parents[parent] = parent.buttons
			if not isSet then
				f:SetScript("OnUpdate", onupdate)
				isSet = 1
			end
        end
    end
)

local oldUpdate = ShadowUF.modules.auras.Update
function ShadowUF.modules.auras:Update(frame, ...) -- sorry about the raw hook, shadowed...
	oldUpdate(self, frame, ...)
	
	local groupname = ShadowUF.L.units[frame.unitType]
	if not LMB then
		local v = ShadowedUFFacade[groupName]
		if v then
			LBF:Group("ShadowedUF", groupname):Skin(v.S,v.G,v.B,v.C)
		end
	end
	LBF:Group("ShadowedUF", groupname):ReSkin()
end

if not LMB then
	local function OnEvent(self, event, addon)
		ShadowedUFFacade = ShadowedUFFacade or {}
		db = ShadowedUFFacade
		LBF:RegisterSkinCallback("ShadowedUF",
			function(_, SkinID, Gloss, Backdrop, Group, _, Colors)
				if not (db and SkinID) then return end
				if Group then
					local gs = db[Group] or {}
					db[Group] = gs
					gs.S = SkinID
					gs.G = Gloss
					gs.B = Backdrop
					gs.C = Colors
				end
			end
		)
		for k, v in pairs(db) do
			LBF:Group("ShadowedUF", k):Skin(v.S,v.G,v.B,v.C)
		end
		f:SetScript("OnEvent", nil)
	end

	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnEvent", OnEvent)
end

