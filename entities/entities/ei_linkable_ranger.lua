
AddCSLuaFile()

ENT.PrintName		= "Ranger"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE
ENT.Base			= "ei_linkable_ent"

ENT.Model 			= "models/jaanus/wiretool/wiretool_range.mdl"
ENT.Thrust			= 0
ENT.Enabled 		= 0

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

function ENT:Initialize()
	self.BaseClass.Initialize(self)
end


function ENT:Draw()
	self.BaseClass.Draw( self )
end

function ENT:Think()
	self.BaseClass.Think( self )

end

function ENT:OnTakeDamage( dmginfo )
end

function ENT:GetLinkTable()
	return {
		Query = function(chip, x, y, onlymetal)
			if not chip:GetJoules(0.5) then return 1000000 end
			
			x = x or 0
			y = y or 0
						
			local trace = {}
			trace.start = self:GetPos() + self:GetUp() * 2
			
			local ang = self:GetUp():Angle()
			
			ang:RotateAroundAxis(self:GetRight(), x / 1.325)
			ang:RotateAroundAxis(self:GetForward(), y / 1.325)
			
			trace.endpos = trace.start + ang:Forward() * 1000000
			
			trace.filter = { self }
			local tr = util.TraceLine(trace)
			
			if tr.HitSky or (tr.HitWorld and onlymetal) then
				debugoverlay.Line(trace.start, tr.HitPos, 0.25)
				return 1000000
			end
			
			for k,v in pairs(ents.FindByClass("ei_linkable_geigercounter")) do
				local dist = v:GetPos():Distance(tr.HitPos)
				
				local rand = 0 //math.random(0, 10)
				
				if math.random(0, dist) < 250 then
					rand = 1
				end
				
				dist = v:GetPos():Distance(trace.start)
				
				rand = math.Clamp(rand, 0, 1)
				
				if rand != 0 and math.random(0, dist) > 5000 then
					rand = 0
				end
				
				print(rand)
				v.Counts = v.Counts + rand
				
				if rand >= 1 then
					if rand <= 3 then
						v:EmitSound("player/geiger" .. rand .. ".wav")
					else
						v:EmitSound("player/geiger" .. math.random(1, 3) .. ".wav")
					end
				end
			end
			
			debugoverlay.Line(trace.start, tr.HitPos, 0.25)
			
			return (trace.start - tr.HitPos):Length()
		end
	}
end