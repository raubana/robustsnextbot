AddCSLuaFile()

print( "SHARED" )

ENT.Base = "base_nextbot"



function ENT:Initialize()
end



if SERVER then
	include( "sv_robustsnextbot.lua" )
end
