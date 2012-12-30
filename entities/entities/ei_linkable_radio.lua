AddCSLuaFile()

-- models/props_spytech/radar_top002.mdl
-- models/props_lab/citizenradio.mdl

ENT.PrintName		= "Radio"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "Transmit and recieve"
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_linkable_ent"

ENT.Model 			= "models/bull/various/gyroscope.mdl"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false
ENT.EI_Radio 			= true

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Frequency = 200
	self.OutputPower = 5 -- 5W
	self.Squelch = 1
	
	self.Bits = {}
	self.Queue = {}
end

function ENT:GetPowerOutput()
	return self.OutputPower
end

function ENT:Transmit(val)
	val = math.Round(math.Clamp(val, 0, 255))
	
	for k,v in pairs(ents.GetAll()) do
		if v.EI_Radio and v.Receive and v != self then
			v:Receive(self, val)
		end
	end
end

function ENT:Receive(from, val)
	val = val + 256
	
	local distance = from:GetPos():Distance(self:GetPos())
	local power = from:GetPowerOutput() * 1000
	
	local factor = power / distance
	
	for i = 0, 8 do
		-- local x = (val & 1 << i) >> i
		local comp = bit.lshift(1, i)
		local x = bit.rshift(bit.band(comp, val), i)
		
		x = x * factor
		local err = x * 0.05 -- 5%, 10% when inc. negative
		
		self.Bits[i+1] = (self.Bits[i+1] or 0) + x + math.Rand(-err, err)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	-- Introduce some random noise & calculate max
	local max = 0
	for i = 0, 8 do
		self.Bits[i+1] = (self.Bits[i+1] or 0) + math.pow(math.Rand(0, 1), 2)
		
		if self.Bits[i+1] > max then
			max = self.Bits[i+1]
		end
	end
	
	if max > self.Squelch then
		
		if #self.Queue > 64 then
			return
		end
		
		-- Process
		local threshold = max * 0.5
		local val = 0
		for i = 0, 7 do
			if not (self.Bits[i+1] > threshold) then continue end
			--val = val | 1 << i
			val = bit.bor(val, bit.lshift(1, i))
		end
		
		table.insert(self.Queue, {Value = val, Intensity = max})
		
	end
	
	-- Reset
	for i = 0, 8 do
		self.Bits[i+1] = 0
	end
end

function ENT:GetLinkTable()
	return {
		SetFequency = function(chip, freq)
			self.Frequency = freq
		end,
		SetOutputPower = function(chip, pwr)
			self.OutputPower = pwr
		end,
		WriteByte = function(chip, val)
			if not chip:GetJoules(self.OutputPower) then return end
			self:Transmit(val)
		end,
		ReadByte = function(chip)
			local ret = self.Queue[1]
			table.remove(self.Queue, 1)
			if not ret then return end
			return ret.Value, ret.Intensity
		end,
		HasData = function(chip)
			return (#self.Queue) > 1
		end
	}
end

function ENT:OnRemove()
end


function ENT:OnTakeDamage(dmginfo)
end
