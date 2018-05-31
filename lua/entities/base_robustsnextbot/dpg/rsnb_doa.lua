RSNB_DOA = RSNB_DOA or {}




function RSNB_DOA:create( ent, path, minimal_path_dist, options )
	local instance = {}
	setmetatable(instance,self)
	self.__index = self
	
	instance.ent = ent
	instance.path = path
	instance.minimal_path_dist = minimal_path_dist
	
	instance.options = options or {}
	
	instance.hull_halfthick = (options.hull_thick or 28) / 2
	instance.hull_stand_height = options.hull_stand_height or 75
	instance.hull_crouch_height = options.hull_crouch_height or 75
	
	instance.node_min_dist = options.node_min_dist or 14
	instance.node_travel_dist = instance.node_min_dist + 1
	instance.node_max_dist = instance.node_min_dist*2-1
	
	instance.nodes = {}
	instance.connections = {}
	
	instance.open_nodes = {}
	
	instance.done = false
	instance.result = "ok"
	
	instance.output = nil
	
	instance:CreateSeedNode( ent:GetPos() )
	
	return instance
end




function RSNB_DOA:DrawDebug(duration)
	local duration = duration
	if not duration then duration = 1.0 end
	
	if IsValid(self.ent) then
		for i, node in ipairs(self.nodes) do
			node:DrawDebug(duration)
		end
		
		for i, connection in ipairs(self.connections) do
			connection:DrawDebug(duration)
		end
	end
end



local COLOR_RED = Color(255,0,0)
local COLOR_GREEN = Color(0,255,0)



local function doValidationHullTrace( start, endpos, mins, maxs, filter, drawit )
	local tr = util.TraceHull({
		start = start,
		endpos = endpos,
		mins = mins,
		maxs = maxs,
		filter = filter,
		mask = MASK_SOLID,
	})
	
	if drawit or true then
		-- local c = COLOR_GREEN
		-- if tr.Hit then c = COLOR_RED end
		-- debugoverlay.SweptBox( start, endpos, mins, maxs, angle_zero, engine.TickInterval()*2, c )
	end
	
	--coroutine.yield() -- FOR DEBUG
	
	return tr
end




function RSNB_DOA:EvaluateNode( new_node )
	self.path:MoveCursorTo( self.minimal_path_dist )
	self.path:MoveCursorToClosestPosition( new_node.pos )
	
	local cursor_dist = self.path:GetCursorPosition()
	local cursor_pos = self.path:GetPositionOnPath( cursor_dist )
	
	new_node.path_cursor_pos = cursor_pos
	
	new_node.dist_from_path = new_node.pos:Distance( cursor_pos )
	new_node.path_cursor_offset = cursor_dist-self.minimal_path_dist
end




function RSNB_DOA:ScoreNodeWithParent( new_node, parent )
	local data = {}
	data.parent = parent
	data.dist_from_parent = 0
	data.travel_dist = 0
	
	if parent then 
		data.dist_from_parent = new_node.pos:Distance( parent.pos )
		data.travel_dist = parent.travel_dist + data.dist_from_parent
	end
	
	if new_node.path_cursor_offset < 0 then 
		new_node.path_cursor_offset = -math.pow(new_node.path_cursor_offset, 2)
	end
	
	data.score = new_node.dist_from_path + (data.travel_dist*2) - new_node.path_cursor_offset
	return data
end




function RSNB_DOA:ApplyDataToNode( new_node, data )
	new_node.parent = data.parent
	new_node.travel_dist = data.travel_dist
	new_node.score = data.score
end




function RSNB_DOA:GetNearestNode( pos, ceiling )
	if #self.nodes == 0 then return nil, nil end

	local nearest = nil
	local nearest_dist = nil
	
	local mins = pos - (ceiling*Vector(1,1,1))
	local maxs = pos + (ceiling*Vector(1,1,1))
	
	for i, node in ipairs(self.nodes) do
		if node.valid then
			local dist = node.pos:Distance(pos)
			if (nearest == nil or dist < nearest_dist) and dist <= ceiling then
				nearest = node
				nearest_dist = dist
			end
		end
	end
	
	return nearest, nearest_dist
end




