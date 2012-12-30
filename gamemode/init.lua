AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

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

function GM:Think()
	hook.Call("ThinkGM")
end