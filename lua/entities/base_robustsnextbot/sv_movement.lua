print( "MOVEMENT" )


include( "sv_movement_motionless.lua" )
 -- DPG = Dynamic Path Generator
include( "dpg/rsnb_dpg.lua" )




function ENT:RSNBInitMovement()
	self.path = nil
	self.alt_path = nil -- reserved for dynamically generated paths
	self.alt_path_index = 1
	
	self.walk_speed = 75
	self.run_speed = 200
	
	self.walk_accel = 50
	self.walk_decel = 50
	
	self.run_accel = 300
	self.run_decel = 100
	
	self.walk_turn_speed = 180
	self.run_turn_speed = 90
	
	self.move_ang = Angle()
	
	self.run_tolerance = 500
	
	self:RSNBInitMovementMotionless()
end



function ENT:RSNBSetupDataTablesMovement()
end




function ENT:SetupToRun( push )
	if push then self:PushActivity( ACT_RUN ) end
	self.loco:SetDesiredSpeed( self.run_speed )
	self.loco:SetMaxYawRate( self.run_turn_speed )
	self.loco:SetAcceleration( self.run_accel )
	self.loco:SetDeceleration( self.run_decel )
end




function ENT:SetupToWalk( push )
	if push then self:PushActivity( ACT_WALK ) end
	self.loco:SetDesiredSpeed( self.walk_speed )
	self.loco:SetMaxYawRate( self.walk_turn_speed )
	self.loco:SetAcceleration( self.walk_accel )
	self.loco:SetDeceleration( self.walk_decel )
end




function ENT:GiveMovingSpace( options )
	print( self, "GiveMovingSpace" )
	
	self:SetupToWalk( true )

	local timeout = CurTime() + ( options.maxage or 3 )

	while CurTime() <= timeout do
		local closest_ang = nil
		local closest_dist = nil
		local trace_length = 45 -- TODO
		local start = self:GetPos() + Vector(0,0,75/2) -- TODO
		
		local offset = (CurTime()%45)*8
		
		for ang = 0, 360, 45 do
			local ang2 = ang + offset
		
			local normal = Angle(0,ang2,0):Forward()
			local endpos = start + normal * trace_length
			
			local tr = util.TraceEntity({
					start = start,
					endpos = endpos,
					filter = self,
					mask = MASK_SOLID,
				},
				self
			)
			
			if options.draw then
				debugoverlay.Line( start, start + normal * (trace_length * tr.Fraction), 0.1, color_white, true )
			end
			
			if tr.Hit and (closest_dist == nil or tr.Fraction*trace_length < closest_dist) then
				closest_ang = ang2
				closest_dist = tr.Fraction*trace_length
			end
		end
		
		if closest_dist == nil or closest_dist > 1 then
			self:PopActivity()
			return "ok"
		else
			local result = Angle( 0, closest_ang, 0 )
			self.loco:Approach( self:GetPos() - (result:Forward()*100), 1 )
		end
		
		coroutine.yield()
	end
	
	self:PopActivity()
	return "timeout"
end




function ENT:FollowAltPath( options )
	print( self, "FollowAltPath" )
	self:ResetMotionless()
	
	self:SetupToWalk( true )
	
	local timeout = CurTime() + ( options.timeout or 60 )
	
	while self.alt_path_index <= #self.alt_path do
		if CurTime() >= timeout then
			self:PopActivity()
			return "timeout"
		end
		
		if self.motionless then
			local result = self:GiveMovingSpace( options )
			if result != "ok" then
				self:PopActivity()
				return result
			end
		end
	
		if options.draw then
			for i = 1, #self.alt_path - 1 do
				debugoverlay.Line( self.alt_path [i], self.alt_path [i+1], 0.1, color_white, true )
			end
		end
		
		self.loco:Approach( self.alt_path[self.alt_path_index], 1 )
		self.loco:FaceTowards( self.alt_path[ self.alt_path_index ] )
		if self:GetPos():Distance( self.alt_path[ self.alt_path_index ] ) < 10 then -- TODO: replace magic number
			self.alt_path_index = self.alt_path_index + 1
		end
		
		coroutine.yield()
	end
	
	self:PopActivity()
	return "ok"
