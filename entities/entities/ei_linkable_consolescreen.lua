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
	font 		= "Arial",
	size 		= 10, -- TODO: Get size later
	weight 		= 500,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= true,
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
		self.RT = GetRenderTarget("EI_GPU_RT_512_" .. self:EntIndex(), 512, 512)
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

if CLIENT then
	function Console_DrawText( um )
		local self = um:ReadEntity()
		local str = um:ReadString()
		local x = um:ReadShort()
		local y = um:ReadShort()
		local col = um:ReadVector()
		col = Color(col.x, col.y, col.z)
		
		local bgcol = um:ReadVector()
		bgcol = Color(bgcol.x, bgcol.y, bgcol.z)
		
		self.ToDo = self.ToDo or {}
		table.insert(self.ToDo,{What=str, Col = col, BGCol = bgcol, X = x,Y = y})
	end
	usermessage.Hook("Console_DrawText", Console_DrawText)
	
	function Console_Clear( um )
		local self = um:ReadEntity()
		
		render.ClearRenderTarget(self.RT, Color(0, 0, 0, 255))
	end
	usermessage.Hook("Console_Clear", Console_Clear)
end

function ENT:Draw()
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
				surface.SetDrawColor(v.Col.r, v.Col.g, v.Col.b, 255)
				local str = v.What
				local len = string.len(v.What)
				local x,y = v.X * factor, v.Y * factor
				
				x = x + factor
				y = y + factor
				
				for i = 1, len do
					local c = str[i]
					
					surface.SetDrawColor(v.BGCol.r, v.BGCol.g, v.BGCol.b, 255)
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
	
	cam.Start3D2D(self:GetPos() + self:GetAngles():Up() * 3, self:GetAngles(), 1)
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
			if not chip:GetWatts(0.5) then return end
			umsg.Start( "Console_DrawText" )
				umsg.Entity(self)
				umsg.String(what)
				umsg.Short(x)
				umsg.Short(y)
				umsg.Vector(Vector(col.r, col.g, col.b))
				umsg.Vector(Vector(bgcol.r, bgcol.g, bgcol.b))
			umsg.End()
			
		end,
		Clear = function(chip)
			if not chip:GetWatts(0.5) then return end
			
			umsg.Start( "Console_Clear" )
				umsg.Entity(self)
			umsg.End()
		end
	}
end