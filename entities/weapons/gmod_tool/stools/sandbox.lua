
TOOL.Category		= "Endure It"
TOOL.Name			= "Sandbox"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "model" ]			= "models/hunter/plates/plate.mdl"
TOOL.ClientConVar[ "file" ]				= "sandbox.lua"

cleanup.Register( "sandbox" )

function TOOL:RightClick( trace )

	if ( IsValid( trace.Entity ) && trace.Entity:IsPlayer() ) then return false end
	if ( CLIENT ) then return true end
	if ( !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	local ply = self:GetOwner()
	
	local model				= self:GetClientInfo( "model" )
	local filename			= self:GetClientInfo( "file" )

	if ( !self:GetSWEP():CheckLimit( "sandbox" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		-- Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local code = [[
		self.CreateLink("sensor", "ei_sensor_")
		self.gyro = self.GetLink("sensor")
		
		self.NextPrint = CurTime()
		
		function Think()
			if CurTime() > self.NextPrint then
				self.NextPrint = CurTime() + 5
				
				print(self.gyro.Connected)
			end
		end
	]]

	chip = MakeSandbox( ply, model, Ang, trace.HitPos, code)
	
	local min = chip:OBBMins()
	chip:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const
	
	undo.Create("Sandbox")
		undo.AddEntity( chip )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "sandboxes", chip )
	
	return true, chip

end

function TOOL:LeftClick( trace )

	local bool, chip, set_key = self:RightClick( trace, true )
	if ( CLIENT ) then return bool end

	if ( set_key ) then return true end
	if ( !chip || !chip:IsValid() ) then return false end
	if ( !trace.Entity:IsValid() && !trace.Entity:IsWorld() ) then return false end

	local weld = constraint.Weld( chip, trace.Entity, 0, trace.PhysicsBone, 0, 0, true )
	trace.Entity:DeleteOnRemove( weld )
	chip:DeleteOnRemove( weld )

	chip:GetPhysicsObject():EnableCollisions( false )
	chip.nocollide = true
	
	return true

end

if SERVER then
	CreateConVar("sbox_maxsandbox", 100)
end

if (SERVER) then

	function MakeSandbox( pl, Model, Ang, Pos, code, frozen )
	
		if ( IsValid( pl ) && !pl:CheckLimit( "sandbox" ) ) then return false end
	
		local sandbox = ents.Create( "ei_sandbox" )
		if ( !IsValid( sandbox ) ) then return false end
		sandbox:SetModel( Model )

		sandbox:SetAngles( Ang )
		sandbox:SetPos( Pos )
		sandbox:Spawn()
		
		sandbox:SetPlayer( pl )
		sandbox.Owner = pl
		
		sandbox:Setup(code)

		local ttable = 
			{
				pl		= pl,
				code 	= code
			}

		table.Merge( sandbox:GetTable(), ttable )
		
		if ( IsValid( pl ) ) then
			pl:AddCount( "sandbox", sandbox )
		end
		
		DoPropSpawnedEffect( sandbox )

		return sandbox
		
	end
	
	duplicator.RegisterEntityClass( "ei_sandbox", MakeSandbox, "Model", "Ang", "Pos", "key", "description", "toggle", "Vel", "aVel", "frozen" )

end


function TOOL:Think()

	
end



function TOOL.BuildCPanel( CPanel )

	-- HEADER
	CPanel:AddControl( "Header", { Text = "Sandbox CPU", Description	= "Execute sandboxed Lua code" }  )
	
	local Options = { Default = { sandbox_model = "models/hunter/plates/plate.mdl" } }
									
	local CVars = { "sandbox_model", "sandbox_file"}
	
	CPanel:AddControl( "ComboBox", { Label = "#tool.presets",
									 MenuButton = 1,
									 Folder = "sandbox",
									 Options = Options,
									 CVars = CVars } )
									 							
									 
	CPanel:AddControl( "TextBox", { Label = "File",
									 MaxLenth = "20",
									 Command = "sandbox_file" } )
									
end


list.Set( "SandboxModels", "models/hunter/plates/plate.mdl", {} )

