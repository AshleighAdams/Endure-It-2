Space = {}
Space.Planets = {}
Space.LastThink = CurTime()
Space.BadClasses = {viewmodel = true}

local BasePlanet = {}
BasePlanet.Name = "Earth"
BasePlanet.Gravity = math.Round(9.8 / 0.01633333333)
BasePlanet.Position = Vector(0, 0, 0)
BasePlanet.Radius = 10000
BasePlanet.Temperature = 20
BasePlanet.Atmosphere = {
	O2 = 20.946, N2 = 78.084, Ar = 0.9340, CO2 = 0.035, Ne = 0.001818,
	He = 0.00524, CH4 = 0.0001745, Kr = 0.000114, H2 = 0.000055
}

function Planet(name)
	local planet = {Name = name}
	Space.Planets[name] = planet
	
	return setmetatable(planet, {__index = BasePlanet})
end

function Space:Spacify(ent)
	if not IsValid(ent) then return end
	print("s", ent)
	if CLIENT then return end
	
	ent:SetGravity(0)
	
	local po = ent:GetPhysicsObject()
	
	if IsValid(po) then
		po:EnableGravity(false)
		po:EnableDrag(false)
	end
end

function Space:Planetify(ent, planet)
	if not IsValid(ent) then return end
	
	print("p", ent, planet.Gravity)
	
	ent:SetGravity(planet.Gravity)
	
	local po = ent:GetPhysicsObject()
	
	if IsValid(po) then
		po:EnableGravity(true)
		po:EnableDrag(true)
	end
end

function Space:Think()
	local t = CurTime() - self.LastThink
	self.LastThink = CurTime()
	
	for k,v in pairs(ents.GetAll()) do
		if self.BadClasses[v:GetClass()] == true then return end
		
		if v.CurrentPlanet then
			
			-- Are we still on the planet?  If so, then just return
			local dist = ( (v.GetShootPos or v.GetPos)(v) - v.CurrentPlanet.Position ):Length()
			
			if dist > v.CurrentPlanet.Radius then
				-- Yup, we're not on this planet anymore; lets spacify them
				self:Spacify(v)
				v.CurrentPlanet = nil
				continue
			end
			
			-- Simulate gravity as it seems to be broken...
			if not v:IsPlayer() then
				local po  = v:GetPhysicsObject()
				
				if IsValid(po) and not po:IsAsleep() then
					po:ApplyForceCenter(Vector(0, 0, v.CurrentPlanet.Gravity) * t * po:GetMass() * -1)
				end
			end
			
		else
		
			-- Check if we're in a planet, but only if we last checked >0.2 seconds ago
			if CurTime() > (v.NextPlanetThink or 0) then
				v.NextPlanetThink = CurTime() + 0.2
				
				for pn,p in pairs(self.Planets) do
					local dist = ( (v.GetShootPos or v.GetPos)(v) - p.Position ):Length()
					
					if dist < p.Radius then
						self:Planetify(v, p)
						v.CurrentPlanet = p
						
						break
					end
				end
			end
			
		end
	end
end

local Earth		 = Planet("Earth")
Earth.Position	 = Vector(-9727, -6144, -8162)
Earth.Radius	 = 4812

local Mercury		 = Planet("Mercury")
Mercury.Position	 = Vector(0, 0, 4580)
Mercury.Radius		 = 1122
Mercury.Temperature	 = 630
Mercury.Gravity		 = math.Round(3.7 / 0.01633333333)

local Mars		 = Planet("Mars")
Mars.Position	 = Vector(1514, 7663, -10236)
Mars.Temperature = -55
Mars.Radius	 	 = 3060
Mars.Gravity	 = math.Round(3.711 / 0.01633333333)

local Venus		 = Planet("Venus")
Venus.Position	 = Vector(8192, -10240, -2128)
Venus.Temperature = 462
Venus.Radius	 = 4860
Venus.Gravity	 = math.Round(8.87 / 0.01633333333)

local Saturn		 = Planet("Venus")
Saturn.Position		 = Vector(-8192, 8703, 10104)
Saturn.Temperature	 = -150
Saturn.Radius		 = 3316
Saturn.Gravity		 = math.Round(10.44 / 0.01633333333)

