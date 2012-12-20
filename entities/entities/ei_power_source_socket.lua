AddCSLuaFile()

ENT.PrintName		= "500Watt Battery"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "..."
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_power_source"
ENT.Model 			= "models/items/car_battery01.mdl"
ENT.Capacity		= 0
ENT.Bandwidth		= 0

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:GetOther()
	if IsValid(self.Plug) then
		if IsValid(self.Plug.OtherPlug.Socket) then
			return self.Plug.OtherPlug.Socket
		end
	end
	
	return nil
end

function ENT:MaxWatt(from_otherside)
	if from_otherside then
		return self.BaseClass.MaxWatt(self)
	end
	
	if self:GetOther() then
		return self:GetOther():MaxWatt(true)
	end
	return 0
end

function ENT:TakeWatts(amm, from_otherside)
	if from_otherside then
		return self.BaseClass.TakeWatts(self)
	end
	
	if self:GetOther() then
		return self:GetOther():TakeWatts()
	end
	return self.BaseClass.TakeWatts(self)
	-- take watts from other
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Plug = NullEntity()
end

function ENT:Think()
	-- Nope, this will "charge us", which we don't want to do.
	--self.BaseClass.Think(self)
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmginfo)
end
