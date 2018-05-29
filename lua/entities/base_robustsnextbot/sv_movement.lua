print( "MOVEMENT" )


include( "sv_movement_motionless.lua" )


-- Should be called last inside of the Initialize method.
function ENT:RSNBInitMovement()
	self.path = nil
	
	self:RSNBInitMovementMotionless()
end



function ENT:RSNBSetupDataTablesMovement()
end