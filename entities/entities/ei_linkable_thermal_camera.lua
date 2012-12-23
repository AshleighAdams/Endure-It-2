
AddCSLuaFile()

ENT.PrintName		= "Thermal Camera"
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
	self:SetColor(Color(255,127,127))
end


function ENT:Draw()
	self.BaseClass.Draw( self )
end

function ENT:Think()
	self.BaseClass.Think( self )

end

function ENT:OnTakeDamage( dmginfo )
end

function cam_ToScreen( camPos, camAng, camFov, scrW, scrH, vec )
    local vDir = camPos - vec
      
    local fdp = camAng:Forward():Dot( vDir )
  
    if ( fdp == 0 ) then
        return 0, 0, false, false
    end
     
    local d = 4 * scrH / ( 6 * math.tan( math.rad( 0.5 * camFov ) ) ) 
    local vProj = ( d / fdp ) * vDir
      
    local x = 0.5 * scrW + camAng:Right():Dot( vProj )
    local y = 0.5 * scrH - camAng:Up():Dot( vProj )
      
    return x, y, ( 0 < x && x < scrW && 0 < y && y < scrH ) && fdp < 0, fdp > 0
end

function ENT:GetLinkTable()
	return {
		Query = function(chip, fov, resx, resy)
			if not chip:GetJoules((resx * resy) / 400) then return end /* 64x64 = 1W */
			
			local ret = {}
			
			for x = 0, resy do
				ret[x] = {}
				for y = 0, resx do
					
					ret[x][y] = 0
				end
			end
			
			local camang = self:GetAngles()
			camang:RotateAroundAxis(self:GetRight(), 90)
			
			local selfpos = self:GetPos() + camang:Forward() * 2
			
			for k,v in pairs(ents.GetAll()) do
				if v:GetClass() == "prop_physics" or v:IsPlayer() or string.StartWith(v:GetClass(), "ei_") then
					local pos = v:GetPos()
					local phy = v:GetPhysicsObject()
					
					if IsValid(phy) then
						pos = v:LocalToWorld(phy:GetMassCenter())
					end
					
					
					
					debugoverlay.Line(selfpos, selfpos + camang:Forward() * 10, 2)
					
					local x, y, onscreen = cam_ToScreen(selfpos, camang, fov, resx, resy, v:GetPos())
					--print(x, y, onscreen)
					if not onscreen then continue end
					
					local trace = {}
					trace.start = selfpos
					trace.endpos = pos
					trace.mask = MASK_SOLID_BRUSHONLY
					
					
					local tr = util.TraceLine(trace)
					
					if tr.Hit then continue end
					
					local size = (v:OBBMaxs() - v:OBBMins()):Length()
					local dist =  (pos-selfpos):Length()
					size = (1/math.log10(dist) * size) / fov -- approx
										
					for xx = math.Round(x - size/2), math.Round(x + size / 2) do
						for yy = math.Round(y - size/2), math.Round(y + size / 2) do
							
							if xx < 0 or yy < 0 then continue end
							if xx > resx or yy > resy then continue end
							
							if ret[xx][yy] != nil then
								ret[xx][yy] = ret[xx][yy] + math.Round((5000 / dist) * size)
							end
						end
					end
					
				end
			end
			
			return ret
		end
	}
end
