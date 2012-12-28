
AddCSLuaFile()

ENT.PrintName		= "Keybaord"
ENT.Author			= "Mostly WireMod"
ENT.Contact			= "c0bra@xiatek.org"
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.RenderGroup 	= RENDERGROUP_BOTH
ENT.Base			= "ei_linkable_ent"

ENT.Model 			= "models/beer/wiremod/keyboard.mdl"
ENT.Thrust			= 0
ENT.Enabled 		= 0

ENT.Spawnable			= true
ENT.AdminSpawnable		= false
ENT.DownCount 			= 0

ENT.KeyTranslate = {}

for i = 1, 10 do -- 0 to 9
	ENT.KeyTranslate[i] = string.char(i - 1)
end

for i = 11, 36 do -- a to z
	ENT.KeyTranslate[i] = string.char((97 - 11) + i)
end

function ENT:TranslateToChar(key)
	if self:ShouldCaps() then
		return string.upper(self.KeyTranslate[key]) or ""
	else
		return self.KeyTranslate[key] or ""
	end
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	if SERVER then
		self.KeyQueue = {}
		self.MouseDeltaX = 0
		self.MouseDeltaY = 0
		self:SetUseType( SIMPLE_USE )
	end
end


if CLIENT then
	EI_BlockFrame 		= EI_BlockFrame or nil
	EI_KeyStates 		= EI_KeyStates or {}
	EI_UseKeyboard 		= false
	
	function CreateBlocker()
		if not EI_BlockFrame then EI_BlockFrame = vgui.Create("TextEntry") end
		EI_BlockFrame:SetSize(10,10)
		EI_BlockFrame:SetPos(-100,-100)
		EI_BlockFrame:SetVisible(true)
		EI_BlockFrame:MakePopup()
		EI_BlockFrame:SetMouseInputEnabled(false)
		EI_BlockFrame.OnKeyCodeTyped = function(b,key)
			if not EI_KeyStates[key] then
				EI_KeyStates[key] = true
				net.Start("EI_KeyStateChanged")
					net.WriteUInt(1, 8)
					net.WriteUInt(key, 8)
				net.SendToServer()
				if key == 70 then
					CancelSelect = true
				end
			end
		end
		
		EI_UseKeyboard = true
	end
	
	usermessage.Hook("EI_CreateBlocker", CreateBlocker)
	concommand.Add("ei_keyboard_blockinput", CreateBlocker)
	
	function HideBlocker()
		if (EI_BlockFrame) then
			EI_BlockFrame:SetVisible(false)
		end

		EI_UseKeyboard = false
	end
	usermessage.Hook("EI_ReleaseBlocker", HideBlocker)
	concommand.Add("ei_keyboard_releaseinput", HideBlocker)
	
	CancelSelect = false
	function CheckKeys()
		if not EI_UseKeyboard and not CancelSelect then return end
		for i = 1,130 do
			if input.IsKeyDown(i) and not EI_KeyStates[i] then
				// The key has been pressed
				EI_KeyStates[i] = true
				net.Start("EI_KeyStateChanged")
					net.WriteUInt(1, 8)
					net.WriteUInt(i, 8)
				net.SendToServer()
				if i == 70 then
					CancelSelect = true
				end
			elseif not input.IsKeyDown(i) and EI_KeyStates[i] then
				// The key has been released
				EI_KeyStates[i] = false
				net.Start("EI_KeyStateChanged")
					net.WriteUInt(0, 8)
					net.WriteUInt(i, 8)
				net.SendToServer()
			end
		end
		
		if CancelSelect then
			CancelSelect = false
			RunConsoleCommand("cancelselect")
			HideBlocker()
			ViewAngles = nil
			
			for i = 1, 130 do
				EI_KeyStates[i] = false
			end
		end
	end
	hook.Add("PostRenderVGUI", "EI_CheckKeys", CheckKeys)
	
	local NextCheck = 0
	local ViewDelta = Angle()
	function KeybaordPreventViewChange(cmd)
		if not EI_UseKeyboard then
			ViewAngles = nil
			return
		end
		if EI_DynamicKeyboard then return end
		
		if ViewAngles == nil then
			ViewAngles = cmd:GetViewAngles()
		end
		
		if CurTime() > NextCheck then
			NextCheck = CurTime() + 0.1
			if ViewDelta.y != 0 or ViewDelta.p != 0 then
				net.Start("EI_MouseChange")
					net.WriteFloat(-ViewDelta.y) -- note: this one is inverted
					net.WriteFloat(ViewDelta.p)
				net.SendToServer()
			end
			ViewDelta = Angle()
		end
		ViewDelta = ViewDelta + (cmd:GetViewAngles() - ViewAngles)
		
		cmd:SetViewAngles(ViewAngles)
	end
	hook.Add("CreateMove", "PreventViewChange", KeybaordPreventViewChange)
end


if SERVER then
	util.AddNetworkString("EI_KeyStateChanged")
	util.AddNetworkString("EI_MouseChange")	
	
	function ReceiveKeys(len, pl)
		if len > 32 then
			pl:Kick("Key message length too long!")
		end
		
		local down = net.ReadUInt(8) != 0
		local key = net.ReadUInt(8)
				
		if not IsValid(pl.Keyboard) then return end
		
		pl.Keyboard:HandleInput(pl, key, down)
	end
	net.Receive("EI_KeyStateChanged", ReceiveKeys)
	
	function ReceiveMouseDelta(len, pl)
		local self = net.ReadEntity()
		
		if not IsValid(self.Typer) then return end
		if self.Typer != pl then return end
		
		local x = net.ReadFloat()
		local y = net.ReadFloat()
		
		self.MouseDeltaX = self.MouseDeltaX + x
		self.MouseDeltaY = self.MouseDeltaY + y
	end
	net.Receive("EI_MouseChange", ReceiveMouseDelta)
	
	function ENT:HandleInput(pl, key, down)
		if self.Typer != pl then 
			pl.Keyboard = nil
			self.Typer = nil
			pl:ConCommand("ei_keyboard_releaseinput")
			return
		end
		
		if key == 70 then -- Escape
			pl.Keyboard = nil
			self.Typer = nil
			pl:ConCommand("ei_keyboard_releaseinput")
			return
		end
		
		if table.Count(self.KeyQueue) > 32 then return end -- eh, we're full
		table.insert(self.KeyQueue, {Key = key, Down = down})
	end
end

function ENT:Use( activator, caller, type, value )
	if not activator:IsPlayer() then return end
	if IsValid(self.Typer) and self.Typer.Keyboard == self then return end -- someone is already on it
	
	self.Typer = activator
	activator.Keyboard = self
	activator:ConCommand("ei_keyboard_blockinput")
	activator:ChatPrint("Push ESCAPE to release input!")
end

function ENT:Think()
	if not IsValid(self.Typer) then return end
	
	self.Typer:ConCommand("ei_keyboard_blockinput")
	
	self:NextThink(CurTime() + 1)
	return true
end

function ENT:GetLinkTable()
	return {
		NextEvent = function()
			if #self.KeyQueue <= 0 then return nil end
			local ret = self.KeyQueue[1]
			table.remove(self.KeyQueue, 1)
			return ret
		end,
		MouseDelta = function()
			local x, y = self.MouseDeltaX, self.MouseDeltaY
			self.MouseDeltaX = 0
			self.MouseDeltaY = 0
			return x, y
		end,
		HasTyper = function()
			return IsValid(self.Typer)
		end
	}
end