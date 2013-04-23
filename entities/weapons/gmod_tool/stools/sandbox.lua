
TOOL.Category		= "Endure It"
TOOL.Name			= "Sandbox"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "model" ]			= "models/hunter/plates/plate.mdl"
TOOL.ClientConVar[ "file" ]				= "sandbox.lua"

if CLIENT then
	language.Add("tool.sandbox.name", "Sandbox")
	language.Add("tool.sandbox.desc", "Create a sandbox CPU")
	language.Add("tool.sandbox.0", "Left click to attach a CPU, Right click to upload code")
	language.Add("Undone_Sandbox", "Undone Sandbox")
end

cleanup.Register( "sandbox" )

if SERVER then
	util.AddNetworkString("sandbox_upload")
	
	net.Receive("sandbox_upload", function(len, pl)
		local name = net.ReadString()
		local code = net.ReadString()
		pl.Programs = pl.Programs or {}
		
		pl.Programs[name] = code
		
		pl:ChatPrint("Recived program " .. name)
	end)
end


function ParseCodeFile(f, done_files, parent_file, file_offsets)
	if done_files[f] then return "" end
	done_files[f] = true
	
	local f_local
	local contents
	
	if parent_file != nil then
		f_local	= string.GetPathFromFilename(parent_file) .. f
		contents = file.Read(f_local, "DATA")
	end
	
	if not contents then
		contents = file.Read(f, "DATA")
		
		if not contents then
			LocalPlayer():ChatPrint("warning: failed to include `" .. f .. "'")
			return ""
		end
	end
	
	local start,endp = string.find(contents, "#include \"[%a\\.\\\\\\/_0-9]+\"")
	
	
	while start != nil do
		local found = string.sub(contents, start, endp)
		
		local fname = string.sub(contents, start + string.len("#include '"), endp-1)
		print("including " .. fname)
		local fileconts = ParseCodeFile(fname, done_files, f, file_offsets)
		
		// save the positions of the file offsets, when we go into a file, mark it as so, and when we come back out of it, again, mark it as so
		// this can be used to fix the error messages later on!
		table.insert(file_offsets, {name = fname, pos = string.len(contents)})
		contents = string.Replace(contents, found, fileconts)
		table.insert(file_offsets, {name = (f or "root"), pos = string.len(contents)})
		
		-- line below is for testing...
		-- if true then break end
		start,endp = string.find(contents, "#include \"[%a\\.\\\\\\/_0-9]+\"")
	end
	
	return contents
end

local DebugInfo = {}

function GetRelativeErrorPosition(fname, line)
	if DebugInfo[fname] == nil then
		return "no debug info for file " .. fname, line
	end
	
	local code, offsets = unpack(DebugInfo[fname])
	local curline = 0
	local position = nil
	
	for i = 1, string.len(code) do
		local char = code[i]
		
		if char == '\n' then
			curline = curline + 1
			
			if curline == line then
				position = i
				break
			end
		end
	end
	
	if position == nil then return "nope.avi (EOF)", 0 end
		
	local start = nil
	
	print(position)
	PrintTable(offsets)
	
	// now we have the position of that line, lets attempt to locate the file it falls under...
	for k,v in pairs(offsets) do
		if v.pos > position then
			break
		end
		
		start = v
	end
	
	// now find out what line pos resides on
	local newline_count = 0
	for i = start.pos, position do
		if code[i] == '\n' then
			newline_count = newline_count + 1
		end
	end
	
	return start.name, newline_count
end

function TOOL:RightClick(trace)
	if SERVER then return false end
	
	if not IsFirstTimePredicted() then return end
	
	local f = self:GetClientInfo("file")
	local file_offsets = {}
	
	table.insert(file_offsets, {pos = 1, name = f})
	local code = ParseCodeFile(f, {}, nil, file_offsets)
	
	DebugInfo[f] = {code, file_offsets}
	
	
	net.Start("sandbox_upload")
		net.WriteString(f)
		net.WriteString(code)
	net.SendToServer()
	
	return false
end

function TOOL:RightClick_Old( trace )
	
	if ( IsValid( trace.Entity ) && trace.Entity:IsPlayer() ) then return false end
	
	if CLIENT then
		// semd the server the code
		return true
	end
	
	local model				= self:GetClientInfo( "model" )
	local filename			= self:GetClientInfo( "file" )
	
	if IsValid(trace.Entity) and trace.Entity.Owner == self:GetOwner() and trace.Entity:GetClass() == "ei_sandbox" then
		local code = (self:GetOwner().Programs or {})[filename]
	
		if code == nil then
			self:GetOwner():ChatPrint("That file hasn't been uploaded yet!")
			return false
		end
		
		trace.Entity:Setup(code)
		
		return true
	end
	
	if ( !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	local ply = self:GetOwner()
	
	if ( !self:GetSWEP():CheckLimit( "sandbox" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		-- Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local code = (self:GetOwner().Programs or {})[filename]
	
	if code == nil then
		self:GetOwner():ChatPrint("That file hasn't been uploaded yet!")
		return false
	end
	
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

	local bool, chip, set_key = self:RightClick_Old( trace, true )
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
	
	duplicator.RegisterEntityClass( "ei_sandbox", MakeSandbox, "Model", "Ang", "Pos", "code", "frozen" )

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

