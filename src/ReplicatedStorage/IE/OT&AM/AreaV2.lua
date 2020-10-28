-- basically my own datatype
local Area = {}
Area.__index = Area


local constructors
constructors = {
   default = function(minVector3, maxVector3)
        local self = setmetatable({}, Area)
        self.MinV = minVector3
        self.MaxV = maxVector3
        return self
    end,
    CF_Size = function (CFrame, Size )
        local abs = math.abs
        local sx, sy, sz = Size.X, Size.Y, Size.Z -- this causes 3 Lua->C++ invocations

        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = CFrame:components() -- this causes 1 Lua->C++ invocations and gets all components of cframe in one go, with no allocations

        -- https://zeuxcg.org/2010/10/17/aabb-from-obb-with-component-wise-abs/
        local wsx = 0.5 * (abs(R00) * sx + abs(R01) * sy + abs(R02) * sz) -- this requires 3 Lua->C++ invocations to call abs, but no hash lookups since we cached abs value above; otherwise this is just a bunch of local ops
        local wsy = 0.5 * (abs(R10) * sx + abs(R11) * sy + abs(R12) * sz) -- same
        local wsz = 0.5 * (abs(R20) * sx + abs(R21) * sy + abs(R22) * sz) -- same

        -- just a bunch of local ops
        local minx = x - wsx
        local miny = y - wsy
        local minz = z - wsz

        local maxx = x + wsx
        local maxy = y + wsy
        local maxz = z + wsz

        local minv, maxv = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)
        -- credit for conversion https://devforum.roblox.com/t/part-to-region3-help/251348/5
        return constructors.default(minv , maxv)
    end,
    part = function(part)
        return constructors.CF_Size(part.CFrame, part.Size)
    end
}

function Area.new(...) -- constructors for Area
    local n = select("#", ...)
    local args = {...}

    if n == 1 and typeof(args[1]) == "Instance" then
        return constructors.part(...)
    elseif  n == 2 and typeof(args[1]) == "CFrame" and typeof(args[2]) == "Vector3" then
        return  constructors.CF_Size(...)
    elseif  n == 2 and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
        return constructors.default(...)
    else
        error("Incorrect given parameters")
    end
end

function Area:isInArea(position) -- expects a vector3 instance, returns true if the position is inside the area
    return self.MinV.X <= position.X and position.X <= self.MaxV.X and self.MinV.Y <= position.Y and position.Y <= self.MaxV.Y and self.MinV.Z <= position.Z and position.Z <= self.MaxV.Z
end

function Area:getCF_Size()
    local region = Region3.new(self.MinV, self.MaxV)
    return region.CFrame, region.Size
end

return Area