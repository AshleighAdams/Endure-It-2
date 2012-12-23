AddCSLuaFile()

ENT.PrintName		= "Battery (1.5kWh @ 300Ws)"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "..."
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_power_source"
ENT.Model 			= "models/items/car_battery01.mdl"
ENT.Capacity		= 2728*1000 -- 2728kJ
ENT.Bandwidth		= 300

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= true
ENT.AdminSpawnable		= false


function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	self.Joules = 0
	self.JoulesCache = 0
	
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
