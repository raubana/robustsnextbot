local CURRENT_ID = CURRENT_ID or 0

RSNB_DPG_CONNECTION = RSNB_DPG_CONNECTION or {}



function RSNB_DPG_CONNECTION:create( node1, node2 )
	local instance = {}
	setmetatable(instance,self)
	self.__index = self
	
	instance.id = CURRENT_ID * 1.0
	instance.nodes = {node1, node2}
	
	CURRENT_ID = CURRENT_ID + 1
	
	return instance
end




local CONNECTION_COLOR = Color(0,0,128)
function RSNB_DPG_CONNECTION:DrawDebug( duration )
	local duration = duration
	if not duration then duration = 1.0 end
	debugoverlay.Line(self.nodes[1].pos, self.nodes[2].pos, duration, CONNECTION_COLOR, true)
end