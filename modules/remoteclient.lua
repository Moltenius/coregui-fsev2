-- ceat_ceat

local http = game:GetService("HttpService")
local startergui = game:GetService("StarterGui")
local runservice = game:GetService("RunService")

local REQUEST_EXPIRATION_TIME = math.huge
local KEY_CHANGE_PERIOD = 1
local LENIENCY = 2
local PING_TIME = 2
local SCRAMBLE_CHARS = "qwertyuiopasdfghjklzxcvbnm"
local SERVICES = {
	"SoundService",
	"Chat",
	"MarketplaceService",
	"LocalizationService",
	"JointsService",
	"FriendService",
	"InsertService",
	"Lighting",
	"Teams",
	"TestService",
	"ProximityPromptService"
}

local plrs = game:GetService("Players")

local localplayer = plrs.LocalPlayer
local mouse = localplayer:GetMouse()

local remoteclient = {}
local requests = {}

local aes = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/aes.lua", true))()

remoteclient.Methods = {}

local settings = localplayer.PlayerGui.remoteconfig

local remotename = settings:GetAttribute("Name")
local key = settings:GetAttribute("Key")
local timeassigned = settings:GetAttribute("TimeAssigned")

local remotes = {}

-- random service idk what can i say
local function randomservice()
	return game:GetService(SERVICES[math.random(1, #SERVICES)])
end

-- lets the client distinguish their remote from others
local function hasremotename(s)
	local s2 = s
	for i = 1, #SCRAMBLE_CHARS do
		s2 = s2:gsub(SCRAMBLE_CHARS:sub(i, i), "")
	end
	return s2 == remotename
end

-- get current key as it changes every KEY_CHANGE_PERIOD seconds
local function getkeynow()
	local elapsed = math.floor(workspace:GetServerTimeNow()) - timeassigned
	return key + math.floor(elapsed/KEY_CHANGE_PERIOD)
end

-- extremely super ultra mega rare chance of collision but just in case
-- this uses generateguid bc it has to be unique
-- the loop is just to make super duper sure
local function getuniquereqid()
	local id
	repeat
		id = http:GenerateGUID(false):gsub("-", "")
	until not requests[id]
	return id
end

-- connect to potential remoteevent, if the remote is not the right one its fine
-- cus fireserver and invokeserver are encrypted
local function servicechildadded(inst)
	if table.find(remotes, inst) then
		return
	end

	if not inst:IsA("RemoteEvent") then
		return
	end

	if not hasremotename(inst.Name) then
		return
	end

	local onclientevent
	local ancestrychanged
	local destroying

	-- copy paste :scream:
	onclientevent = inst.OnClientEvent:Connect(function(packetobf, err)
		local key = getkeynow()
		local packet

		if not packetobf and err then
			startergui:SetCore("SendNotification", {
				Title = "fsev2",
				Text = err
			})
			return
		end

		for i = -LENIENCY, LENIENCY do
			local successdeobf, deobf = pcall(aes.ECB_256, aes.decrypt, key + i, packetobf)
			if not successdeobf then
				continue
			end

			local successdecode, decoded = pcall(http.JSONDecode, http, deobf)
			if not successdecode then
				continue
			end

			packet = decoded
			break
		end

		if not packet then
			return
		end

		local reqtype = packet.Type
		local reqid = packet.RequestId
		local args = packet.Args

		-- private response method for invokeserver
		if reqtype == 2 then
			if not requests[reqid] then
				return
			end

			requests[reqid].ReturnArgs = args
			requests[reqid].Fullfilled = true
			return
		end

		local method = args[1]
		table.remove(args, 1)

		if not remoteclient.Methods[method] then
			return
		end

		remoteclient.Methods[method](unpack(args))
	end)

	-- survive client kill so that it survives /rs on require executor and stuff
	destroying = inst.Destroying:Connect(function()
		onclientevent:Disconnect()
		destroying:Disconnect()
		remoteclient:FireServer(remotename)
		table.remove(remotes, table.find(remotes, inst))
	end)

	table.insert(remotes, inst)
	task.defer(function()
		inst.Parent =  nil
	end)
end

-- get remotes that could potentially be the correct one
local function lookthruservice(service)
	for _, v in service:GetChildren() do
		task.spawn(servicechildadded, v)
	end
end

for _, servicename in SERVICES do
	local service = game:GetService(servicename)

	lookthruservice(service)
	service.ChildAdded:Connect(servicechildadded)
end

-- this was from when i was debugging hasremotename() but this is good so itll stay
-- my thinking behind this is that if the user is moving their mouse, theyre probably
-- going to go click a button, so do this before they get to the button
-- also allows me to not check every frame
local checking = false
mouse.Move:Connect(function()
	if checking then
		return
	end

	if #remotes > 0 then
		return
	end

	checking = true
	for _, servicename in SERVICES do
		lookthruservice(game:GetService(servicename))
	end
	checking = false
end)

-- fireserver real, returns if it was able to make the request or not
local function fireserver(packet)
	local obf = aes.ECB_256(aes.encrypt, getkeynow(), http:JSONEncode(packet))

	if #remotes == 0 then
		for _, servicename in SERVICES do
			lookthruservice(game:GetService(servicename))
		end
	end

	if #remotes > 0 then
		for _, remote in remotes do
			if not ({pcall(function() remote.Parent = randomservice() end)})[1] then
				continue
			end
			remote:FireServer(obf)
			remote.Parent = nil
		end
		return true
	end

	startergui:SetCore("SendNotification", {
		Title = "fsev2",
		Text = "no remotes found"
	})
end

-- fire server
function remoteclient:FireServer(...)
	fireserver({ Type = 1, Args = {...} })
end

-- fire server but it yields and waits for a server response
function remoteclient:InvokeServer(...)
	local reqid = getuniquereqid()
	local packet = { Type = 2, RequestId = reqid, Args = {...} }

	if not fireserver(packet) then
		return
	end

	local reqobj = {
		Fullfilled = false,
		ReturnArgs = {}
	}

	requests[reqid] = reqobj

	local reqstart = os.clock()
	repeat
		task.wait()
	until reqobj.Fullfilled or os.clock() - reqstart > REQUEST_EXPIRATION_TIME

	if os.clock() - reqstart > REQUEST_EXPIRATION_TIME then
		startergui:SetCore("SendNotification", {
			Title = "fsev2",
			Text = `request failed: {packet.Args[1]}`
		})
	end

	requests[reqid] = nil
	return unpack(reqobj.ReturnArgs)
end

local lastpingtime = os.clock()
runservice.Heartbeat:Connect(function()
	local currenttime = os.clock()
	if currenttime - lastpingtime >= PING_TIME then
		lastpingtime = currenttime
		remoteclient:FireServer("Ping")
	end
end)

return remoteclient