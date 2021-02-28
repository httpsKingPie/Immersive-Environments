-- @Author: VerdommeMan, see https://github.com/VerdommeMan/OT-AM for more information, minor changes by https_KingPie for integration with Immersive Environments

local shapes = {}
shapes.AreaV2 = require(script:WaitForChild("AreaV2"))
shapes.AreaV7 = require(script:WaitForChild("AreaV7"))
local ObjectTracker = require(script:WaitForChild("ObjectTracker"))

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local module = {}

--settings, can be changed directly instead of using the setters (read/write)
module.Settings = {}
module.Settings.Heartbeat = 2 --max 60
module.Settings.FolderName = "OT&AM: Areas" -- name used for the folder where the parts will be stored in for making Areas visible
module.Settings.FrontCenterPosition = false -- so instead of using the center of part to calculate if a player is inside an  area it will use the FrontCenterPosition (only if Size is available)
module.Settings.Part = {  --contains the props of the part that will generated for that Area when its made visible
    Transparency = 0.7,
    Color = Color3.fromRGB(255, 85, 255),
    CastShadow = false,
    CanCollide = false,
    Anchored = true
}

--settings, cant be changed directly (read only)
module.Settings.AutoAddPlayersCharacter = true -- if this is set to false then the person must manually add the player characters he wants to track
module.Settings.TrackedObjects = {} -- tracked objects are saved here

-- other stuff
local mtAreas = {} -- different mt table because i dont want to pollute Areas with metamethods
local Areas = {} -- a list of areas
mtAreas.__index = Areas

local function canUseAreaV2(cf) -- 
    local x, y, z = cf:ToEulerAnglesYXZ()
    x , y, z = math.round(math.deg(x)),math.round(math.deg(y)), math.round(math.deg(z))
    return x%90 == 0 and y%90 ==0 and z%90 == 0
end

local function checkIfAutoDetermineWhichArea(arg)
    if typeof(arg) == "Instance" then
        return canUseAreaV2(arg.CFrame)
    elseif typeof(arg) == "CFrame" then
        return canUseAreaV2(arg)
    end
    return false -- cant determine for these types
end

--// https_KingPie function
function module.RemoveAllAreas()
	for Identifier, Area in pairs (Areas) do
		module.removeArea(Identifier)
	end
end

--// https_KingPie function
function module.RemoveAreas(ListOfIdentifiers: table)
	for Index, Identifier in pairs (ListOfIdentifiers) do
		if Areas[Identifier] then
			module.removeArea(Identifier)
		end
	end
end

--// https_KingPie function
function module.GetAllAreas()
	return Areas
end

