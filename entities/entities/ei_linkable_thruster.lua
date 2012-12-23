
AddCSLuaFile()

ENT.PrintName		= "Thruster"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_BOTH
ENT.Base			= "ei_linkable_ent"

ENT.Model 			= "models/dav0r/thruster.mdl"
ENT.Thrust			= 0
ENT.Enabled 		= 0

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

local matHeatWave		= Material( "sprites/heatwave" )
local matFire			= Material( "effects/fire_cloud1" )
local matPlasma			= Material( "effects/strider_muzzle" )

if ( CLIENT ) then
	CreateConVar( "cl_drawthrusterseffects", "1" )
end



function ENT:SetEffect( name )
	self:SetNetworkedString( "Effect", name )
end


function ENT:GetEffect( name )
	return self:GetNetworkedString( "Effect", "" )
end

function ENT:SetOn( boolon )
	self:SetNetworkedBool( "On", boolon, true )
end

function ENT:IsOn( name )
	return self:GetNetworkedBool( "On", false )
end

function ENT:SetOffset( v )
	self:SetNetworkedVector( "Offset", v, true )
end

function ENT:GetOffset( name )
	return self:GetNetworkedVector( "Offset" )
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	if ( CLIENT ) then
		self.ShouldDraw = 1
		self.NextSmokeEffect = 0
		
		-- Make the render bounds a bigger so the effect doesn't get snipped off
		local mx, mn = self:GetRenderBounds()
		self:SetRenderBounds( mn + Vector(0,0,128), mx, 0 )
		
		self.Seed = math.Rand( 0, 10000 )
	else
	
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		
		local phys = self:GetPhysicsObject()
		
		if (phys:IsValid()) then
			phys:Wake()
		end
		
		local max = self:OBBMaxs()
		local min = self:OBBMins()
		
		self.ThrustOffset 	= Vector( 0, 0, max.z )
		self.ThrustOffsetR 	= Vector( 0, 0, min.z )
		self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1
		
		self:SetEffect( "plasma" )
		self:SetSound( "k_lab.ringsrotating" ) //  /thrusters/mh1.wav sounds better?
		
		self:Switch(true)
		self:Switch(false)
	
		self:SetForce( 1000 )
	
		self:SetOffset( self.ThrustOffset )
		self:StartMotionController()
		
		self:Switch( false )
		self.ActivateOnDamage = false
		
		self.SoundName = Sound( "k_lab.ringsrotating" )
		
		
		
	end

end


function ENT:Draw()

	self.BaseClass.Draw( self )
			
end


function ENT:DrawTranslucent()

	if ( self.ShouldDraw == 0 ) then return end

	self.BaseClass.DrawTranslucent( self )
		
	if ( !self:IsOn() ) then 
		self.OnStart = nil
	return end
	
	if ( self:GetEffect() == "none" ) then return end
	
	self.OnStart = self.OnStart or CurTime()
	
	local EffectThink = self[ "EffectDraw_"..self:GetEffect() ]
	if ( EffectThink ) then EffectThink( self ) end
	
end

//ENT.NextSoundSet = 0
function ENT:Think()
	/*if CurTime() > self.NextSoundSet then
		self.NextSoundSet = CurTime() + 1
		
		if self.Sound and self:IsOn() then
			//self.Sound:ChangeVolume(self.force / 1000, 0.25)
			print(self.force / 1000, SERVER)
		end
	end
	*/
	
	
	if SERVER then
		if self.Chip then
			local found = false
			for k,v in pairs(self.Chip.Links) do
				if IsValid(v.Entity) and v.Entity == self then
					found = true
					break
				end
			end
			
			if not found then
				self.Chip = nil
				self:Switch(false)
			end
		end
		
		local t = CurTime() - (self.LastThrusterThinkT or CurTime())
		self.LastThrusterThinkT = CurTime()
		
		if self.force > 0 and self.Chip then
			local got = self.Chip:GetJoules(self.force / 1000 * t)
			
			if got then
				if not self:IsOn() then
					self:Switch(true)
				end
			else
				if self:IsOn() then
					self:Switch(false)
				end
			end
		end
	
	end
	
	self.BaseClass.Think( self )
	
	if ( CLIENT ) then
		
		self.ShouldDraw = GetConVarNumber( "cl_drawthrusterseffects" )
		
		local bDraw = true

		if ( self.ShouldDraw == 0 ) then bDraw = false end
		
		if ( !self:IsOn() ) then bDraw = false end
		if ( self:GetEffect() == "none" ) then bDraw = false end

		if ( !bDraw ) then return end
		
		local EffectThink = self[ "EffectThink_"..self:GetEffect() ]
		if ( EffectThink ) then EffectThink( self ) end
		
	end	

end


function ENT:EffectThink_fire()
end

