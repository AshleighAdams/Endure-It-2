
AddCSLuaFile()

ENT.PrintName		= "Button"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_BOTH
ENT.Base			= "ei_linkable_ent"

ENT.Model 			= "models/maxofs2d/button_05.mdl"
ENT.Thrust			= 0
ENT.Enabled 		= 0

ENT.Spawnable			= true
ENT.AdminSpawnable		= false
ENT.DownCount 			= 0

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	self:SetUseType(ONOFF_USE)
end

function ENT:GetOn()
	return self:GetNWBool("On", false)
end

function ENT:SetOn(b)
	return self:SetNWBool("On", b)
end

function ENT:Use( activator, caller, type, value )
	
	if type == USE_ON then
		self:SetOn(true)
		
		timer.Simple(0.1, function()
			self:SetOn(false)
		end)
	end
end

function ENT:Think()
	if CLIENT then
		self:UpdateAnimation()
	end
end

function ENT:UpdateAnimation()
	local TargetPos = 0.0;
	if ( self:GetOn() ) then TargetPos = 1.0; end
	
	self.PosePosition = self.PosePosition or 0
	self.PosePosition = math.Approach( self.PosePosition, TargetPos, FrameTime() * 20 )	

	self:SetPoseParameter( "switch", self.PosePosition )
	self:InvalidateBoneCache()
end

function ENT:GetLinkTable()
	return {
		IsPressed = function()
			return self:GetOn()
		end
	}
end