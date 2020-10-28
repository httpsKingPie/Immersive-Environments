-- names comes from the fact im storing 7 vectors
local Area = {}
Area.__index = Area

local constructors
constructors = {
   default = function(corners, vectors) -- first param needs the four positions of a corner (origin and three perpendicular corners), second needs the vectors of those three perpendicular corners
        local self = setmetatable({}, Area)
        self.P1 = corners[1] 
        self.P2 = corners[2]
        self.P3 = corners[3]
        self.P4 = corners[4]
        self.u = vectors[1]
        self.v = vectors[2]
        self.w = vectors[3]
        return self
    end,
    CF_Size = function (cframe, Size)
        local pos1 = (cframe * CFrame.new(Size.X/-2, Size.Y/-2, Size.Z/-2)).Position
        local pos2 = (cframe * CFrame.new(Size.X/2, Size.Y/-2, Size.Z/-2)).Position
        local pos3 = (cframe * CFrame.new(Size.X/-2, Size.Y/2, Size.Z/-2)).Position
        local pos4 = (cframe * CFrame.new(Size.X/-2, Size.Y/-2, Size.Z/2)).Position
       
        local u = pos2 - pos1
        local v = pos3 - pos1
        local w = pos4 - pos1       
        return constructors.default({pos1,pos2,pos3,pos4} , {u, v, w})
    end,
    part = function(part)
        return constructors.CF_Size(part.CFrame, part.Size)
    end
}

function Area.new(...) -- constructors for AreaV7
    local n = select("#", ...)
    local args = {...}

    if n == 1 and typeof(args[1]) == "Instance" then
        return constructors.part(...)
    elseif  n == 2 and typeof(args[1]) == "CFrame" and typeof(args[2]) == "Vector3" then
        return  constructors.CF_Size(...)
    elseif  n == 2 and typeof(args[1]) == "table" and #args[1] == 4 and typeof(args[2]) == "table" and #args[2] == 3 then
        return constructors.default(...)
    else
        error("Incorrect given parameters")
    end
end

-- credit for the idea of checking an area https://math.stackexchange.com/questions/1472049/check-if-a-point-is-inside-a-rectangular-shaped-area-3d
function Area:isInArea(position) -- expects a vector3 instance, returns true if the position is inside the area
    local ux = self.u:Dot(position)
    local vx = self.v:Dot(position)
    local wx = self.w:Dot(position)

    local constraint1 = self.u:Dot(self.P1) <= ux and ux <= self.u:Dot(self.P2)
    local constraint2 = self.v:Dot(self.P1) <= vx and vx <= self.v:Dot(self.P3)
    local constraint3 = self.w:Dot(self.P1) <= wx and wx <= self.w:Dot(self.P4)
    return constraint1 and constraint2 and constraint3
end

function Area:getCF_Size()
    return CFrame.fromMatrix(self.P1 + self.u/2 + self.v/2 + self.w/2, self.u , self.v, self.w), Vector3.new(self.u.Magnitude, self.v.Magnitude, self.w.Magnitude)
end

return Area
