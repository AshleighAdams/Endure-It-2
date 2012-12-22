AddCSLuaFile()

ENT.PrintName		= "Plug"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "Plug to transfer all them WattZ"
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "base_gmodentity"
ENT.Model 			= "models/props_lab/tpplug.mdl"

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

function ENT:PreEntityCopy()
	if CLIENT then return end
	local info = {}
	
	self.Other  = self.Other or Entity(0)
	self.Socket  = self.Socket or Entity(0)
	
	info.Other  = self.Other:EntIndex()
	info.Socket  = self.Socket:EntIndex()
		
	duplicator.StoreEntityModifier(self, "PlugData", info)
end

function ENT:PostEntityPaste(pl, ent, CreatedEntities)
	if CLIENT then return end
	if not ent.EntityMods then ErrorNoHalt("Warning: no data to spawn plug with (duped)") return end
	
	local tbl = ent.EntityMods["PlugData"]
	if not tbl then ErrorNoHalt("Warning: no data to spawn plug with (EntityMods)") return end
	
	PrintTable(tbl)
	
	self.Other = CreatedEntities[tbl.Other]
	self.Socket = CreatedEntities[tbl.Socket]
end

function ENT:Setup()
	local ent = ents.Create( self:GetClass() )
		ent:SetPos( self:GetPos() + Vector(0, 0, 50) )
		ent:SetAngles( self:GetAngles() )
	ent:Spawn()
	ent:Activate()
	
	ent.Other = self
	self.Other = ent
	
	local forcelimit = 0
	local addlength	 = 0
	local material 	 = "cable/cable2"
	local width 	 = 2
	local rigid	 	= false
	 
	// Get information we're about to use
	local Ent1,  Ent2  = self, 				 ent
	local Bone1, Bone2 = 0,					 0
	local WPos1, WPos2 = self:GetPos(),		 ent:GetPos()
	local LPos1, LPos2 = Vector(11, 0, 0),	 Vector(11, 0, 0)
	local length = 500
 
	local const, rope = constraint.Rope( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, length, addlength, forcelimit, width, material, rigid )
	
	ent:DeleteOnRemove(self)
	self:DeleteOnRemove(ent)
	self:DeleteOnRemove(const)
end

function ENT:Initialize()
	self:SetModel(self.Model)
	self.Links = {}
	
	
	if SERVER then
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		
		local phys = self:GetPhysicsObject();
		if phys:IsValid() then
			phys:Wake()
		end
	end	
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 2
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180
	
	local ent = ents.Create(ClassName)
		ent:SetPos(SpawnPos)
		ent:SetAngles(SpawnAng)
	ent:Spawn()
	ent:Activate()
	
	ent:Setup()
	
	return ent
	
end

function ENT:SetSocket(sock)
	self.Socket = sock
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmginfo)
end
