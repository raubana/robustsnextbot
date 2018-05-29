print( "DYNAMICS - LOOK" )


-- Should be called last inside of the Initialize method.
function ENT:RSNBInitDynamicsLook()
	self.look_head_angle = Angle(0,0,0)
	self.look_head_turn_bias = 0.5
	
	self.look_entity = nil
	self.look_endtime = 0 -- The time when this NextBot stops looking at what it's looking at currently.
	self.look_bored_min_interval = 3 -- The time it takes for the NextBot to get bored of looking at something.
	self.look_bored_max_interval = 7
	self.look_bored_min_interval_person = 1.5 -- The time it takes for the NextBot to get bored of looking at someone else.
	self.look_bored_max_interval_person = 3
	
	self.look_sightstray_next_time = 0
	self.look_sightstray_min_delay = 0.3
	self.look_sightstray_max_delay = 0.7
	self.look_sightstray_offset = Vector()
end




-- Hook that is called when the entity this NextBot is looking at changes.
function ENT:OnChangedLookAt( old, new )
	print( old, new )
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
		
		if math.random() > 0.25 then self:Blink() end
	end
end




-- Call this to randomly chose an entity to look at. Override this to control what it looks at.
function ENT:FindSomethingToLookAt()
	local ent_list = ents.FindInPVS(self:GetHeadPos())
	table.insert( ent_list, nil )
	
	while #ent_list > 0 do
		local index = math.random(#ent_list)
		local pick = table.remove( ent_list, index )
		
		if (IsValid(pick) or pick == nil) and pick != self.look_entity then
			if pick == nil or pick:IsSolid() and pick != self then
				self:SetEntityToLookAt( pick )
				return
			end
		end
	end
	
	self:SetEntityToLookAt( nil )
end




-- Should run inside the Think hook. Don't call this directly unless you know what you're doing.
function ENT:UpdateLook()
	local target = self.look_entity
	local target_pos = self:GetHeadPos() + self:GetAngles():Forward() * 1000
	
	if target != nil and IsValid( target ) then
		if isfunction(target.GetShootPos) then
			target_pos = target:GetShootPos()
		elseif isfunction(target.GetHeadPos) then
			target_pos = target:GetHeadPos()
		else
			target_pos = target:GetPos()
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
	
	if CurTime() >= self.look_endtime then
		self:FindSomethingToLookAt()
		self.look_sightstray_next_time = CurTime()
	end
end