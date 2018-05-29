print( "ANIMATION - BLINK" )



function ENT:RSNBInitAnimationBlink()
	self.blinking = false
	self.blink_starttime = 0 -- The time of the last blink.
	self.blink_nextblink = 0
	self.blink_duration = 1/10
	self.blink_min_interval = 3
	self.blink_max_interval = 5
	self.blink_flex_id = self:GetFlexIDByName( "blink" )
end




function ENT:Blink()
	if not self.blinking then
		self.blinking = true
		self.blink_starttime = CurTime()
		self:OnBlink()
	end
end




function ENT:OnBlink()
	
end




function ENT:OnBlinkEnd()
	
end



-- 
function ENT:UpdateBlink()
	if self.blinking then
		local p = math.min( (CurTime()-self.blink_starttime)/self.blink_duration, 1 )
		
		local p2
		if p < 0.5 then
			p2 = p * 2
		else
			p2 = 1-((p-0.5)/0.5)
		end
		
		self:SetFlexWeight( self.blink_flex_id, p2 )
		
		if p == 1 then
			self.blinking = false
			self.blink_nextblink = CurTime() + Lerp( math.random(), self.blink_min_interval, self.blink_max_interval )
			self:OnBlinkEnd()
		end
	else
		if CurTime() >= self.blink_nextblink then
			self:Blink()
		end
	end
end