function module.addArea(uniqueName, ...) -- first param needs to be unique key for the area, then you add the constructor parameters and as last you have an optional override 
    local args = {...}

    if #args == 0 then
        error("Wrong given parameters")
    elseif Areas[uniqueName] then
        error("That name '".. tostring(uniqueName).. "' already exists") --// Edit by https_KingPie to provide more detail as to which area already exists
    else
        local area = setmetatable({}, mtAreas) -- mt allows ppl to access other areas from this table
        
        if typeof(args[#args]) == "string" and shapes[args[#args]] then -- the optional override, only works if the given string is a real type of Area
            area.Area = shapes[table.remove(args)].new(unpack(args))
        else
            area.Area = checkIfAutoDetermineWhichArea(args[1]) and shapes.AreaV2.new(...) or shapes.AreaV7.new(...)
        end
        area.enter = Instance.new("BindableEvent")
        area.leave = Instance.new("BindableEvent")
        area.onEnter = area.enter.Event
        area.onLeave = area.leave.Event
        area.TrackedObjectKeys = {}

        function area:getObjects()
            local keys = {}
            for key in pairs(self.TrackedObjectKeys) do
                table.insert(keys, module.Settings.TrackedObjects[key])
            end
            return keys
        end
        
        Areas[uniqueName] = area
        return area
    end
end

function module.removeArea(identifier)
    Areas[identifier] = nil
end

function module.getArea(indentifier)
    return Areas[indentifier]
end

function module.addTrackedObject(object, objectKey, size) -- objectKey is optional, this is what is returned from the bindeable event and must be unique, second is the parameters for the TrackedObject
    if module.Settings.TrackedObjects[objectKey or object] then
        error("ObjectKey / object already exists as key, it must be unique")
    else
        module.setTrackedObject(object, objectKey, size)
    end
end

function module.setTrackedObject(object, objectKey, size) -- object is the item you wanna track, objectKey is optional, this is what is returned from the bindeable event and must be unique, third is optional if you give an item without an Size property you can give it one so that you can still use FCP feature
        module.Settings.TrackedObjects[objectKey or object] = ObjectTracker.new(object , size)
end

function module.removeTrackedObject(objectKey)
    module.Settings.TrackedObjects[objectKey] = nil
end

local playerCharEvents = {} -- keeps a table of RBXScriptConnections

local function addCharEvents(player)
    table.insert(playerCharEvents, player.CharacterAdded:Connect(function(character)
        module.addTrackedObject(character:WaitForChild("HumanoidRootPart").Parent, player) -- in my testing sometimes the PrimaryPart isnt set fast enough
    end))
    table.insert(playerCharEvents, player.CharacterRemoving:Connect(function()
        module.removeTrackedObject(player)
    end))
end


local function addPlayerCharEvents() -- intended behavoir it only starts tracking new players that join, if you want to track already joind players then you must add them yourself
    if RunService:IsClient() then -- different behavoir depending on executed on client or server (client only adds his char while server adds everyones char)
       addCharEvents(Players.LocalPlayer)
    else
        table.insert(playerCharEvents, Players.PlayerAdded:Connect(function(player)
            addCharEvents(player)
        end))
    end
end

local function removePlayerCharEvents() -- intended behavior leave event never fires when shutdown and player was in an Area
    for _, event in ipairs(playerCharEvents) do
        event:Disconnect()
    end
    playerCharEvents = {}
    for _, player in ipairs(Players:GetPlayers()) do
        module.removeTrackedObject(player)
    end
end

addPlayerCharEvents()

function module.setAutoAddCharacter(bool) -- set this to false if you want to manually add the characters, you can turn it back on by setting it true again
    if bool == not module.Settings.AutoAddPlayersCharacter then
        if bool then
            addPlayerCharEvents()
        else
            removePlayerCharEvents()
        end
        module.Settings.AutoAddPlayersCharacter = bool
    else
        warn("AutoAddCharacter is already in this state")
    end
end

function module.getAreas(objectKey)
    local areas = {}

    for _, area in pairs(Areas) do
        if area.TrackedObjectKeys[objectKey] then
            table.insert(areas, area)
        end
    end
    return areas    
end

function module.switchMakeAreasVisible() -- call it to make the areas visible, call it again to make the areas invisible
    local folder = workspace:FindFirstChild(module.Settings.FolderName)
    if folder then
        folder:Destroy()
    else
        local newFolder = Instance.new("Folder")
        newFolder.Name = module.Settings.FolderName
        newFolder.Parent = workspace

        for key, area in pairs(Areas) do            
            local part = Instance.new("Part")

            for prop, value in pairs(module.Settings.Part) do
                part[prop] = value
            end
            part.Name = key
            part.CFrame , part.Size = area.Area:getCF_Size()
            part.Parent = newFolder
        end
    end
end

local function coreLoop()
    for key, to in pairs(module.Settings.TrackedObjects) do
        coroutine.wrap(function()
            for _, area in pairs(Areas) do
                local contains, object = area.Area:isInArea(module.Settings.FrontCenterPosition and to:getFCP() or to:getPosition()), area.TrackedObjectKeys[key]
                if not object and contains then
                    area.TrackedObjectKeys[key] = true
                    area.enter:Fire(key) 
                    break
                elseif object and not contains then
                    area.TrackedObjectKeys[key] = nil
                    area.leave:Fire(key) 
                    break
                end
            end
        end)()
    end
end

local sumDt = 0
RunService.Heartbeat:Connect(function(dt)
    sumDt += dt
    if sumDt >= 1 / module.Settings.Heartbeat then
        sumDt = 0
        coreLoop()
    end
end)

return module