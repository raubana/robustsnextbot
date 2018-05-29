print( "INIT" )


include( "sv_movement.lua" )
include( "sv_dynamics.lua" )
include( "sv_animation.lua" )


-- Should be called last inside of the Initialize method.
function ENT:RSNBInit()
	self.bool_nvar_count = 0
	self.int_nvar_count = 0
	self.float_nvar_count = 0
	self.angle_nvar_count = 0
	self.vector_nvar_count = 0
	self.entity_nvar_count = 0

	self:RSNBInitMovement()
	self:RSNBInitDynamics()
	self:RSNBInitAnimation()
end



-- Hook that is called after the RSNB finishes setting up its networked vars.
function ENT:PostRSNBSetupDataTables()
	
end



function ENT:SetupDataTables()
	self:RSNBSetupDataTablesMovement()
	self:RSNBSetupDataTablesDynamics()
	self:RSNBSetupDataTablesAnimation()
	
	self:PostRSNBSetupDataTables()
end



-- Should be called within the Think hook every tick.
function ENT:RSNBUpdate()
	self:UpdateDynamics()
	self:UpdateAnimation()
end




-- Convenience function. Returns the position of the head in world coordinates.
function ENT:GetHeadPos()
	return self:GetBonePosition( self:LookupBone( "ValveBiped.Bip01_Head1" ) )
end


