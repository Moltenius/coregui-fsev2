

	local tabs = {}
	tabs.__index = tabs

	tabs.SelectedTab = nil
	tabs.Tabs = {}

	local antideath = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/antideath.lua", true))()
	local buttonify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/buttonify.lua", true))().new
	local remoteclient = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/remoteclient.lua", true))()
	local bindableevent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/bindableevent.lua", true))()

	local defaulttab
	local defaultsource = "print(\"Hello World!\")"
	local tabtemplate
	local container

	local tabselectedevent = bindableevent.new()
	tabs.TabSelected = tabselectedevent.Event

	-- make sure that script does not override script and instead turns into script(1)
	local function getuniquetabname(name)
		if not tabs.Tabs[name] then
			return name
		end

		local basename, num = name:match("(.+)%((%d+)%)$")

		if num then
			return getuniquetabname(basename .. "(" .. num + 1 .. ")")
		else
			return getuniquetabname(name .. "(1)")
		end
	end

	-- set tab button container
	function tabs.setcontainer(inst)
		container = inst
	end

	-- set tab template
	function tabs.settemplate(inst)
		tabtemplate = inst
	end

	-- set source for a tab to default to when it is created
	function tabs.setdefaultsource(src)
		defaultsource = src or "print(\"Hello World!\")"
	end

	-- set default tab to this name, tabs with the same name as this will not have a
	-- remove button
	function tabs.setdefaulttab(name)
		defaulttab = name
	end

	-- select a tab yay
	function tabs.selecttab(tabname)
		tabs.SelectedTab = tabname

		for othertabname, tab in tabs.Tabs do
			tab._Frame.BorderSizePixel = tabname == othertabname and 1 or 0
		end

		tabselectedevent:Fire(tabname)
	end

	-- die!!!!!!!!!
	function tabs:Destroy()
		for _, c in self._Connections do
			c:Disconnect()
		end

		for _, button in self._Buttons do
			button:Destroy()
		end

		self._Frame:Destroy()
		tabs.Tabs[self.Name] = nil

		if tabs.SelectedTab == self.Name then
			tabs.selecttab(defaulttab)
		end

		remoteclient:FireServer("SetTabSource", self.Name, nil)
	end

	-- set tab source in object and tell the server to update
	-- throttled
	function tabs:UpdateSource(src)
		if self.Source == src then
			return
		end

		self.Source = src
		remoteclient:FireServer("SetTabSource", self.Name, src)
	end

	-- get existing tab
	function tabs.get(tabname)
		return tabs.Tabs[tabname]
	end

	-- construct new tab
	function tabs.new(name, source)
		name = getuniquetabname(name)
		local new = setmetatable({
			Name = name,
			Source = source or defaultsource,

			_Frame = nil,
			_Connections = {},
			_Buttons = {
				SelectButton = nil,
				RemoveButton = nil,
			},
		}, tabs)

		local template = antideath.new(tabtemplate:Clone())
		template.Parent = container
		template.NameLabel.Text = name

		new._Frame = template
		new._Buttons.SelectButton = buttonify(template.NameLabel)

		if name == defaulttab then
			template.RemoveButton:Destroy()
		else
			new._Buttons.RemoveButton = buttonify(template.RemoveButton)
			new._Connections.RemoveOnClick = new._Buttons.RemoveButton.OnClick:Connect(function()
				new:Destroy()
			end)
		end

		new._Connections.OnClick = new._Buttons.SelectButton.OnClick:Connect(function()
			tabs.selecttab(new.Name)
		end)

		tabs.Tabs[name] = new

		if not tabs.SelectedTab then
			tabs.selecttab(name)
		end

		return new
	end

	return tabs