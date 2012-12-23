AddCSLuaFile()

ENT.PrintName		= "Base Power Source"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "Base ent for power sources"
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Linkable		= true
ENT.Base 			= "ei_linkable_ent"
ENT.Model 			= "models/props_lab/huladoll.mdl"
ENT.Capacity		= 1000 -- 1 kW
ENT.Bandwidth		= 50 -- can draw 50joule/sec
ENT.EI_Power		= true
ENT.EndPoint		= true

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:MaxJoule()
	if self.EndPoint then
		
		if self.JoulesCache < self.Bandwidth then
			return self.JoulesCache
		end
	
		if self.Joules <= 0 then
			self.Joules = 0
			return 0
		end
	
		return self.Bandwidth
	end
	
	local sources = {}
	BuildPowerTable(self, 0, sources, {})
	
	local totaljoule = 0
	
	for k,src in pairs(sources) do
		if not IsValid(src) then continue end
		
		totaljoule = totaljoule + src:MaxJoule(true, done) /* returns the bandwidth, or the avaibible power if less than bandwidth */
	end
	
	return totaljoule
end

function ENT:TakeJoules(amm)
	if self.Joules != self.Joules then self.Joules = 0 end
	if self.JoulesCache != self.JoulesCache then self.JoulesCache = 0 end
	
	self.Joules = self.Joules - amm
	self.JoulesCache = self.JoulesCache - amm
	
	self.Drawn = (self.Drawn or 0) + amm
end

function ENT:AddJoules(amm)
	if self.Joules != self.Joules then self.Joules = 0 end
	
	self.Joules = self.Joules + amm
	
	self.Charged = (self.Charged or 0) + amm
end

function BuildPowerTable(ent, depth, ret, done)
	if not IsValid(ent) then return end
	
	if depth > 16 then
		ErrorNoHalt("Warning: max depth hit!")
		return
	end
	
	if done[ent] then return end
	done[ent] = true
	
	if ent.EndPoint then
		table.insert(ret, ent)
		return
	end

	for k,v in pairs(ent.PowerSources) do
		BuildPowerTable(v, depth + 1, ret, done)
	end
end

function ENT:GetJoules(joule)
	if self.Joules != self.Joules then self.Joules = 0 end
	if self.JoulesCache != self.JoulesCache then self.JoulesCache = 0 end
	
	if self.EndPoint then
		if self:MaxJoule() < joule then return false end
	
		self:TakeJoules(joule)
		
		return true
	end
	
	local sources = {}
	BuildPowerTable(self, 0, sources, {})
	
	local totaljoule = 0
	
	for k,src in pairs(sources) do
		if not IsValid(src) then continue end
		
		totaljoule = totaljoule + src:MaxJoule(true, done) /* returns the bandwidth, or the avaibible power if less than bandwidth */
	end
	
	if totaljoule < joule then
		return false
	end
	
	
	for k,src in pairs(sources) do
		if not IsValid(src) then continue end
		
		local max = src:MaxJoule(true, done)
		local percent = max / totaljoule
		local joule_used = joule * percent
		
		src:GetJoules(joule_used, nil, done)
	end
	
	return true
end

function ENT:GetPowerSources()
	return self.PowerSources
end

function ENT:Initialize()
	self.BaseClass.BaseClass.Initialize(self)
	
	self.Joules = 0
	self.JoulesCache = 0
	self.PowerSources = {} -- For parents, such as batteries on batteries
	
	self.LastThink = CurTime()
end

function ENT:MakeNicePower(val)
	local postfixes = {
		"uJ",
		"mJ",
		"J",
		"kJ",
		"MJ",
		"GJ",
		"TJ",
		"PJ"
	}
	
	if not val then return "0J" end
	
	local val =  val * 1000 * 1000 -- start at uW
	local postfix = 1
		
	while math.abs(val) > 1000 do
		if postfix == table.Count(postfixes) then break end
		val = val / 1000
		postfix = postfix + 1
	end
	return tostring(math.Round(val * 100) / 100) .. postfixes[postfix]
end

function ENT:Think()
	if self.Joules != self.Joules then self.Joules = 0 end
	if self.JoulesCache != self.JoulesCache then self.JoulesCache = 0 end
	
	self.BaseClass.BaseClass.Think(self)
	if CLIENT then return end
	
	if not self.NextUpdateText or CurTime() > self.NextUpdateText then
		local drawn = self.Drawn
		self.Drawn = 0
		
		local charge = self.Charged
		self.Charged = 0
		
		self:SetOverlayText(self:MakeNicePower(self.Joules) .. "\nDraw: " .. self:MakeNicePower(drawn) .. "\nCharge: " .. self:MakeNicePower(charge) )
		self.NextUpdateText = CurTime() + 1
		self.LastJoules = self.Joules
	end
	
	local t = CurTime() - self.LastThink
	self.LastThink = CurTime()
	
	self.JoulesCache = self.JoulesCache + self.Bandwidth * t
	self.JoulesCache = math.Clamp(self.JoulesCache, 0, math.min(self.Joules, self.Bandwidth))
	
	if self.Joules >= self.Capacity then return end
	
	-- ok, lets charge the battery from other sources
	local joule = math.min(self.Bandwidth, self.Capacity - self.Joules) * t
	--print(self.Bandwidth, joule)
	
	local got = self:Charge(self:GetPowerSources(), joule, false)
	
	self:AddJoules(got)
end

function ENT:Charge(srcs, joule, exact)

	local totaljoule = 0
	for k,src in pairs(srcs) do
		if not IsValid(src) then continue end
		totaljoule = totaljoule + src:MaxJoule() /* returns the bandwidth, or the avaibible power if less than bandwidth */
	end
	
	if totaljoule < joule then
		if exact then return 0 end
		
		joule = totaljoule
	end
	
	if totaljoule == 0 then return 0 end
	
	local ret = 0
	for k,src in pairs(srcs) do
		if not IsValid(src) then continue end
		
		local max = src:MaxJoule() 
		local percent = max / totaljoule
		local joule_used = joule * percent
		
		src:GetJoules(joule_used)
		
		ret = ret + joule_used
	end
	return ret
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmginfo)
end

function ENT:GetLinkTable()
	return {
		Capacity = function(self)
			return self.Capacity
		end,
		Bandwidth = function(self)
			return self.Bandwidth
		end,
		Charge = function(self)
			return self.Joules
		end
	}
end