function ENT:EffectDraw_fire()

	local vOffset = self:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local scroll = self.Seed + (CurTime() * -10)
	
	local Scale = math.Clamp( (CurTime() - self.OnStart) * 5, 0, 1 )
		
	render.SetMaterial( matFire )
	
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8 * Scale, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60 * Scale, 32 * Scale, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148 * Scale, 32 * Scale, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()
	
	scroll = scroll * 0.5
	
	render.UpdateRefractTexture()
	render.SetMaterial( matHeatWave )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8 * Scale, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 32 * Scale, 32 * Scale, scroll + 2, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * 128 * Scale, 48 * Scale, scroll + 5, Color( 0, 0, 0, 0) )
	render.EndBeam()
	
	
	scroll = scroll * 1.3
	render.SetMaterial( matFire )
	render.StartBeam( 3 )
		render.AddBeam( vOffset, 8 * Scale, scroll, Color( 0, 0, 255, 128) )
		render.AddBeam( vOffset + vNormal * 60 * Scale, 16 * Scale, scroll + 1, Color( 255, 255, 255, 128) )
		render.AddBeam( vOffset + vNormal * 148 * Scale, 16 * Scale, scroll + 3, Color( 255, 255, 255, 0) )
	render.EndBeam()
	
end


function ENT:EffectDraw_plasma()

	local vOffset = self:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local scroll = CurTime() * -20
		
	render.SetMaterial( matPlasma )
	
	scroll = scroll * 0.9
	
	local len = self:PlasmaSize()
	
	local width = math.Clamp(len / 4, 0, 16)
	
	render.StartBeam( 3 )
		render.AddBeam( vOffset, width, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * len/8, width, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * len, width, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()
	
	scroll = scroll * 0.9
	
	render.StartBeam( 3 )
		render.AddBeam( vOffset, width, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * len/8, width, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * len, width, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()
	
	scroll = scroll * 0.9
	
	render.StartBeam( 3 )
		render.AddBeam( vOffset, width, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * len/8, width, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( vOffset + vNormal * len, width, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()
	
end


function ENT:EffectThink_smoke()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end
	
	self.SmokeTimer = CurTime() + 0.015

	local vOffset = self:LocalToWorld( self:GetOffset() ) + Vector( math.Rand( -3, 3 ), math.Rand( -3, 3 ), math.Rand( -3, 3 ) )
	local vNormal = (vOffset - self:GetPos()):GetNormalized()

	local emitter = self:GetEmitter( vOffset, false )
	
		local particle = emitter:Add( "particles/smokey", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 10, 30 ) )
			particle:SetDieTime( 2.0 )
			particle:SetStartAlpha( math.Rand( 50, 150 ) )
			particle:SetStartSize( math.Rand( 16, 32 ) )
			particle:SetEndSize( math.Rand( 64, 128 ) )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )
			particle:SetColor( 200, 200, 210 )

end


function ENT:EffectThink_magic()

	self.SmokeTimer = self.SmokeTimer or 0
	if ( self.SmokeTimer > CurTime() ) then return end
	
	self.SmokeTimer = CurTime() + 0.01

	local vOffset = self:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self:GetPos()):GetNormalized()
	
	vOffset = vOffset + VectorRand() * 5

	local emitter = self:GetEmitter( vOffset, false )
	
		local particle = emitter:Add( "sprites/gmdm_pickups/light", vOffset )
			particle:SetVelocity( vNormal * math.Rand( 80, 160 ) )
			particle:SetDieTime( 0.5 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 255 )
			particle:SetStartSize( math.Rand( 1, 3 ) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -0.2, 0.2 ) )

end


function ENT:EffectDraw_rings()

	self.RingTimer = self.RingTimer or 0
	if ( self.RingTimer > CurTime() ) then return end
	self.RingTimer = CurTime() + 0.01

	
	local vOffset = self:LocalToWorld( self:GetOffset() )
	local vNormal = (vOffset - self:GetPos()):GetNormalized()
	
	vOffset = vOffset + vNormal * 5
		
	local emitter = self:GetEmitter( vOffset, true )
	
		local particle = emitter:Add( "effects/select_ring", vOffset )
		if (particle) then
		
			particle:SetVelocity( vNormal * 300 )
			particle:SetLifeTime( 0 )
			particle:SetDieTime( 0.2 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 8 )
			particle:SetEndSize( 10 )
			particle:SetAngles( vNormal:Angle() )
			particle:SetColor( math.Rand( 10, 100 ), math.Rand( 100, 220 ), math.Rand( 240, 255 ) )
						
		end

	
end

--[[---------------------------------------------------------
   Name: Use the same emitter, but get a new one every 2 seconds
		This will fix any draw order issues
-----------------------------------------------------------]]
function ENT:GetEmitter( Pos, b3D )

	if ( self.Emitter ) then	
		if ( self.EmitterIs3D == b3D && self.EmitterTime > CurTime() ) then
			return self.Emitter
		end
	end
	
	self.Emitter = ParticleEmitter( Pos, b3D )
	self.EmitterIs3D = b3D
	self.EmitterTime = CurTime() + 2
	return self.Emitter

