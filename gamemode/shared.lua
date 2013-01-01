GM.Name		 = "Endure It 2"
GM.Author	 = "C0BRA"
GM.Email	 = "c0bra@xiatek.org"
GM.Website	 = "xiatek.org"

DeriveGamemode("sandbox")

include("planets.lua")

local ValidMoveTypes = {
	[MOVETYPE_WALK] = true,
	[MOVETYPE_FLYGRAVITY] = true,
	[MOVETYPE_STEP] = true,
	[MOVETYPE_WALK] = true,
}

function GM:Move(pl, data)
	if not pl.CurrentPlanet then return end
	if pl:WaterLevel() > 1 then return end
	if not ValidMoveTypes[pl:GetMoveType()] then return end
	
	pl:SetVelocity(Vector(0, 0, -pl.CurrentPlanet.Gravity))
end

function GM:Tick()
	Space:Think()
end
