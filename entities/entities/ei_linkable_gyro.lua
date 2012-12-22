AddCSLuaFile()

ENT.PrintName		= "Gyroscope"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "Sensor for the Sandbox CPU"
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_linkable_ent"

ENT.Model 			= "models/bull/various/gyroscope.mdl"

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

function ENT:GetLinkTable()
	return {
		Orientation = function(chip)
			if not chip:GetWatts(0.01) then return end
			return self:GetAngles()
		end,
		AngleVelocity = function(chip)
			if not chip:GetWatts(0.01) then return end
			local ret = self:GetPhysicsObject():GetAngleVelocity()
			return Angle(ret.x, ret.z, ret.y)
		end
	}
end

function ENT:OnRemove()
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if CLIENT then
		local model = self:GetModel()

		if model == "models/bull/various/gyroscope.mdl" then

			local lineOfNodes = self:WorldToLocal( ( Vector(0,0,1):Cross( self:GetUp() ) ):GetNormal( ) + self:GetPos() )

			self:SetPoseParameter( "rot_yaw"  ,  math.deg( math.atan2( lineOfNodes[2] , lineOfNodes[1] ) ) )
			self:SetPoseParameter( "rot_roll" , -math.deg( math.acos( self:GetUp():DotProduct( Vector(0,0,1) ) )  or 0 ) )
		end
	end
	
	self:NextThink(CurTime()+0.04)
	return true
end

function ENT:OnTakeDamage(dmginfo)
end
