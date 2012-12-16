AddCSLuaFile()

ENT.PrintName		= "Stable Platform"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "A platform that can remove angular momentum"
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_linkable_ent"

ENT.Model 			= "models/hunter/blocks/cube025x025x025.mdl"

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

function ENT:GetLinkTable()
	return {
		Pitch = function(val)
			--val = val * self:GetPhysicsObject():GetMass()
			self:GetPhysicsObject():AddAngleVelocity(Vector(val, 0, 0))
		end,
		Yaw = function(val)
			--val = val * self:GetPhysicsObject():GetMass()
			self:GetPhysicsObject():AddAngleVelocity(Vector(0, 0, val))
		end,
		Roll = function(val)
			--val = val * self:GetPhysicsObject():GetMass()
			self:GetPhysicsObject():AddAngleVelocity(Vector(0, val, 0))
		end,
		Friction = function(val)
			local po = self:GetPhysicsObject()
			val = math.Clamp(val, 0, 1)
			po:AddAngleVelocity(-po:GetAngleVelocity() * val)
		end
	}
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmginfo)
end