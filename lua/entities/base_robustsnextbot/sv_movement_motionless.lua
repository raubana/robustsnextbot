print( "MOVEMENT - MOTIONLESS" )


-- Should be called last inside of the Initialize method.
function ENT:RSNBInitMovementMotionless()
	self.motionless = false
	self.motionless_ticks = 0
	self.motionless_speed_limit = 2 -- How slow the NextBot must be going at most to be considered motionless.
	self.motionless_interval = 0.33 -- How long before the motionless flag is set to true.
end



-- Hook that is called when the NextBot is believed to be motionless.
function ENT:OnMotionless()
	print( self, "OnMotionless" )
end




-- Hook that is called when the NextBot was motionless but isn't anymore.
function ENT:OnNoLongerMotionless()
	print( self, "OnNoLongerMotionless" )
end




function ENT:ResetMotionless()
	self.motionless_ticks = 0
	if self.motionless then
		self.motionless = false
		self:OnNoLongerMotionless()
	end
end




-- To be called within MoveToPos or related methods (like Chase).
function ENT:CheckIsMotionless()
	local reset_motionless_ticks = true
	if self:OnGround() then
		local ground_ent = self:GetGroundEntity()
		
		if IsValid(ground_ent) or ground_ent:IsWorld() then
			local relative_vel = self:GetVelocity() - ground_ent:GetVelocity()
			local speed = relative_vel:Length()
			
			if speed < self.motionless_speed_limit then
				reset_motionless_ticks = false
			end
		end
	end
	
	if reset_motionless_ticks then
		self.motionless_ticks = 0
	else
		self.motionless_ticks = self.motionless_ticks + 1
	end
	
	local old_state = self.motionless
	self.motionless = self.motionless_ticks * engine.TickInterval() >= self.motionless_interval
	
	if old_state != self.motionless then
		if self.motionless then
			self:OnMotionless()
		else
			self:OnNoLongerMotionless()
		end
	end
end