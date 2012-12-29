
AddCSLuaFile()
--DEFINE_BASECLASS( "base_gmodentity" )

ENT.PrintName			= "Lua Sandbox"
ENT.Author				= "C0BRA"
ENT.Contact				= "c0bra@xiatek.org"
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE
ENT.Base				= "base_gmodentity"

ENT.Model				= "models/cheeze/wires/cpu2.mdl"
ENT.Quota 				= 1000000
ENT.MemoryQuota			= 64*1024 -- 64KB * 1024 = 64MB

AccessorFunc( ENT, "m_ShouldRemove", "ShouldRemove" )

--[[---------------------------------------------------------
   Name: Initialize
   Desc: First function called. Use to set up your entity
-----------------------------------------------------------]]
function ENT:Initialize()

	if ( SERVER ) then
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
	end
	
	self.Links = {}
	self.PowerSources = {}
	self.Crashed = false
	
	self:SetModel(self.Model)
end
/*
function ENT:GetJoules(joule)
	local totaljoule = 0
	
	for k,src in pairs(self.PowerSources) do
		if not IsValid(src) then continue end
		totaljoule = totaljoule + src:MaxJoule() // returns the bandwidth, or the avaibible power if less than bandwidth
	end
	
	if totaljoule < joule then
		return false
	end
	
	local ret = 0
	
	for k,src in pairs(self.PowerSources) do
		if not IsValid(src) then continue end
		
		local max = src:MaxJoule() 
		local percent = max / totaljoule
		
		local joule_used = joule * percent
		
		src:GetJoules(joule_used)
		ret = ret + joule_used
	end
	
	return true
end
*/

function ENT:GetJoules(joule)
	if self.Joules != self.Joules then self.Joules = 0 end
	
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

		src:TakeJoules(joule_used)
	end
	
	return true
end


function ENT:OnRemove()
end

function ENT:Reset()
	self:SetColor(Color(255, 255, 255))
	self.Enviroment = {}
	self.MemoryCount = 0
	self.Crashed = false
end

function ENT:PreEntityCopy()
	if CLIENT then return end
	local info = {}
	
	info.Code = self.Code
	info.CodeName = self.CodeName
	
	info.Links = {}
	
	for k,v in pairs(self.Links) do
		info.Links[k] = v.Entity:EntIndex()
	end
	
	info.PowerSources = {}
	for k,v in pairs(self.PowerSources or {}) do
		info.PowerSources[k] = v:EntIndex()
	end
	
	duplicator.StoreEntityModifier(self, "CodeAndLinks", info)
end

function ENT:PostEntityPaste(pl, ent, CreatedEntities)
	if CLIENT then return end
	if not ent.EntityMods then return end
	
	local tbl = ent.EntityMods["CodeAndLinks"]
	
	if not tbl then return end
	
	self:Setup(tbl.Code or "error('empty code')", tbl.CodeName)
	
	for k,v in pairs(tbl.Links) do
		self:Sandboxed_CreateLink(k).Entity = CreatedEntities[v]
	end
	
	for k,v in pairs(tbl.PowerSources) do
		self.PowerSources[k] = CreatedEntities[v]
	end
	
	self:SendUpdatedLinkTable()
	//function ENT:Sandboxed_CreateLink(name)
end

function ENT:Setup(code, name)
	name = "ei_sandbox_" .. (name or "unknown")
	
	self:Reset()
	self.Code = code
	self.CodeName = name

	local infloop = code:match("do%W+end")
	if infloop then
		self.Owner:ChatPrint("Please remove redundant `do end'")
		self:SetColor(Color(255, 0, 0))
		return
	end
	
	local func,err = CompileString(code, name, false)
	
	if type(func) == "string" or func == nil then
		self.Owner:ChatPrint((func or err) or "unknown error")
		self:SetColor(Color(255, 0, 0))
		return
	end
	
	self.Enviroment = {
		ipairs = ipairs,
		next = next,
		pairs = pairs,
		pcall = pcall,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack,
		/* -- I'm not too sure how safe this is, so I'm not exposing it to them.
		coroutine = {
			create = coroutine.create, resume = coroutine.resume, 
			running = coroutine.running, status = coroutine.status, 
			wrap = coroutine.wrap 
		},
		*/
		string = { 
			byte = string.byte, char = string.char, find = string.find, 
			format = string.format, gmatch = string.gmatch, gsub = string.gsub, 
			len = string.len, lower = string.lower, match = string.match, 
			rep = string.rep, reverse = string.reverse, sub = string.sub, 
			upper = string.upper 
		},
		table = {
			insert = table.insert, maxn = table.maxn, remove = table.remove, 
			sort = table.sort, HasValue = table.HasValue, Count = table.Count
		},
		math = { --table.Copy(math)
			abs = math.abs, acos = math.acos, asin = math.asin, 
			atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos, 
			cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor, 
			fmod = math.fmod, frexp = math.frexp, huge = math.huge, 
			ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max, 
			min = math.min, modf = math.modf, pi = math.pi, pow = math.pow, 
			rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh, 
			sqrt = math.sqrt, tan = math.tan, tanh = math.tanh,
			Round = math.Round
		},
		os = { clock = os.clock, difftime = os.difftime, time = os.time },
		bit = {
			tobit = bit.tobit, tohex = bit.tohex, bnot = bit.bnot,
			band = bit.band, bor = bit.bor, bxor = bit.bxor,
			lshift = bit.lshift, rshift = bit.rshift, 
			arshift = bit.arshift, rol = bit.rol, ror = bit.ror, 
			bswap = bit.bswap
		},
		// Garry's Mod functions
		print = print, PrintTable = PrintTable, // DANGER
		CurTime = CurTime, RealTime = RealTime, Angle = Angle, Vector = Vector, Color = Color,
		LerpAngle = LerpAngle, LerpVector = LerpVector
	}
	
	self.Enviroment["_G"] = self.Enviroment
	
	self.Enviroment.self = {
		GetLink = function(name) return self:Sandboxed_GetLink(name) end,
		CreateLink = function(name, asserter) return self:Sandboxed_CreateLink(name, asserter) end
	}
		
	debug.setfenv(func, self.Enviroment) -- make sure the Lua script can't touch any of the things it's not "supposed" to
	
	// Prevent them from crashing the server
	local count = 0
	debug.sethook(function()
		count = count + 1
		
		if count > self.Quota then
			self.Crashed = true
			debug.sethook()
			error("quota exceeded", 2)
		end
	end, "l", self.Quota)
	
	collectgarbage("stop")
	local memcount = collectgarbage("count")
	
	local x, err = pcall(func)
	
	self.MemoryCount = self.MemoryCount + (collectgarbage("count") - memcount)
	collectgarbage("restart")
	
	debug.sethook()
	
	
	if self.MemoryCount > self.MemoryQuota then
		self.Crashed = true
		error("memory usage exceeded", 2)
	end
	
	if not x then
		self:SetColor(Color(255, 0, 0))
		self.Owner:ChatPrint(err)
	end
