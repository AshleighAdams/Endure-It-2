
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

function TOOL:RightClick( trace )

	return false

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
	
	return true
end

function TOOL:Think()

	
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl("Header", { Text = "Sandbox CPU Linker", Description	= "Link the sandbox to an entity" })
	
	CPanel:AddControl( "TextBox", { Label = "Link Name",
		MaxLenth = "20",
		Command = "sandbox_linker_linkname" } )
end