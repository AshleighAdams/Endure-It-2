
AddCSLuaFile()

ENT.PrintName		= "Oscilloscope"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_BOTH
ENT.Base			= "ei_linkable_ent"

ENT.Model 			= "models/props_phx/construct/glass/glass_plate1x1.mdl"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	if CLIENT then
		self.RT = GetRenderTarget("EI_GPU_RT_512_" .. self:EntIndex(), 512, 512)
		render.ClearRenderTarget(self.RT, Color(0, 0, 0, 0))
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
	function Oscilloscope_Line( um )
		
		local self = um:ReadEntity()
		local x1 = -um:ReadFloat()
		local y1 = -um:ReadFloat()
		local x2 = self.LastX or 0
		local y2 = self.LastY or 0
		local perc = um:ReadFloat()
		
		self.LastX = x1
		self.LastY = y1
		
		if not IsValid(self) then return end
		
		if self.LinesBuffer == nil then
			self.LinesBuffer = {}
		end
		
		table.insert(self.LinesBuffer, {
			x1 = x1,
			y1 = y1,
			x2 = x2,
			y2 = y2,
			perc = perc
		})
	end
	usermessage.Hook("Oscilloscope_Line", Oscilloscope_Line)
	
	function Oscilloscope_Clear( um )
		local self = um:ReadEntity()
		render.ClearRenderTarget(self.RT, Color(0, 0, 0, 0))
	end
	usermessage.Hook("Oscilloscope_Clear", Oscilloscope_Clear)
end

function ENT:Draw()
	self.LinesBuffer = self.LinesBuffer or {}
	
	local sw = ScrW()
	local sh = ScrH()

	local OldRT = render.GetRenderTarget()
	render.SetRenderTarget(self.RT)
	
	render.SetViewPort(0, 0, 512, 512)
	cam.Start2D()
		surface.SetDrawColor(0, 0, 0, self:GetNWFloat("decay", 500) * FrameTime())
		--render.ClearRenderTarget(self.RT, Color(0, 0, 0, 1))
		surface.DrawRect(0, 0, 512, 512) -- Fade out over time
		
		if #self.LinesBuffer != 0 then
			for k,v in pairs(self.LinesBuffer) do
				surface.SetDrawColor(0, 255, 0, 255 * v.perc )
				surface.DrawLine(
					256 * v.x1 + 256,
					256 * v.y1 + 256,
					256 * v.x2 + 256,
					256 * v.y2 + 256
				)
			end
			
			self.LinesBuffer = {}
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
		Draw = function(x, y, intensity)
			x = x or 0
			y = y or 0
			self.LastX = self.LastX or x
			self.LastY = self.LastY or y
			
			intensity = intensity or 1
			
			umsg.Start( "Oscilloscope_Line" )
				umsg.Entity(self)
				umsg.Float(math.Clamp(x, -1, 1))
				umsg.Float(math.Clamp(y, -1, 1))
				umsg.Float(math.Clamp(intensity, 0, 1))
			umsg.End()
			
			self.LastX = x
			self.LastY = y
		end,
		SetDecay = function(val)
			self:SetNWFloat("decay", val)
		end,
		Clear = function()
			umsg.Start( "Oscilloscope_Clear" )
				umsg.Entity(self)
			umsg.End()
		end
	}
end