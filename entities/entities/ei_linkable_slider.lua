
AddCSLuaFile()

ENT.PrintName		= "Slider"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_BOTH
ENT.Base			= "ei_linkable_ent"

ENT.Model 			= "models/maxofs2d/button_slider.mdl"
ENT.Thrust			= 0
ENT.Enabled 		= 0

ENT.Spawnable			= true
ENT.AdminSpawnable		= false
ENT.DownCount 			= 0

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:SetUseType(CONTINUOUS_USE)
	end
end

function ENT:PreEntityCopy()
	if CLIENT then return end
	local info = {}
	
	info.Value = self:GetVal()
	
	duplicator.StoreEntityModifier(self, "SliderData", info)
end

function ENT:PostEntityPaste(pl, ent, CreatedEntities)
	if CLIENT then return end
	if not ent.EntityMods then return end
	
	local tbl = ent.EntityMods["SliderData"]
	
	if not tbl then return end
	
	self:SetVal(tbl.Value)
end

function ENT:GetVal()
	return self:GetNWFloat("Val", 0)
end

function ENT:SetVal(v)
	return self:SetNWFloat("Val", v)
end

local function Scale(x, from_min, from_max, to_min, to_max)
	local from_diff = from_max - from_min
	local to_diff = to_max - to_min
	
	local y = (x - from_min) / from_diff
	return to_min + to_diff * y
end

function ENT:Use( activator, caller, type, value )
	if not IsValid(activator) then return end
	if not activator:IsPlayer() then return end
	
	local pl = activator
	
	local t = {}
		t.start = pl:GetShootPos()
		t.endpos = pl:GetAimVector() * 64 + t.start
		t.filter = pl
	local tr = util.TraceLine(t)
	
	if not tr.Hit then return end
	if not tr.Entity == self then return end
	
	local pos = self:WorldToLocal(tr.HitPos)
	local val = Scale(pos.x, -5.619, 5.697, 1, 0)
	
	val = math.Clamp(val, 0, 1)
	
	self:SetVal(val)
end

function ENT:Think()
	if CLIENT then
		self:UpdateAnimation()
	end
end

CreateClientConVar("cl_ei_slider_interp", 0.1)

function ENT:UpdateAnimation()
	self.InterpTable = self.InterpTable or {}
	self.LastVal = self.LastVal or 0
	
	if self:GetVal() != self.LastVal then
		table.insert(self.InterpTable, {RealTime(), self:GetVal()})
		self.LastVal = self:GetVal()
	end
	
	local interptime = RealTime() - GetConVar("cl_ei_slider_interp"):GetFloat()
	-- 200ms to do shit
	
	self.PosePosition = self.PosePosition or 0
	
	
	local lastk
	for k,v in pairs(self.InterpTable) do
		if v[1] < interptime then
			if lastk then
				table.remove(self.InterpTable, lastk)
			end
			lastk = k
			continue
		end
		break
	end
	
	local cur = self.InterpTable[1]
	local nxt = self.InterpTable[2]
	
	if nxt != nil then
		if interptime > nxt[1] then
			print("WARNING, EXTRAPOLATING!", interptime, cur[1], nxt[1])
		end
		self.PosePosition = Scale(interptime, cur[1], nxt[1], cur[2], nxt[2])
	else
		self.PosePosition = self:GetVal()
	end
	
	--self.PosePosition = math.Approach( self.PosePosition, TargetPos, (tickspeed * self.Diff) * self.Distance)	

	self:SetPoseParameter( "switch", self.PosePosition )
	self:InvalidateBoneCache()
end

function ENT:GetLinkTable()
	return {
		GetValue = function()
			return self:GetVal()
		end,
		SetValue = function(chip, val)
			return self:SetVal(val)
		end
	}
end