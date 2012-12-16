
AddCSLuaFile()

ENT.PrintName		= "Geiger Counter"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE
ENT.Base			= "ei_linkable_ent"

ENT.Model 			= "models/Items/combine_rifle_ammo01.mdl"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.Counts			= 0

function ENT:Initialize()
	self.BaseClass.Initialize(self)
end


function ENT:Draw()
	self.BaseClass.Draw( self )
end

function ENT:Think()
	self.BaseClass.Think( self )
	if SERVER then
		
		if math.random(0, 500) == 1 then
			self.Counts = self.Counts + 1
			self:EmitSound("player/geiger1.wav")
		end
		
		self:NextThink(CurTime())
		return true
	end
end

function ENT:OnTakeDamage( dmginfo )
end

function ENT:GetLinkTable()
	return {
		Query = function(x, y)
			local ret = self.Counts
			self.Counts = 0
			return ret
		end
	}
end