end

--[[---------------------------------------------------------
   Name: OnRemove
-----------------------------------------------------------]]
function ENT:OnRemove()

	if (self.Sound) then
		self.Sound:Stop()
	end

end

--[[---------------------------------------------------------
   Name: SetForce
-----------------------------------------------------------]]
function ENT:SetForce( force, mul )
	if (force) then	self.force = force end
	mul = mul or 1
	
	self:SetNWFloat("force", force)
	
	local phys = self:GetPhysicsObject()
	if (!phys:IsValid()) then 
		Msg("Warning: [gmod_thruster] Physics object isn't valid!\n")
		return 
	end
	
	-- Get the data in worldspace
	local ThrusterWorldPos = phys:LocalToWorld( self.ThrustOffset )
	local ThrusterWorldForce = phys:LocalToWorldVector( self.ThrustOffset * -1 )
	
	-- Calculate the velocity
	ThrusterWorldForce = ThrusterWorldForce * self.force * mul * 50
	self.ForceLinear, self.ForceAngle = phys:CalculateVelocityOffset( ThrusterWorldForce, ThrusterWorldPos );
	self.ForceLinear = phys:WorldToLocalVector( self.ForceLinear )
	
	if ( mul > 0 ) then
		self:SetOffset( self.ThrustOffset )
	else
		self:SetOffset( self.ThrustOffsetR )
	end
	
	self:SetNetworkedVector( 1, self.ForceAngle )
	self:SetNetworkedVector( 2, self.ForceLinear )
	
	self:SetOverlayText( "Force: " .. math.floor( self.force ) )
	
	if self:IsOn() then
		self.Sound:ChangeVolume(self.force / 1000, 0.25)
		
		
		
	end
	
	local p = (self.force / 1000)
	p = (math.Clamp(p, 0, 1) * 25) + 100
	self.Sound:ChangePitch(p, 0.25)

end


function ENT:AddMul( mul, bDown )

	if ( self:GetToggle() ) then 
	
		if ( !bDown ) then return end
		
		if ( self.Multiply == mul ) then 
			self.Multiply = 0
		else 
			self.Multiply = mul 
		end
		
	else
	
		self.Multiply = self.Multiply or 0
		self.Multiply = self.Multiply + mul	
	
	end

	
	self:SetForce( nil, self.Multiply )
	self:Switch( self.Multiply != 0 )
	
end

function ENT:OnTakeDamage( dmginfo )
end


function ENT:Use( activator, caller )
end

function ENT:PlasmaSize()
	return self:GetNWFloat("force", 10) / 10
end

function ENT:PhysicsSimulate( phys, deltatime )
	--if (!self:IsOn()) then return SIM_NOTHING end
	
	if not IsValid(self.Chip) then
		--self:Switch(false)
		return SIM_NOTHING
	end
	if (!self:IsOn()) then return SIM_NOTHING end
	local ForceAngle, ForceLinear = self.ForceAngle, self.ForceLinear
	
	if SERVER and self:GetNWFloat("force") > 250 then
		local tr = util.QuickTrace(self:GetPos() + self:GetAngles():Up() * 10, 
			self:GetAngles():Up() * (self:PlasmaSize()),
			self)
		if IsValid(tr.Entity) then
			if tr.Entity.LastBurn and (CurTime() - tr.Entity.LastBurn) > 1 then
				tr.Entity:Extinguish()
				tr.Entity.LastBurn = CurTime()
			elseif tr.Entity.LastBurn == nil then
				tr.Entity.LastBurn = CurTime()
			end
			
			tr.Entity:Ignite(1, 0)
		end
	end
	
	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end

function ENT:Switch( on )
	if (!self:IsValid()) then return false end
	if self:IsOn() == on then return end
	
	self:SetOn( on )
	
	if (on) then 
		self:StartThrustSound()
	else
		self:StopThrustSound()
	end
	
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	return true
	
end

function ENT:SetSound( sound )
	self.SoundName = Sound( sound )
	self.Sound = nil
end

function ENT:StartThrustSound()

	if ( !self.SoundName || self.SoundName == "" ) then return; end

	if ( !self.Sound ) then
		self.Sound = CreateSound( self.Entity, self.SoundName )
	end
	
	self.Sound:PlayEx( 0.5, 100 )

end

function ENT:StopThrustSound()

	if ( self.Sound ) then
		self.Sound:ChangeVolume( 0.0, 0.25 )
	end

end

function ENT:SetToggle(tog)
	self.Toggle = tog
end

function ENT:GetToggle()
	return self.Toggle
end

function ENT:GetLinkTable()
	return {
		SetThrust = function(chip, thrust)
			self.Chip = chip
			thrust = math.max(0, thrust)
			
			local got = self.Chip:GetJoules(thrust / 1000)
			
			self:Switch(got and thrust > 0)
			self:SetForce(thrust)
		end
	}
end