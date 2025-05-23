	local plrs = game:GetService("Players")

	local localplayer = plrs.LocalPlayer
	local mouse = localplayer:GetMouse()
	--print("windowresize init")

	local resize = {
		X = 0,
		Y = 0
	}

	local bindableevent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/bindableevent.lua", true))()

	local event = bindableevent.new()
	local mousemove

	resize.SizeChanged = event.Event

	-- start dragging, both axes have a minimum of 0 so the gui doesnt collapse on itself
	function resize:Start()
		if mousemove then
			mousemove:Disconnect()
		end

		local startx, starty = mouse.X, mouse.Y
		local origx, origy = resize.X, resize.Y
		local lastx, lasty = origx, origy

		mousemove = mouse.Move:Connect(function()
			local newx, newy = math.max(origx + mouse.X - startx, 0), math.max(origy + mouse.Y - starty, 0)

			if lastx ~= newx or lasty ~= newy then
				lastx, lasty = newx, newy
				resize.X, resize.Y = newx, newy
				event:Fire(resize.X, resize.Y)
			end
		end)
	end

	-- stop dragging
	function resize:Stop()
		if mousemove then
			mousemove:Disconnect()
			mousemove = nil
		end
	end

	return resize