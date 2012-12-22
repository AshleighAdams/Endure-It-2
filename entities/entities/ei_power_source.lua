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
	-- this could be recursive, for say a plug
	if self.WattsCache < self.Bandwidth then
		return self.WattsCache
	end
	
	return self.Bandwidth
end

function ENT:TakeWatts(amm)
	self.Watts = self.Watts - amm
	self.WattsCache = self.WattsCache - amm
end

function BuildPowerTable(ent, depth, ret, done)
	if depth > 16 then
		ErrorNoHalt("Warning: max depth hit!")
		return
	end
	
	if done[ent] then return end
	done[ent] = true
	
	if ent.EndPoint then
		table.insert(ret, ent)
	end
	
	for k,v in pairs(ent.PowerSources) do
		BuildPowerTable(v, depth + 1, ret, done)
	end
end

function ENT:GetWatts(watt)
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

function ENT:Think()
	self.BaseClass.BaseClass.Think(self)
	if CLIENT then return end
	
	local t = CurTime() - self.LastThink
	self.WattsCache = self.WattsCache + self.Bandwidth * t
	self.WattsCache = math.Clamp(self.WattsCache, 0, math.min(self.Watts, self.Bandwidth))
	
	if self.Watts >= self.Capacity then return end
	
	-- ok, lets charge the battery from other sources
	local watt = math.min(self.Bandwidth, self.Capacity - self.Watts) * t
	local got = self:Charge(self:GetPowerSources(), watt, false)
	
	self.Watts = self.Watts + got
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
	
	local ret = 0
	for k,src in pairs(srcs) do
		if not IsValid(src) then continue end
		
		local max = src:MaxWatt() 
		local percent = max / totalwatt
		local watt_used = watt * percent
		
		v:TakeWatt(watt_used)
		
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