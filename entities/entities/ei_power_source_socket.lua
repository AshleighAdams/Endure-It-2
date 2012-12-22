AddCSLuaFile()

ENT.PrintName		= "Power Socket"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "..."
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_power_source"
ENT.Model 			= "models/props_lab/tpplugholder_single.mdl"
ENT.Capacity		= 0
ENT.Bandwidth		= 0
ENT.EndPoint		= false

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

function ENT:GetOther()
	if IsValid(self.Plug) then
		if IsValid(self.Plug.Other.Socket) then
			return self.Plug.Other.Socket
		end
	end
	
	return nil
end

function ENT:MaxWatt(from_otherside, doneents, depth)
	if self:GetOther() then
		return self.BaseClass.MaxWatt(self:GetOther())
	end
	return 0
end


function ENT:GetWatts(amm, from_otherside, doneents)
	if not doneents then doneents = {} end
	
	if doneents[self] then return 0 end
	doneents[self] = true
	
	
	if from_otherside then
		return self.BaseClass.GetWatts(self, amm, doneents)
	end
	
	if self:GetOther() then
		return self:GetOther():GetWatts(amm, true, doneents)
	end
	return false
	-- take watts from other
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Plug = Entity(-1)
end

function ENT:GetOffset( vec )
	local offset = vec

	local ang = self:GetAngles()
	local stackdir = ang:Up()
	offset = ang:Up() * offset.X + ang:Forward() * -1 * offset.Z + ang:Right() * offset.Y

	return self:GetPos() + stackdir * 2 + offset
end

function ENT:PreEntityCopy()
	if CLIENT then return end
	local info = {}
	
	self.Plug  = self.Plug or Entity(0)
	self.Const  = self.Const or Entity(0)
	self.NoCollideConst  = self.NoCollideConst or Entity(0)
	
	info.Plug = self.Plug:EntIndex()
	info.Const = self.Const:EntIndex()
	info.NoCollideConst = self.NoCollideConst:EntIndex()
	
	info.PowerSources = {}
	for k,v in pairs(self.PowerSources) do
		info.PowerSources[k] = v:EntIndex()
	end
	
	duplicator.StoreEntityModifier(self, "SocketData", info)
end

function ENT:PostEntityPaste(pl, ent, CreatedEntities)
	if CLIENT then return end
	if not ent.EntityMods then ErrorNoHalt("Warning: no data to spawn plug with (duped)") return end
	
	local tbl = ent.EntityMods["SocketData"]
	if not tbl then ErrorNoHalt("Warning: no data to spawn plug with (EntityMods)") return end
	
	self.Plug = CreatedEntities[tbl.Plug]
	self.Const = CreatedEntities[tbl.Const]
	self.NoCollideConst = CreatedEntities[tbl.NoCollideConst]
	
	for k,v in pairs(tbl.PowerSources) do
		self.PowerSources[k] = CreatedEntities[v]
	end
end

function ENT:Think()
	-- Nope, this will "charge us", which we don't want to do.
	--self.BaseClass.Think(self)
	if CLIENT then return end
		
	if self.Const and not IsValid(self.Const) then
		self.Const = nil
		self.NoCollideConst = nil
		if (self.Plug) and IsValid(self.Plug) then
			self.Plug:SetSocket(nil)
			self.Plug = nil
		end

		self:NextThink(CurTime() + 2)
		return true
	end
	
	if not IsValid(self.Plug) then
		
		local center = self:GetOffset(Vector(-1.75, 0, 0))
		local local_ents = ents.FindInSphere(center, 15)
		for key, plug in pairs(local_ents) do
			if not IsValid(plug) then continue end
			if plug:GetClass() != "ei_plug" then continue end
			
			if IsValid(plug.Socket) and plug.Socket then
				if plug.Socket.Plug == plug then continue end
			end
			
			local plugpos = plug:GetPos()
			local dist = (center-plugpos):Length()

			self:AttachPlug(plug)
			
			self:NextThink(CurTime() + 0.05)
			return true
			
		end
	end
	
	self:NextThink(CurTime() + 0.05)
	return true
end

function ENT:AttachPlug(plug)
	plug:SetSocket(self)
	
	DropEntityIfHeld(plug)
	
	self.Plug = plug
	
	// Position
	plug:SetPos(self:GetOffset(Vector(8, -13, -5)))
	plug:SetAngles(self:GetAngles())

	// Nocollide
	self.NoCollideConst = constraint.NoCollide(self, plug, 0, 0)
	if (not self.NoCollideConst) then
		self.Plug = nil
		plug:SetSocket(nil)
		return
	end

	// Constrain together
	self.Const = constraint.Weld(self, plug, 0, 0, 5000, true)
	if (not self.Const) then
		self.NoCollideConst:Remove()
		self.NoCollideConst = nil
		self.Plug = nil
		plug:SetSocket(nil)
		return
	end

	// Prepare clearup incase one is removed
	plug:DeleteOnRemove( self.Const )
	self:DeleteOnRemove( self.Const )
	self.Const:DeleteOnRemove( self.NoCollideConst )
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmginfo)
end
