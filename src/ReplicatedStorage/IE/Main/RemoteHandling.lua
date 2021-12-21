local Main = script.Parent
local IEFolder = Main.Parent

local RemoteFolder = IEFolder:WaitForChild("RemoteFolder")

local module = {}

--// Returns the RemoteEvent, Type = "Audio" or "Lighting"
function module:GetRemote(Type: string, RemoteName: string)
    local RemoteName = Type.. RemoteName

    local Remote: RemoteEvent = RemoteFolder:FindFirstChild(RemoteName)

    if not Remote then
        warn(RemoteName, "not found in RemoteFolder")
        return
    end

    return Remote
end

return module