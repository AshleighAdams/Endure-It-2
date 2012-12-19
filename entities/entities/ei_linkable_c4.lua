
AddCSLuaFile()

ENT.PrintName		= "Plastic Explosives"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE
ENT.Base			= "ei_linkable_ent"

ENT.Model 			= "models/dav0r/tnt/tnt.mdl"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false


function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
end


function ENT:Draw()

	self.BaseClass.Draw( self )
			
end

function ENT:Think()

	self.BaseClass.Think( self )
	
end

function ENT:OnRemove()

end

function ENT:OnTakeDamage( dmginfo )
end


function ENT:Use( activator, caller )
end

function ENT:GetLinkTable()
	return {
		Fire = function(chip)
			// Create an explosion
			-- TODO
			local vPoint = self:GetPos()
			local effectdata = EffectData()
			effectdata:SetStart( vPoint ) // not sure if we need a start and origin (endpoint) for this effect, but whatever
			effectdata:SetOrigin( vPoint )
			effectdata:SetScale( 1 )
			
			local effect = "Explosion"
			
			if false then -- in space
				effect = "HelicopterMegaBomb"
			end
			
			util.Effect(effect, effectdata)	
			util.BlastDamage(self, self, self:GetPos(), 256, 100)

			self:Remove()
		end
	}
end