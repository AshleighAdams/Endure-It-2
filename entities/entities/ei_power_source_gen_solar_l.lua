AddCSLuaFile()

ENT.PrintName		= "Solar Panel (L)"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "..."
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_power_source"
ENT.Model 			= "models/ce_ls3additional/solar_generator/solar_generator_huge.mdl"
ENT.Yeild			= 0
ENT.EndPoint 		= true
ENT.Capacity = ENT.Yeild
ENT.Bandwidth = ENT.Yeild

ENT.Spawnable			= true
ENT.AdminSpawnable		= false


AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )


function ENT:MaxJoule()
	return self.Joules
end
/*
function ENT:TakeJoules(amm)
	self.Joules = self.Joules - amm
end

function ENT:GetJoules(joule)
	if self:MaxJoule() < joule then return false end
	
	self:TakeJoules(joule)
	return true
end
*/
function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	local max = self:OBBMaxs()
	self.Yeild = (max.x * max.y * 2) / 621 * (12) -- 12Ws per square foot
	
	self.Capacity = self.Yeild
	self.Bandwidth = self.Yeild
	
	self.Joules = 0
	
	self.LastThink = CurTime()
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	self.LastThinkT = self.LastThinkT or CurTime()
	local t = CurTime() - self.LastThinkT
	
	local gain = self.Yeild * t
	if self.Joules + gain > self.Yeild then
		gain = self.Yeild - self.Joules
	end
	self:AddJoules(gain)
	
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
