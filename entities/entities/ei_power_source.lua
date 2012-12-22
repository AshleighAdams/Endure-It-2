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
ENT.Bandwidth		= 50 -- can draw 50watt/sec
ENT.EI_Power		= true
ENT.EndPoint		= true

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:MaxWatt()
	if self.EndPoint then
		
		if self.WattsCache < self.Bandwidth then
			return self.WattsCache
		end
	
		if self.Watts <= 0 then
			self.Watts = 0
			return 0
		end
	
		return self.Bandwidth
	end
	
	local sources = {}
	BuildPowerTable(self, 0, sources, {})
	
	local totalwatt = 0
	
	for k,src in pairs(sources) do
		if not IsValid(src) then continue end
		
		totalwatt = totalwatt + src:MaxWatt(true, done) /* returns the bandwidth, or the avaibible power if less than bandwidth */
	end
	
	return totalwatt
end

function ENT:TakeWatts(amm)
	if self.Watts != self.Watts then self.Watts = 0 end
	if self.WattsCache != self.WattsCache then self.WattsCache = 0 end
	
	self.Watts = self.Watts - amm
	self.WattsCache = self.WattsCache - amm
	
	self.Drawn = (self.Drawn or 0) + amm
end

function ENT:AddWatts(amm)
	if self.Watts != self.Watts then self.Watts = 0 end
	
	self.Watts = self.Watts + amm
	
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

function ENT:GetWatts(watt)
	if self.Watts != self.Watts then self.Watts = 0 end
	if self.WattsCache != self.WattsCache then self.WattsCache = 0 end
	
	if self.EndPoint then
		if self:MaxWatt() < watt then return false end
	
		self:TakeWatts(watt)
		
		return true
	end
	
	local sources = {}
	BuildPowerTable(self, 0, sources, {})
	
	local totalwatt = 0
	
	for k,src in pairs(sources) do
		if not IsValid(src) then continue end
		
		totalwatt = totalwatt + src:MaxWatt(true, done) /* returns the bandwidth, or the avaibible power if less than bandwidth */
	end
	
	if totalwatt < watt then
		return false
	end
	
	
	for k,src in pairs(sources) do
		if not IsValid(src) then continue end
		
		local max = src:MaxWatt(true, done)
		local percent = max / totalwatt
		local watt_used = watt * percent
		
		src:GetWatts(watt_used, nil, done)
	end
	
	return true
end

function ENT:GetPowerSources()
	return self.PowerSources
end

function ENT:Initialize()
	self.BaseClass.BaseClass.Initialize(self)
	
	self.Watts = 0
	self.WattsCache = 0
	self.PowerSources = {} -- For parents, such as batteries on batteries
	
	self.LastThink = CurTime()
end

function ENT:MakeNicePower(val)
	local postfixes = {
		"uW",
		"mW",
		"W",
		"kW",
		"MW",
		"GW",
		"TW",
		"PW"
	}
	
	if not val then return "0uW" end
	
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
	if self.Watts != self.Watts then self.Watts = 0 end
	if self.WattsCache != self.WattsCache then self.WattsCache = 0 end
	
	self.BaseClass.BaseClass.Think(self)
	if CLIENT then return end
	
	if not self.NextUpdateText or CurTime() > self.NextUpdateText then
		local drawn = self.Drawn
		self.Drawn = 0
		
		local charge = self.Charged
		self.Charged = 0
		
		self:SetOverlayText(self:MakeNicePower(self.Watts) .. "\nDraw: " .. self:MakeNicePower(drawn) .. "s\nCharge: " .. self:MakeNicePower(charge) .. "s" )
		self.NextUpdateText = CurTime() + 1
		self.LastWatts = self.Watts
	end
	
	local t = CurTime() - self.LastThink
	self.LastThink = CurTime()
	
	self.WattsCache = self.WattsCache + self.Bandwidth * t
	self.WattsCache = math.Clamp(self.WattsCache, 0, math.min(self.Watts, self.Bandwidth))
	
	if self.Watts >= self.Capacity then return end
	
	-- ok, lets charge the battery from other sources
	local watt = math.min(self.Bandwidth, self.Capacity - self.Watts) * t
	--print(self.Bandwidth, watt)
	
	local got = self:Charge(self:GetPowerSources(), watt, false)
	
	self:AddWatts(got)
end

function ENT:Charge(srcs, watt, exact)

	local totalwatt = 0
	for k,src in pairs(srcs) do
		if not IsValid(src) then continue end
		totalwatt = totalwatt + src:MaxWatt() /* returns the bandwidth, or the avaibible power if less than bandwidth */
	end
	
	if totalwatt < watt then
		if exact then return 0 end
		
		watt = totalwatt
	end
	
	if totalwatt == 0 then return 0 end
	
	local ret = 0
	for k,src in pairs(srcs) do
		if not IsValid(src) then continue end
		
		local max = src:MaxWatt() 
		local percent = max / totalwatt
		local watt_used = watt * percent
		
		src:GetWatts(watt_used)
		
		ret = ret + watt_used
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
			return self.Watts
		end
	}
end