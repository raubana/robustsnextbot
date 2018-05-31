print( "ANIMATION" )


include( "sv_animation_blink.lua" )



function ENT:RSNBInitAnimation()
	self.activity_stack = util.Stack()
	
	self.use_bodymoveyaw = false

	self:RSNBInitAnimationBlink()
end




function ENT:RSNBSetupDataTablesAnimation()
end




function ENT:PlayGesture( name )
	self:AddGestureSequence( self:LookupSequence( name ) )
end




function ENT:PushActivity( act, duration )
	print( self, "PushActivity", act, duration )
	local duration = duration or -1
	local endtime = -1
	if duration > 0 then
		endtime = CurTime() + duration
	end
	
	if self.activity_stack:Size() == 0 or act != self.activity_stack:Top()[1] then
		self:StartActivity( act )
	end
	self.activity_stack:Push( {act, endtime} )
end




function ENT:PopActivity()
	print( self, "PopActivity" )
	if self.activity_stack:Size() > 0 then
		self.activity_stack:Pop()
		if self.activity_stack:Size() == 0 or act != self.activity_stack:Top()[1] then
			self:StartActivity( self.activity_stack:Top()[1] )
		end
	end
end




function ENT:BodyMoveYaw()
	local my_ang = self:GetAngles()
	local my_vel = self.loco:GetGroundMotionVector()
	
	if my_vel:IsZero() then return end
	
	local move_ang = my_vel:Angle()
	local ang_dif = move_ang - my_ang
	ang_dif:Normalize()
	
	self.move_ang = LerpAngle( 0.9, ang_dif, self.move_ang )
	
	self:SetPoseParameter( "move_yaw", self.move_ang.yaw )
end




function ENT:BodyUpdate()
	local act = self:GetActivity()
	
	if act == ACT_WALK or act == ACT_RUN then
		self:BodyMoveXY()
		if self.use_bodymoveyaw then
			self:BodyMoveYaw()
		end
		return
	end
	
	self:FrameAdvance()
end




function ENT:UpdateAnimation()
	self:UpdateBlink()
	
	local top = self.activity_stack:Top()
	if istable(top) then
		if top[2] > 0 and CurTime() >= top[2] then
			self:PopActivity()
		end
	end
end