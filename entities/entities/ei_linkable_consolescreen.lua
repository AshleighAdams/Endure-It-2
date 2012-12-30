AddCSLuaFile()

ENT.PrintName		= "Console Screen"
ENT.Author			= "victormeriqui"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_BOTH
ENT.Base			= "ei_linkable_ent"

ENT.Model 			= "models/props_phx/construct/glass/glass_plate1x1.mdl"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

if CLIENT then
surface.CreateFont( "EI_Console", {
	font 		= "lucida console",
	size 		= 10, -- TODO: Get size later
	weight 		= 500,
	blursize 	= 0,
	scanlines 	= false,
	antialias 	= false,
	underline 	= false,
	italic 		= false,
	strikeout 	= false,
	symbol 		= false,
	rotary 		= false,
	shadow 		= false,
	additive 	= false,
	outline 	= false
} )
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	if CLIENT then
		self.ToDo = {}
		self.RT = GetRenderTargetEx("EI_GPU_RT_512_" .. self:EntIndex(), 512, 512,
			0 /*index*/, 0/*sizemode*/, 1/*text flags*/, 0/*rtflags*/, 0/*image format*/)
		render.ClearRenderTarget(self.RT, Color(0, 0, 0, 255))
	end
end

if CLIENT then
	ENT.ScreenMat = CreateMaterial("EI_RT_PROXY","UnlitGeneric",{
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
		["$ignorez"] = 1,
		["$nolod"] = 1,
	})
end

if SERVER then
	util.AddNetworkString("Console_DrawText")
	util.AddNetworkString("Console_Clear")
end

if CLIENT then
	function Console_DrawText()
		local self = net.ReadEntity()
		local str = net.ReadString()
		local x = net.ReadUInt(8)
		local y = net.ReadUInt(8)
		local col = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
		local bgcol = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
		
		self.ToDo = self.ToDo or {}
		table.insert(self.ToDo,{What=str, Col = col, BGCol = bgcol, X = x,Y = y})
	end
	net.Receive("Console_DrawText", Console_DrawText)
	
	function Console_Clear()
		local self = net.ReadEntity()
		local col = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
		
		self.ToDo = {}
		render.ClearRenderTarget(self.RT, col)
	end
	net.Receive("Console_Clear", Console_Clear)
end

function ENT:DrawTranslucent()
	self.ToDo = self.ToDo or {}
	local sw = ScrW()
	local sh = ScrH()

	local OldRT = render.GetRenderTarget()
	render.SetRenderTarget(self.RT)
	
	render.SetViewPort(0, 0, 512, 512)
	local factor = 512/64
	cam.Start2D()
		if #self.ToDo != 0 then
			surface.SetFont("EI_Console")
			
			for k,v in pairs(self.ToDo) do
				surface.SetTextColor(v.Col.r, v.Col.g, v.Col.b, v.Col.a)
				
				local str = v.What
				local len = string.len(v.What)
				local x,y = v.X * factor, v.Y * factor
				
				x = x + factor
				y = y + factor
				
				for i = 1, len do
					local c = str[i]
					
					surface.SetDrawColor(v.BGCol.r, v.BGCol.g, v.BGCol.b, v.BGCol.a)
					surface.DrawRect(x, y, factor, factor)
					
					local w,h = surface.GetTextSize("H")
					
					surface.SetTextPos(x + factor / 2 - w / 2, y + factor / 2 - h / 2)
					surface.DrawText(c)
					// Post draw
					x = x + factor
					if x >= 512 then
						x = 0
						y = y + factor
					end
				end
			end
			
			self.ToDo = {}
		end
	cam.End2D()
	
	render.SetViewPort(0, 0, sw, sh)
	render.SetRenderTarget(OldRT)
	
	local pop = self.ScreenMat:GetTexture("$basetexture")
	self.ScreenMat:SetTexture("$basetexture", self.RT)
	
	local scale = 5.5
	
	cam.Start3D2D(self:GetPos() + self:GetAngles():Up() * 0.5, self:GetAngles(), 1)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(self.ScreenMat)
		surface.DrawTexturedRect(-256 / scale / 2, -256 / scale / 2, 256 / scale, 256 / scale)
	cam.End3D2D()
	
	self.BaseClass.Draw( self )
	
	self.ScreenMat:SetTexture("$basetexture", pop)
end

function ENT:Think()
	self.BaseClass.Think( self )
end

function ENT:OnTakeDamage( dmginfo )
end

function ENT:GetLinkTable()
	return {
		Draw = function(chip, what, x, y, col, bgcol)
			if not chip:GetJoules(2) then return end
			bgcol = bgcol or Color(0, 0, 0, 0)
			col = col or Color(255, 255, 255, 255)
			
			net.Start("Console_DrawText")
				net.WriteEntity(self)
				net.WriteString(what)
				net.WriteUInt(x, 8)
				net.WriteUInt(y, 8)
				net.WriteUInt(col.r, 8)
				net.WriteUInt(col.g, 8)
				net.WriteUInt(col.b, 8)
				net.WriteUInt(col.a, 8)
				net.WriteUInt(bgcol.r, 8)
				net.WriteUInt(bgcol.g, 8)
				net.WriteUInt(bgcol.b, 8)
				net.WriteUInt(bgcol.a, 8)
			net.Broadcast()
			
		end,
		Clear = function(chip, col)
			if not chip:GetJoules(2) then return end
			col = col or Color(0, 0, 0, 255)
			
			net.Start("Console_Clear")
				net.WriteEntity(self)
				net.WriteUInt(col.r, 8)
				net.WriteUInt(col.g, 8)
				net.WriteUInt(col.b, 8)
				net.WriteUInt(col.a, 8)
			net.Broadcast()
		end
	}
end