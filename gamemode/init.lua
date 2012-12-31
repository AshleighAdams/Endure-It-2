AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("planets.lua")

include("shared.lua")

RunConsoleCommand("sv_gravity", 0)

function GM:PlayerSpawn(pl)
    self.BaseClass:PlayerSpawn(pl)
end

function GM:PlayerInitialSpawn(pl)
	self.BaseClass:PlayerInitialSpawn(pl)
end

function GM:PlayerLoadout(pl)
	self.BaseClass:PlayerLoadout(pl)
	
	pl:Give("weapon_physcannon")
	pl:Give("weapon_physgun")
	pl:Give("gmod_tool")
end

