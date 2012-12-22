AddCSLuaFile()

ENT.PrintName		= "Fusion Reactor"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "..."
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_power_source"
ENT.Model 			= "models/smallbridge/life support/sbfusiongen.mdl"
ENT.Yeild			= 5 * 1000 * 1000 -- 5MW
ENT.EndPoint 		= true
ENT.Capacity = ENT.Yeild
ENT.Bandwidth = ENT.Yeild

ENT.Spawnable			= true
ENT.AdminSpawnable		= false


AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )


function ENT:MaxWatt()
	return self.Watts
end
/*
function ENT:TakeWatts(amm)
	self.Watts = self.Watts - amm
end

function ENT:GetWatts(watt)
	if self:MaxWatt() < watt then return false end
	
	self:TakeWatts(watt)
	return true
end
*/
function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	self.Watts = 0
	
	self.LastThink = CurTime()
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	self.LastThinkT = self.LastThinkT or CurTime()
	local t = CurTime() - self.LastThinkT
	
	local gain = self.Yeild * t
	if self.Watts + gain > self.Yeild then
		gain = self.Yeild - self.Watts
	end
	self:AddWatts(gain)
	
	self.LastThinkT = CurTime()
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
	
	duplicator.StoreEntityModifier(self, "GeneratorData", info)
end

function ENT:PostEntityPaste(pl, ent, CreatedEntities)
	if CLIENT then return end
	if not ent.EntityMods then ErrorNoHalt("Warning: no data to spawn plug with (duped)") return end
	
	local tbl = ent.EntityMods["GeneratorData"]
	if not tbl then ErrorNoHalt("Warning: no data to spawn plug with (EntityMods)") return end
	
	for k,v in pairs(tbl.PowerSources) do
		self.PowerSources[k] = CreatedEntities[v]
	end
end
