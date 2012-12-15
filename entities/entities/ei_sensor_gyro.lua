AddCSLuaFile()

ENT.PrintName		= "Gyroscope"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "Sensor for the Sandbox CPU"
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Linkable		= true
ENT.Base 			= "base_gmodentity"

ENT.Model 			= "models/props_lab/huladoll.mdl"

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

function ENT:Initialize()

	if ( SERVER ) then
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
	end
	
	self:SetModel(self.Model)
end

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180
	
	local ent = ents.Create( ClassName )
		ent:SetPos( SpawnPos )
		ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()
	
	return ent
	
end

function ENT:BaseGetLinkTable()
	local tbl = self:GetLinkTable()
	
	tbl.TypeName = self.TypeName
	
	return tbl
end

function ENT:GetLinkTable()
	return {
		Orientation = function()
			return self:GetAngles()
		end
	}
end

function ENT:OnRemove()
end


function ENT:OnTakeDamage(dmginfo)
end
