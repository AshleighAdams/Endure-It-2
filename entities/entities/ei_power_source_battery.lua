AddCSLuaFile()

ENT.PrintName		= "500Watt Battery"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "..."
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_power_source"
ENT.Model 			= "models/items/car_battery01.mdl"
ENT.Capacity		= 500
ENT.Bandwidth		= 25

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

function ENT:MaxWatt()
	-- this could be recursive, for say a plug
	if self.WattsCache < self.Bandwidth then
		return self.WattsCache
	end
	
	return self.WattsCache
end

function ENT:TakeWatts(amm)
	self.Watts = self.Watts - amm
	self.WattsCache = self.WattsCache - amm
end

function ENT:GetWatts(watt)
	if self:MaxWatt() < watt then return false end
	
	self:TakeWatts(watt)
	return true
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	self.Watts = 0
	self.WattsCache = 0
	
	self.LastThink = CurTime()
end

function ENT:Think()
	self.BaseClass.Think(self)
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmginfo)
end

function ENT:PreEntityCopy()
	if CLIENT then return end
	local info = {}
	
	info.PowerSources = {}
	for k,v in pairs(self.PowerSources) do
		info.PowerSources[k] = v:EntIndex()
	end
	
	duplicator.StoreEntityModifier(self, "BatteryData", info)
end

function ENT:PostEntityPaste(pl, ent, CreatedEntities)
	if CLIENT then return end
	if not ent.EntityMods then ErrorNoHalt("Warning: no data to spawn plug with (duped)") return end
	
	local tbl = ent.EntityMods["BatteryData"]
	if not tbl then ErrorNoHalt("Warning: no data to spawn plug with (EntityMods)") return end
	
	for k,v in pairs(tbl.PowerSources) do
		self.PowerSources[k] = CreatedEntities[v]
	end
end
