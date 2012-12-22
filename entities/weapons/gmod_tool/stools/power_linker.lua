
TOOL.Category		= "Endure It"
TOOL.Name			= "Power Linker"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["linkname"] = ""

if CLIENT then
	language.Add("tool.power_linker.name", "Power Linker")
	language.Add("tool.power_linker.desc", "Create a power link (very short)")
	language.Add("tool.power_linker.0", "Left click:  link to; right click: select entity; reload: clear")
end

function TOOL:LeftClick( trace )
	if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsWorld() then return false end
	if trace.Entity.PowerSources == nil then return false end
	if not IsValid(self.PowerTo) then return false end
	
	for k,v in pairs(self.PowerTo.PowerSources) do
		if v == trace.Entity then
			return true
		end
	end
	
	table.insert(self.PowerTo.PowerSources, trace.Entity)
	return true
end

function TOOL:RightClick( trace )
	if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsWorld() then return false end
	
	if trace.Entity.PowerSources == nil then return false end
	
	self.PowerTo = trace.Entity
	
	return true
end

function TOOL:Reload( trace )
	if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsWorld() then return false end
	
	if trace.Entity.PowerSources == nil then return false end
	
	trace.Entity.PowerSources = {}
end

function TOOL:Think()

	
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl("Header", { Text = "Power Linker", Description	= "Link entities to a power source" })
end
