AddCSLuaFile()

-- models/props_spytech/radar_top002.mdl
-- models/props_lab/citizenradio.mdl

-- models/props_rooftop/Roof_Dish001.mdl  Sat dish

ENT.PrintName		= "Radio"
ENT.Author			= "C0BRA"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= "Transmit and recieve"
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "ei_linkable_ent"

ENT.Model 			= "models/props_lab/citizenradio.mdl"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false
ENT.EI_Radio 			= true

EI_Radio_Devices = EI_Radio_Devices or {}
EI_Radio_Devices_Count = EI_Radio_Devices_Count or 0
EI_Radio_Devices_ThinkCount = EI_Radio_Devices_ThinkCount or 0

function EI_Radio_Devices_Think()
	if CLIENT then return end
	
	EI_Radio_Devices_ThinkCount = EI_Radio_Devices_ThinkCount + 1
	
	if EI_Radio_Devices_ThinkCount < EI_Radio_Devices_Count then return end
	EI_Radio_Devices_ThinkCount = 0
	
	for k,v in pairs(EI_Radio_Devices) do
		k:PostThink()
	end
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Frequency = 200
	self.OutputPower = 5 -- 5W
	self.Squelch = 1
	self.BandPass = 0.2
	
	self.Bits = {}
	self.Queue = {}
	self.SendQueue = {}
	
	EI_Radio_Devices[self] = true
	EI_Radio_Devices_Count = EI_Radio_Devices_Count - 1
end

function ENT:GetPowerOutput()
	return self.OutputPower
end

function ENT:Transmit(val)
	local c = #self.SendQueue
	
	if c > 64 then
		return error("Send queue is full!", 3)
	end
	
	table.insert(self.SendQueue, val)
end

function ENT:Receive(from, val)
	val = val + 256
	
	local distance = from:GetPos():Distance(self:GetPos())
	local freq_dist = math.max(math.abs(from.Frequency - self.Frequency) / self.BandPass)
	local power = from:GetPowerOutput() * 1000
	
	local factor = power / distance * math.max(0, 1-freq_dist)
	
	for i = 0, 8 do
		-- local x = (val & 1 << i) >> i
		local comp = bit.lshift(1, i)
		local x = bit.rshift(bit.band(comp, val), i)
		
		x = x * factor
		local err = x * 0.1
		
		self.Bits[i+1] = (self.Bits[i+1] or 0) + x + math.Rand(0, err)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	local val = self.SendQueue[1]
	
	if val then
		table.remove(self.SendQueue, 1)
		
		val = math.Round(math.Clamp(val, 0, 255))
		
		for k,v in pairs(ents.GetAll()) do
			if v.EI_Radio and v.Receive and v != self then
				v:Receive(self, val)
			end
		end
	end
	
	EI_Radio_Devices_Think()
	
	self:NextThink(CurTime())
	return true
end

function ENT:PostThink() -- This is done after making sure every other radio device has thaught	
	-- Introduce some random noise & calculate max
	local max = 0
	for i = 0, 8 do
		self.Bits[i+1] = (self.Bits[i+1] or 0) + math.Rand(0, self.BandPass * 5)
		
		if self.Bits[i+1] > max then
			max = self.Bits[i+1]
		end
	end
	
	--print(max, self.Squelch)
	
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
		
		table.insert(self.Queue, {Value = val, Intensity = max, Freq = self.Frequency})
		
	end
	
	-- Reset
	for i = 0, 8 do
		self.Bits[i+1] = 0
	end
end

function ENT:GetLinkTable()
	return {
		SetFrequency = function(chip, freq)
			self.Frequency = math.Clamp(freq, 80, 2499.999)
			
			return self.Frequency
		end,
		SetOutputPower = function(chip, pwr)
			self.OutputPower = pwr
		end,
		SetSquelch = function(chip, x)
			self.Squelch = x
		end,
		SetBandPass = function(chip, x)
			x = math.max(0.2, x)
			self.BandPass = x
		end,
		WriteByte = function(chip, val)
			if not chip:GetJoules(self.OutputPower * 1) then return end
			self:Transmit(val)
		end,
		ReadByte = function(chip)
			local ret = self.Queue[1]
			table.remove(self.Queue, 1)
			if not ret then return end
			return ret.Value, ret.Intensity, ret.Freq
		end,
		HasData = function(chip, x)
			return (#self.Queue) >= (x or 1)
		end,
		SendQueueSize = function(chip)
			return (#self.SendQueue)
		end
	}
end

function ENT:OnRemove()
	EI_Radio_Devices[self] = nil
	EI_Radio_Devices_Count = EI_Radio_Devices_Count - 1
end


function ENT:OnTakeDamage(dmginfo)
end
