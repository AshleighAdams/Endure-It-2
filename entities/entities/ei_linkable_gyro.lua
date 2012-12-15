AddCSLuaFile()

ENT.PrintName		= "Gyroscope"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "Sensor for the Sandbox CPU"
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_linkable_ent"

ENT.Model 			= "models/props_lab/huladoll.mdl"

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

function ENT:GetLinkTable()
	return {
		Orientation = function()
			return self:GetAngles() + self:LocalToWorldAngles(Angle(0, 180, 0))
		end,
		AngleVelocity = function()
			local ret = self:GetPhysicsObject():GetAngleVelocity()
			return Angle(ret.x, ret.z, ret.y)
		end
	}
end

function ENT:OnRemove()
end


function ENT:OnTakeDamage(dmginfo)
end
