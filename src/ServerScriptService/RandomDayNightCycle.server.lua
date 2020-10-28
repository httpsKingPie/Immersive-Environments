-- dayLength defines how long, in minutes, a day in your game is. Feel free to alter it.
local dayLength = 12

local cycleTime = dayLength*60
local minutesInADay = 24*60

local lighting = game:GetService("Lighting")

local startTime = tick() - (lighting:getMinutesAfterMidnight() / minutesInADay)*cycleTime
local endTime = startTime + cycleTime

local timeRatio = minutesInADay / cycleTime

if dayLength == 0 then
	dayLength = 1
end

repeat
	local currentTime = tick()
	
	if currentTime > endTime then
		startTime = endTime
		endTime = startTime + cycleTime
	end
	
	lighting:setMinutesAfterMidnight((currentTime - startTime)*timeRatio)
	wait(1/15)
until false