function RSNB_DOA:CheckSpacialValidityAtPos( pos )
	local output = {can_stand_here=false}
	if not util.IsInWorld( pos ) then return output end
	
	-- debugoverlay.Box( pos, Vector( -self.hull_halfthick+2, -self.hull_halfthick+2, 2 ), Vector( self.hull_halfthick-2, self.hull_halfthick-2, self.hull_stand_height-2 ), engine.TickInterval()*2 )
	
	local height = self.hull_stand_height

	local tr_up = doValidationHullTrace( pos, pos + Vector(0,0,self.hull_stand_height), Vector(-self.hull_halfthick, -self.hull_halfthick, 0), Vector(self.hull_halfthick, self.hull_halfthick, 0), self.ent )
	
	if tr_up.Hit or tr_up.StartSolid then
		height = tr_up.Fraction * self.hull_stand_height
		if height < self.hull_crouch_height then return output end
		output.must_crouch = true
	end
	
	local tr_down = doValidationHullTrace( pos + Vector(0,0,height), pos, Vector(-self.hull_halfthick, -self.hull_halfthick, 0), Vector(self.hull_halfthick, self.hull_halfthick, 0), self.ent )
	if tr_down.Hit or tr_down.StartSolid then return output end
	
	local tr_right = doValidationHullTrace( pos - Vector(0,self.hull_halfthick,0), pos + Vector(0,self.hull_halfthick,0), Vector(-self.hull_halfthick, 0, 0), Vector(self.hull_halfthick, 0, height), self.ent )
	if tr_right.Hit or tr_right.StartSolid then return output end
	
	local tr_left = doValidationHullTrace( pos + Vector(0,self.hull_halfthick,0), pos - Vector(0,self.hull_halfthick,0), Vector(-self.hull_halfthick, 0, 0), Vector(self.hull_halfthick, 0, height), self.ent )
	if tr_left.Hit or tr_left.StartSolid then return output end
	
	local tr_forward = doValidationHullTrace( pos - Vector(self.hull_halfthick,0,0), pos + Vector(self.hull_halfthick,0,0), Vector(0, -self.hull_halfthick, 0), Vector(0, self.hull_halfthick, height), self.ent )
	if tr_forward.Hit or tr_forward.StartSolid then return output end
	
	local tr_backward = doValidationHullTrace( pos + Vector(self.hull_halfthick,0,0), pos - Vector(self.hull_halfthick,0,0), Vector(0, -self.hull_halfthick, 0), Vector(0, self.hull_halfthick, height), self.ent )
	if tr_backward.Hit or tr_backward.StartSolid then return output end
	
	output.can_stand_here = true
	
	return output
end




function RSNB_DOA:FindConnection( node1, node2 )
	for i, connection in ipairs(node1.connections) do
		if connection.nodes[1] == node2 or connection.nodes[2] == node2 then
			return connection1
		end
	end
	return nil
end




function RSNB_DOA:GenerateConnections( node )
	for i, other_node in ipairs(self.nodes) do
		if other_node != node then
			local dist = node.pos:Distance(other_node.pos)
			if dist >= self.node_min_dist and dist <= self.node_max_dist then
				local existing_connection = self:FindConnection(node, other_node)
				
				if existing_connection == nil then
					-- node:DrawDebug( engine.TickInterval()*2 )
					-- other_node:DrawDebug( engine.TickInterval()*2 )
				
					local tr = doValidationHullTrace(
						node.pos,
						other_node.pos,
						Vector(-self.hull_halfthick, -self.hull_halfthick, 0),
						Vector(self.hull_halfthick, self.hull_halfthick, self.hull_stand_height),
						self.ent
					)
					
					if not tr.Hit then
						local new_connection = RSNB_DPG_CONNECTION:create(node, other_node)
						local center = LerpVector(0.5, node.pos, other_node.pos)
						
						table.insert(self.connections, new_connection)
						
						table.insert(node.connections, new_connection)
						table.insert(other_node.connections, new_connection)
						
						if not other_node.open then
							local score_data = self:ScoreNodeWithParent( node, other_node )
							if node.parent == nil or node.score > score_data.score then
								self:ApplyDataToNode( node, score_data )
							end
						end
					end
				end
			end
		end
	end
end