end




function ENT:HandleStuck( options )
	print( self, "HandleStuck" )
	
	self:PushActivity( ACT_IDLE )

	-- Give some space around the NextBot. This helps with the next step.
	local result = self:GiveMovingSpace( options )
	if result != "ok" then
		self:PopActivity()
		return result
	end
	
	-- Dynamically generate a path using DOA (Dynamic Obstacle Avoidance)
	local cursor_dist = self.path:GetCursorPosition()
	
	local dpg = RSNB_DOA:create(
			self, 
			self.path, 
			cursor_dist + 20,
			options
	)
	
	local timeout = CurTime() + ( options.dpg_maxage or 8 )
	while not dpg.done do
		if CurTime() >= timeout then
			self:PopActivity()
			return "timeout" 
		end
		dpg:Generate()
		coroutine.yield()
	end
	if dpg.result != "ok" then
		self:PopActivity()
		return dpg.result
	end
	
	-- Get the NextBot to follow the dynamically generated path.
	self.alt_path = dpg.output
	self.alt_path_index = 1
	local result = self:FollowAltPath( options )
	if result != "ok" then
		self:PopActivity()
		return result
	end
	
	self:PopActivity()
	return "ok"
end




-- Helper function. Automatically decides weather to run or walk based on
-- how close to the end the NextBot is, and how steep the path is.
function ENT:UpdateRunOrWalk( len, no_pop )
	local cur_act = self.activity_stack:Top()
	
	local cursor_dist = self.path:GetCursorPosition()
	local future_pos = self.path:GetPositionOnPath( cursor_dist + 150 )
	
	local ang = (future_pos - self:GetPos()):Angle()
	ang = ang - Angle(0,self:GetAngles().yaw,0)
	ang:Normalize()
	
	local should_walk = math.abs(ang.pitch) > 10 or math.abs(ang.yaw) > 90
	
	if len <= self.run_tolerance or should_walk then
		if cur_act[1] != ACT_WALK then
			if not no_pop then
				self:PopActivity()
			end
			self:SetupToWalk( true )
			cur_act = self.activity_stack:Top()
		end
	else
		if cur_act[1] != ACT_RUN then
			if not no_pop then
				self:PopActivity()
			end
			self:SetupToRun( true )
			cur_act = self.activity_stack:Top()
		end
	end
	
	return cur_act
end




function ENT:MoveToPos( pos, options )
	print( self, "MoveToPos" )

	local options = options or {}

	self.path = Path( "Follow" )
	self.path:SetMinLookAheadDistance( options.lookahead or 300 )
	self.path:SetGoalTolerance( options.tolerance or 20 )
	self.path:Compute( self, pos )
	
	if not self.path:IsValid() then return "failed" end
	
	-- set the initial animation and speed.
	local len = self.path:GetLength()
	self:UpdateRunOrWalk( len, true )
	
	self:ResetMotionless()
	
	while self.path:IsValid() do
		self:CheckIsMotionless()
	
		local cur_act = self.activity_stack:Top()
	
		if self.path:GetAge() > ( options.repath or 2.0 ) then
			self.path:Compute( self, pos )
			
			-- update the animation and speed as needed.
			local len = self.path:GetLength()
		end
		
		if cur_act[2] <= 0 and self:OnGround() then
			local len = self.path:GetLength()
			cur_act = self:UpdateRunOrWalk( len )
		end
		
		-- only move when the animation is a movement type.
		if cur_act[1] == ACT_WALK or cur_act[1] == ACT_RUN then
			self.path:Update( self )
		else
			self:ResetMotionless()
		end

		if options.draw then self.path:Draw() end
		
		if self.loco:IsStuck() or self.motionless then
			self:PopActivity()
			
			local result = self:HandleStuck( options )
			if result != "ok" then return ( result or "stuck" ) end
			self.path:Compute( self, pos )
			
			self:PushActivity( ACT_IDLE )
		end

		coroutine.yield()
	end
	
	self:PopActivity()
	return "ok"
end