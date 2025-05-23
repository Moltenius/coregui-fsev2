	--print("buttonify init")

	local buttonify = {}
	buttonify.__index = buttonify

	local bindableevent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/bindableevent.lua", true))()

	-- DIE! DIE! DIE! explosion sound sdfjdgbksdhngshdfbgshdfkg
	function buttonify:Destroy()
		for _, c in self._Connections do
			c:Disconnect()
		end

		for _, v in self do
			if bindableevent.isbindable(v) then
				v:Destroy()
			end
		end

		table.clear(self)
	end

	-- construct a fake button
	function buttonify.new(button)
		local new = setmetatable({
			_IsHovering = false,
			_OnClickEvent = bindableevent.new(),
			_DownEvent = bindableevent.new(),
			_UpEvent = bindableevent.new(),
			_EnterEvent = bindableevent.new(),
			_LeaveEvent = bindableevent.new(),
			_Connections = {}
		}, buttonify)

		new.OnClick = new._OnClickEvent.Event
		new.MouseDown = new._DownEvent.Event
		new.MouseUp = new._UpEvent.Event
		new.MouseEnter = new._EnterEvent.Event
		new.MouseLeave = new._LeaveEvent.Event

		local origbgcolor = button.BackgroundColor3

		new._Connections.MouseEnter = button.MouseEnter:Connect(function()
			new._IsHovering = true
			new._EnterEvent:Fire()
		end)

		new._Connections.MouseLeave = button.MouseLeave:Connect(function()
			new._IsHovering = false
			new._LeaveEvent:Fire()
		end)

		new._Connections.InputBegan = button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				button.BackgroundColor3 = Color3.new(math.min(origbgcolor.R + 0.2, 1), math.min(origbgcolor.G + 0.2, 1), math.min(origbgcolor.B + 0.2, 1))
				new._DownEvent:Fire()
			end
		end)

		new._Connections.InputEnded = button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				new._UpEvent:Fire()

				if not new._IsHovering then
					return
				end

				button.BackgroundColor3 = origbgcolor
				new._OnClickEvent:Fire()
			end
		end)

		return new
	end

	return buttonify