function RSNB_DOA:EstimateNewNodesFromGivenNode( node )
	-- next we generate a list of possible positions we might be able to travel to from here.
	for x = -self.node_travel_dist, self.node_travel_dist, self.node_travel_dist do
		for y = -self.node_travel_dist, self.node_travel_dist, self.node_travel_dist do
			if not (x==0 and y==0) then
				local new_pos = node.pos + Vector(x,y,0)
				
				--debugoverlay.Cross(node.pos, 3, engine.TickInterval()*2, color_black)
				--debugoverlay.Cross(new_pos, 3, engine.TickInterval()*2, color_white)
				
				local tr = doValidationHullTrace(
					new_pos + Vector(0,0,self.node_max_dist-1),
					new_pos - Vector(0,0,self.node_max_dist-1),
					Vector(-self.hull_halfthick, -self.hull_halfthick, 0),
					Vector(self.hull_halfthick, self.hull_halfthick, 0),
					self.ent
				)
				
				if tr.Hit and not tr.StartSolid then
					new_pos = tr.HitPos + Vector(0,0,5)
					
					local other_nearest, other_nearest_dist = self:GetNearestNode( new_pos, self.node_max_dist )
				
					if (other_nearest == nil) or (other_nearest_dist >= self.node_min_dist) then
						local results = self:CheckSpacialValidityAtPos(new_pos)
						
						local new_node = RSNB_DPG_NODE:create( new_pos )
						
						if results.can_stand_here then
							table.insert(self.nodes, new_node)
							table.insert(self.open_nodes, new_node)
							
							self:EvaluateNode(new_node)
							self:GenerateConnections(new_node)
						else
							--debugoverlay.Text(new_pos, "can't stand here", engine.TickInterval()*2)
							new_node.open = false
							new_node.valid = false
						end
					--else
					--	if other_nearest == nil then
					--		debugoverlay.Text(new_pos, "is nil", engine.TickInterval()*2)
					--	elseif other_nearest_dist < self.node_min_dist then
					--		debugoverlay.Text(new_pos, "too close", engine.TickInterval()*2)
					--		debugoverlay.Cross(other_nearest.pos, 10, engine.TickInterval()*2, COLOR_RED)
					--	else
					--		debugoverlay.Text(new_pos, "???", engine.TickInterval()*2)
					--	end
					end
				--else
				--	if not tr.Hit then
				--		debugoverlay.Text(new_pos, "no hit", engine.TickInterval()*2)
				--	else
				--		debugoverlay.Text(new_pos, "start solid", engine.TickInterval()*2)
				--	end
				end
			end
		end
	end
end




function RSNB_DOA:CreateSeedNode( pos )
	local tr = doValidationHullTrace(
		pos + Vector(0,0,16),
		pos - Vector(0,0,self.node_min_dist),
		Vector(-self.hull_halfthick, -self.hull_halfthick, 0),
		Vector(self.hull_halfthick, self.hull_halfthick, 0),
		self.ent
	)
	
	local pos = pos
	if tr.Hit then
		pos = tr.HitPos + Vector(0,0,5)
	end

	local new_node = RSNB_DPG_NODE:create( pos )
	
	self:EvaluateNode( new_node )
	local score_data = self:ScoreNodeWithParent( new_node, nil )
	self:ApplyDataToNode( new_node, score_data )

	table.insert(self.nodes, new_node)
	
	-- Move this new node into the closed list.
	new_node.open = false
	self:EstimateNewNodesFromGivenNode( new_node )
end




function RSNB_DOA:Generate()
	if self.done then return end

	if #self.nodes > (self.options.max_nodes or 300) then
		self.result = "failed"
		self.done = true
		return
	end
	
	local pick_index = nil
	local pick_score = nil
	
	for i, node in ipairs( self.open_nodes ) do
		if node.parent != nil and (pick_score == nil or node.score < pick_score) then
			pick_index = i
			pick_score = node.score
		end
	end
	
	if pick_index == nil then
		self.result = "failed"
		self.done = true
		return
	end
	
	local pick = self.open_nodes[pick_index]
	table.remove( self.open_nodes, pick_index )
	pick.open = false
	
	if self.options.draw then
		self.path:Draw()
		self:DrawDebug( 0.1 )
		debugoverlay.Line(pick.pos+Vector(0,0,10), pick.path_cursor_pos+Vector(0,0,10), 0.1, COLOR_WHITE, true)
	end
	
	if pick.path_cursor_offset > 0 and pick.dist_from_path < self.node_travel_dist then
		local new_path = {}
		
		local current_node = pick
		while current_node != nil do
			table.insert(new_path, current_node.pos)
			current_node = current_node.parent
		end
		new_path = table.Reverse( new_path )
		
		self.output = new_path
		self.result = "ok"
		self.done = true
	else
		self:EstimateNewNodesFromGivenNode( pick )
	end
end