end

function ENT:Think()
	if self.Crashed then return end
	if CLIENT then return end
	
	if not self.Enviroment.Think then
		return
	end
	
	if not self:GetJoules(200/66) then
		self:NextThink(CurTime() + 0.1)
		return true
	end
	
	local count = 0
	debug.sethook(function()
		count = count + 1
		
		if count > self.Quota then
			self.Crashed = true
			debug.sethook()
			error("quota exceeded", 2)
		end
	end, "l", self.Quota)
	
	collectgarbage("stop")
	local memcount = collectgarbage("count")
	
	local x, ret = pcall(self.Enviroment.Think)
	
	self.MemoryCount = self.MemoryCount + (collectgarbage("count") - memcount)
	collectgarbage("restart")
	
	debug.sethook()
	
	if self.MemoryCount > self.MemoryQuota then
		self.Crashed = true
		error("memory usage exceeded", 2)
	end
	
	
	if not x then
		self:SetColor(Color(255, 0, 0))
		self.Owner:ChatPrint(ret)
		self.Crashed = true
	elseif ret then
		self:NextThink(CurTime() + ret)
		return true
	end
	
	self:NextThink(CurTime() + 0.1)
	return true
end

function ENT:Sandboxed_GetLink(name)
	local lo = self.Links[name]
	
	if not lo then
		return error("Can't find the link `" .. name .. "'", 2)
	end
	
	local ret = {}
	setmetatable(ret, lo.Meta)
	
	return ret
end

function ENT:Sandboxed_CreateLink(name)
	if self.Links[name] != nil then return self.Links[name] end -- this link has already been made
	
	local link = {Name = name, Entity = nil}
	
	link.Meta = {
		__index = function(tbl, k)
			--print("index: " .. k)
			local tbl2
			
			if IsValid(link.Entity) then
				tbl2 = link.Entity:GetLinkTable()
			end
			
			if k == "Connected" then
				return IsValid(link.Entity)
			elseif tbl2 != nil and type(rawget(tbl2, k)) == "function" then
				if not IsValid(link.Entity) then return nil end
				
				return function(...)
					if not IsValid(link.Entity) then error("link not connected!", 2) return nil end
					
					local tbl = link.Entity:GetLinkTable()
					local func = rawget(tbl, k)
					if not func then
						error("The method `" .. name .. "' does not exist for " .. link.Entity:GetClass(), -2)
					end
					
					return func(self, ...)
				end
			end
			
			if IsValid(link.Entity) then
				local tbl = link.Entity:GetLinkTable()
				
				local v = rawget(tbl, k)
				
				if type(v) == "function" then return nil end
				return v
			end
		end
	}
	
	self.Links[name] = link
	
	self:SendUpdatedLinkTable()
	
	return self:Sandboxed_GetLink(name)
end

function ENT:SendUpdatedLinkTable()
	net.Start("ei_sandbox_links")
		net.WriteEntity(self)
		net.WriteTable(self.Links)
	net.Send(player.GetAll())
end

if SERVER then
	util.AddNetworkString("ei_sandbox_links")
else
	net.Receive("ei_sandbox_links", function()
		local e = net.ReadEntity()
		local tbl = net.ReadTable()
		
		e.Links = tbl
	end)
end

function ENT:OnTakeDamage(dmginfo)
end
