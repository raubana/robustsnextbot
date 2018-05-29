AddCSLuaFile()

ENT.Base 			= "base_robustsnextbot"
ENT.Spawnable		= true



function ENT:Initialize()
	self:SetModel( "models/Humans/Group01/Male_04.mdl" )
	
	if SERVER then
		self:RSNBInit()
	end
end



if SERVER then
	function ENT:Think()
		self:RSNBUpdate()
		self:NextThink( CurTime() )
		return true
	end
end




function ENT:RunBehaviour()
	self:PushActivity( ACT_IDLE )
	coroutine.wait( 2 )
	while true do
		coroutine.wait( 1 )
	end
end




list.Set( "NPC", "npc_example_rsnb", {
	Name = "RobustSNB Example",
	Class = "npc_example_rsnb",
	Category = "RobustSNB Examples"
} )