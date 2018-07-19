print( "DYNAMICS - LOOK" )



local DEBUG_DYNAMICS_LOOK = CreateConVar("rsnb_debug_dynamics_look", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )


-- Should be called last inside of the Initialize method.
function ENT:RSNBInitDynamicsLook()
	self.look_head_angle = Angle(0,0,0)
	self.look_head_turn_bias = 0.5
	
	self.look_requires_visibility = true
	
	self.look_entity = nil
	self.look_endtime = 0 -- The time when this NextBot stops looking at what it's looking at currently.
	
	self.look_keep_focus = false
	self.look_bored_min_interval = 3 -- The time it takes for the NextBot to get bored of looking at something.
	self.look_bored_max_interval = 5
	self.look_bored_min_interval_person = 1.5 -- The time it takes for the NextBot to get bored of looking at someone else.
	self.look_bored_max_interval_person = 3
	
	self.look_sightstray_next_time = 0
	self.look_sightstray_min_delay = 0.3
	self.look_sightstray_max_delay = 0.7
	self.look_sightstray_offset = Vector()
end




local COLOR_RED = Color(255,0,0)
local COLOR_GREEN = Color(0,255,0)



-- Hook that is called when the entity this NextBot is looking at changes.
function ENT:OnChangedLookAt( old, new )
	if DEBUG_DYNAMICS_LOOK:GetBool() then
		print( self, "OnChangedLookAt", old, new )
		debugoverlay.Text( self:GetHeadPos(), tostring("changed") )
		if old != nil then debugoverlay.Line( self:GetHeadPos(), old:GetPos(), 2, COLOR_RED ) end
		if new != nil then debugoverlay.Line( self:GetHeadPos(), new:GetPos(), 2, COLOR_GREEN ) end
	end
end




function ENT:SetEntityToLookAt( ent )
	if ent != self.look_entity then
		local old = self.look_entity
		self.look_entity = ent
		self:OnChangedLookAt( old, ent )
		
		if ent != nil and IsValid( ent ) and ( ent:IsNPC() or ent:IsPlayer() or ent.Type == "nextbot" ) then
			self.look_endtime = CurTime() + Lerp(math.random(), self.look_bored_min_interval_person, self.look_bored_max_interval_person)
		else
			self.look_endtime = CurTime() + Lerp(math.random(), self.look_bored_min_interval, self.look_bored_max_interval)
		end
		
		if math.random() > 0.2 then self:Blink() end
	end
end




function ENT:FindSomethingNearbyToLookAt()
	if self.look_entity != nil then
		self:SetEntityToLookAt( nil )
		return true
	end

	local ent_list = ents.FindInSphere( self:GetHeadPos(), 500 )
	
	while #ent_list > 0 do
		local index = math.random(#ent_list)
		local pick = table.remove( ent_list, index )
		
		if IsValid(pick) and pick != self.look_entity then
			if pick == nil or pick:IsSolid() and pick != self then
				if self:Visible( pick ) then
					self:SetEntityToLookAt( pick )
					return true
				end
			end
		end
	end
	
	return false
end




-- Call this to randomly chose an entity to look at. Override this to control what it looks at.
function ENT:FindSomethingToLookAt()
	if self:FindSomethingNearbyToLookAt() then return end

	local ent_list = ents.FindInSphere( self:GetHeadPos(), 10000 )
	table.insert( ent_list, nil )
	
	while #ent_list > 0 do
		local index = math.random(#ent_list)
		local pick = table.remove( ent_list, index )
		
		if (IsValid(pick) or pick == nil) and pick != self.look_entity then
			if pick == nil or pick:IsSolid() and pick != self then
				if self:Visible( pick ) then
					self:SetEntityToLookAt( pick )
					return
				end
			end
		end
	end
	
	self:SetEntityToLookAt( nil )
end




-- Should run inside the Think hook. Don't call this directly unless you know what you're doing.
function ENT:UpdateLook()
	local target = self.look_entity
	local target_pos = nil
	
	if target != nil and IsValid( target ) then
		if isfunction(target.GetShootPos) then
			target_pos = target:GetShootPos()
		elseif isfunction(target.GetHeadPos) then
			target_pos = target:GetHeadPos()
		else
			target_pos = target:GetPos()
		end
	end
	
	if target_pos == nil then
		if self.alt_path != nil then
			-- We're following an alt path, so we should be looking at that if
			-- we're not looking at something else.
			target_pos = self.alt_path[ math.min( self.alt_path_index+2, #self.alt_path ) ]
		elseif self.path != nil then
			-- We're following a path, so we should be looking at that if we're
			-- not looking at something else.
			local cursor_dist = self.path:GetCursorPosition()
			target_pos = self.path:GetPositionOnPath( cursor_dist + 300 )
		else
			-- Just look forward blankly
			target_pos = self:GetHeadPos() + self:GetAngles():Forward() * 1000
		end
	end
	
	local target_angle = ( target_pos - self:GetHeadPos() ):Angle()
	local target_head_angle = target_angle - self:GetAngles()
	target_head_angle:Normalize()
	
	
	target_head_angle.yaw = math.Clamp( target_head_angle.yaw, -80, 80 )
	
	local p = math.pow( 0.5, (engine.TickInterval() * game.GetTimeScale())/0.2 )
	self.look_head_angle = LerpAngle( p, target_head_angle, self.look_head_angle )
	
	if math.max(math.abs(self.look_head_angle.pitch), math.abs(self.look_head_angle.yaw)) > 1 then
		self:SetPoseParameter( "head_pitch", self.look_head_angle.pitch * self.look_head_turn_bias )
		self:SetPoseParameter( "head_yaw", self.look_head_angle.yaw * self.look_head_turn_bias )
	end
	
	if CurTime() > self.look_sightstray_next_time then
		self.look_sightstray_offset = VectorRand() * 3
		self.look_sightstray_next_time = CurTime() + Lerp(math.random(), self.look_sightstray_min_delay, self.look_sightstray_max_delay)
		
		self:SetEyeTarget( target_pos + self.look_sightstray_offset )
	end
	
	if not self.look_keep_focus and CurTime() >= self.look_endtime then
		self:FindSomethingToLookAt()
		self.look_sightstray_next_time = CurTime()
	end
end