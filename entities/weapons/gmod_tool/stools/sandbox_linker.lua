
TOOL.Category		= "Endure It"
TOOL.Name			= "Sandbox Linker"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["linkname"] = ""

if CLIENT then
	language.Add("tool.sandbox_linker.name", "Sandbox Linker")
	language.Add("tool.sandbox_linker.desc", "Create a sandbox CPU link.")
	language.Add("tool.sandbox_linker.0", "Left click to create")
end

if CLIENT then
	function TOOL:RightClick( trace )
		if not IsFirstTimePredicted() then return end
		
		self:ScrollDown(trace)
		return false

	end
end

function TOOL:LeftClick( trace )
	if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsWorld() then return false end
	
	if not IsValid(self.Chip) and trace.Entity:GetClass() != "ei_sandbox" then return false end
	
	if self.Chip == nil then
		self.Chip = trace.Entity
		return true
	end
	
	if not trace.Entity.Linkable then return false end
		
	local chip = self.Chip
	self.Chip = nil
	
	if CLIENT then return true end
	
	local name = self:GetClientInfo("linkname")
	
	local link = chip.Links[name]
		
	if not link then
		self:GetOwner():ChatPrint("Can't find the link for `" .. name .. "'!")
		return false
	end
	
	link.Entity = trace.Entity
	link.CreationDistance = (link.Entity:GetPos() - trace.Entity:GetPos()):Length()
	
	self:GetOwner():ChatPrint("Created link!")
	
	chip:SendUpdatedLinkTable()
	
	return true
end

function TOOL:Reload( trace )
		if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsWorld() then return false end
	
	if not IsValid(self.Chip) and trace.Entity:GetClass() != "ei_sandbox" then return false end
	
	if self.Chip == nil then
		self.Chip = trace.Entity
		return true
	end
	
	if not trace.Entity.Linkable then return false end
		
	local chip = self.Chip
	self.Chip = nil
	
	if CLIENT then return true end
	
	local name = self:GetClientInfo("linkname")
	
	local link = chip.Links[name]
	
	if link then
		link.Entity = nil
		chip:SendUpdatedLinkTable()
	end
end

function TOOL:DrawHUD()
	self.Scroller = self.Scroller or 0
	
	
	local tr = LocalPlayer():GetEyeTrace()
	if not IsValid(tr.Entity) then return end
	
	if tr.Entity:GetClass() != "ei_sandbox" then return end
	
	local links = tr.Entity.Links
	if not links then return end
	
	local count = table.Count(links)
	self.Scroller = self.Scroller % count
	
	local i = 0
	for k,v in pairs(links) do
		local col = Color(255,255,255,127)
		
		if IsValid(v.Entity) then
			col = Color(0,255,0,127)
		end
		
		if self.Scroller != self.Scroller then
			self.Scroller = 0
		end
		
		if i == self.Scroller then
			col.a = 255
			
			if self.LastScrolled != k then
				self.LastScrolled = k
				RunConsoleCommand("sandbox_linker_linkname", k)
			end
		end
		
		draw.SimpleText(k, "ChatFont", ScrW() / 2 + 20, ScrH() / 2 + 20 + i * 20, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		i = i + 1
	end
end

function TOOL:Think()

	
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl("Header", { Text = "Sandbox CPU Linker", Description	= "Link the sandbox to an entity" })
	
	CPanel:AddControl( "TextBox", { Label = "Link Name",
		MaxLenth = "20",
		Command = "sandbox_linker_linkname" } )
end

function TOOL:ScrollUp(trace)
	if trace.Entity:GetClass() != "ei_sandbox" then return end
	
	self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")
	
	self.Scroller = self.Scroller or 0
	self.Scroller = self.Scroller - 1
	
	return true
end

function TOOL:ScrollDown(trace)
	if trace.Entity:GetClass() != "ei_sandbox" then return end
	
	self:GetOwner():EmitSound("weapons/pistol/pistol_empty.wav")
	
	self.Scroller = self.Scroller or 0
	self.Scroller = self.Scroller + 1
	
	return true
end

if CLIENT then // Taken from WireMod's linker

	local bind_mappings = {
		["invprev" ] = { "ScrollUp" },
		["invnext" ] = { "ScrollDown" },
	}
	local weapon_selection_close_time = 0

	local function open_menu()
		weapon_selection_close_time = CurTime()+6
	end

	local function close_menu()
		weapon_selection_close_time = 0
	end

	local bind_post = {
		invnext = open_menu,
		invprev = open_menu
	}
	
	
	local function get_active_tool(ply, tool)
		-- find toolgun
		local activeWep = ply:GetActiveWeapon()
		if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end

		return activeWep:GetToolObject(tool)
	end
	
	hook.Add("PlayerBindPress", "sandbox_link", function(ply, bind, pressed)
		if not pressed then return end
		--if true then return true end
		local self = get_active_tool(ply, "sandbox_linker")
		if not self then return end
		
		if bind == "invprev" then
			return self:ScrollUp(LocalPlayer():GetEyeTrace())
		elseif bind == "invnext" then
			return self:ScrollDown(LocalPlayer():GetEyeTrace())
		end
	end)

end