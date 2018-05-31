AddCSLuaFile()

ENT.Base 			= "base_robustsnextbot"
ENT.Spawnable		= true



function ENT:Initialize()
	self:SetModel( "models/Humans/Group01/Male_04.mdl" )
	
	if SERVER then
		self:RSNBInit()
		
		self.use_bodymoveyaw = true
	end
end



if SERVER then
	function ENT:Think()
		self:RSNBUpdate()
		self:NextThink( CurTime() )
		return true
	end
end




function ENT:OnLeaveGround( ent )
	print( self, "OnLeaveGround" )
	self:PushActivity( ACT_JUMP )
end




function ENT:OnLandOnGround( ent )
	print( self, "OnLandOnGround" )
	if self.activity_stack != nil then
		if self.activity_stack:Size() > 0 and self.activity_stack:Top()[1] == ACT_JUMP then
			self:PopActivity()
		end
		if self:GetVelocity().z < -100 then
			self:PushActivity( ACT_LAND, 0.5 )
		end
	end
end




function ENT:RunBehaviour()
	self:PushActivity( ACT_IDLE )
	
	coroutine.wait( 1 )
	
	while true do
		local pos = self:FindSpot(
			"random",
			{
				type = "hiding",
				pos = self:GetPos(),
				radius = 100000
			}
		)
		
		local result = self:MoveToPos( pos, {draw=true} )
		print( "MOVE TO POS RESULT:", result )
	
		coroutine.wait( 2 )
	end
end




list.Set( "NPC", "npc_example_rsnb", {
	Name = "RobustSNB Example",
	Class = "npc_example_rsnb",
	Category = "RobustSNB Examples"
} )