print( "DYNAMICS" )


include( "sv_dynamics_look.lua" )



function ENT:RSNBInitDynamics()
	self:RSNBInitDynamicsLook()
end



function ENT:RSNBSetupDataTablesDynamics()
end




function ENT:UpdateDynamics()
	self:UpdateLook()
end