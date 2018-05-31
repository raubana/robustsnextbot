local CURRENT_ID = CURRENT_ID or 0

RSNB_DPG_NODE = RSNB_DPG_NODE or {}



function RSNB_DPG_NODE:create( pos )
	local instance = {}
	setmetatable(instance,self)
	self.__index = self
	
	instance.id = CURRENT_ID * 1.0
	instance.pos = pos
	instance.connections = {}
	instance.parent = nil
	
	instance.travel_dist = 0
	instance.dist_from_path = 0
	instance.path_cursor_pos = nil
	instance.path_cursor_offset = 0
	instance.score = 0
	
	instance.valid = true
	instance.open = true
	
	CURRENT_ID = CURRENT_ID + 1
	
	return instance
end




local INVALID_NODE_COLOR = Color(255,0,0)
local OPEN_NODE_COLOR = Color(0,128,0)
local CLOSED_NODE_COLOR = Color(0,0,128)
local COLOR_MAGENTA = Color(255,0,255)

function RSNB_DPG_NODE:DrawDebug(duration)
	if not duration then
		duration = 1.0
	end
	
	local c = INVALID_NODE_COLOR
	if self.valid then
		if self.open then
			c = OPEN_NODE_COLOR
		else
			c = CLOSED_NODE_COLOR
		end
	end
	
	local s = 3
	debugoverlay.Cross(self.pos, s, duration, c)
	if self.valid and self.open then
		debugoverlay.Text(self.pos, tostring(math.floor(self.score)), duration)
	end
	
	if self.parent != nil then
		debugoverlay.Line(self.pos, self.parent.pos+Vector(0,0,5), duration, COLOR_MAGENTA, true)
	end
end