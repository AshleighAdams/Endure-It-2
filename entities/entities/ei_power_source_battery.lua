AddCSLuaFile()

ENT.PrintName		= "Battery (972kJ)"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "..."
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_power_source"
ENT.Model 			= "models/items/car_battery01.mdl"
// Same battery found in a 206
ENT.Capacity		= (0.5*45/*Ah*/*12/*V*/)/*Wh*/*60/*Wm*/*60/*Ws (J)*/ -- 45Ah @ 12V = 1.728MJ (480Wh) E = �QV
ENT.Bandwidth		= 350/*A*/ * 12/*V*/

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
