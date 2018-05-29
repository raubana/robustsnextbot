print( "ANIMATION" )


include( "sv_animation_blink.lua" )



function ENT:RSNBInitAnimation()
	self.activity_stack = util.Stack()

	self:RSNBInitAnimationBlink()
end



function ENT:RSNBSetupDataTablesAnimation()
end




function ENT:PushActivity( act, duration )
	local duration = duration or -1
	local endtime = -1
	if duration > 0 then
		endtime = CurTime() + duration
	end

	self:StartActivity( act )
	self.activity_stack:Push( {act, endtime} )
end




function ENT:PopActivity()
	print( self, "PopActivity" )
	if self.activity_stack:Size() > 0 then
		self.activity_stack:Pop()
		self.activity_end_stack:Pop()
		
		self:StartActivity( self.activity_stack:Top() )
	end
end




function ENT:UpdateAnimation()
	self:UpdateBlink()
	
	local top = self.activity_stack:Top()
	if istable(top) and top[2] > 0 then
		if CurTime() >= top[2] then
			self:PopActivity()
		end
	end
end