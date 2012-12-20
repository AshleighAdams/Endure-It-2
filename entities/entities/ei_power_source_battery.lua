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

ENT.Spawnable			= false
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
