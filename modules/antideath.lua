	--print("antideath init")

	local tweenservice = game:GetService("TweenService")
	local http = game:GetService("HttpService")

	local antideath = {}
	local active = {}

	local bindableevent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/bindableevent.lua", true))()
	local propertyreference = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/propertyreference.lua", true))()

	local ZERO_WIDTH = "â€‹"

	-- defer without maximum depth reentry
	local defering = false
	local deferevent = Instance.new("BindableEvent")
	local function defer(f, ...)
		local args = {...}

		if not defering then
			defering = true
			task.defer(function()
				deferevent:Fire()
				defering = false
			end)
		end

		deferevent.Event:Once(function()
			f(unpack(args))
		end)
	end

	-- bc generateguid memory leaks to prevent duplicate guids
	-- dont need a really good randomstring just one that works
	local function randomstring()
		local s = ("."):rep(math.random(32, 132)):gsub(".", function()
			return string.char(math.random(32, 132))
		end)
		return s
	end

	-- look for unique attributes of this thing
	local function isantideath(any)
		return typeof(any) == "table" and any.BindToInstance ~= nil
	end

	-- do anything you need to do in the function, return whether or not itll pass
	-- true: pass, false: refit
	local CHANGED_SIGNAL = {
		Parent = function(self, currentparent, correctparent)
			return currentparent == correctparent
		end,
	}

	-- handle specific property changes, this will not automatically set the value on
	-- referenceinstance or unsyncedproperties for you
	local ON_CHANGE = {
		Parent = function(self, oldparent, newparent)
			newparent = active[newparent] or newparent

			if isantideath(oldparent) then
				table.remove(oldparent._Children, table.find(oldparent._Children, self))
			end

			if isantideath(newparent) then
				table.insert(newparent._Children, self)
			end

			self._UnsyncedProperties.Parent = newparent
			self.Instance.Parent = isantideath(newparent) and newparent.Instance or newparent
		end,
	}

	antideath.__index = function(self, idx)
		if antideath[idx] then
			return antideath[idx]
		end

		-- values in _Properties can be false as it represents an unsynced property
		if self._Properties[idx] ~= nil then
			return self._Properties[idx] and self.ReferenceInstance[idx] or self._UnsyncedPropeties[idx]
		end

		local attributeexists, any = pcall(function()
			return self.ReferenceInstance[idx]
		end)

		if attributeexists then
			if typeof(any) == "function" then
				-- return function that will turn the self passed into it into the
				-- actual instance
				return function(self2, ...)
					local inst = isantideath(self2) and self2.ReferenceInstance or self2
					return any(inst, ...)
				end
			end

			-- fake signals
			if typeof(any) == "RBXScriptSignal" then
				return self:GetEvent(idx)
			end

			return self.Instance[idx]
		end

		-- the children
		for _, child in self._Children do
			if child._UnsyncedProperties.Name == idx then
				return child
			end
		end
	end

	-- I LOVE NEWINDEX, allows me to handle property changes :DDDD
	antideath.__newindex = function(self, idx, val)
		-- only allow setting of properties
		if self._Properties[idx] ~= nil then
			local oldvalue = self._Properties[idx] and self.ReferenceInstance[idx] or self._UnsyncedProperties[idx]

			if ON_CHANGE[idx] then
				ON_CHANGE[idx](self, oldvalue, val)
				return
			end

			if self._Properties[idx] then
				self.ReferenceInstance[idx] = val
				return
			end

			self._UnsyncedProperties[idx] = val
			return
		end
		self.Instance[idx] = val
	end

	-- getpropertychangedsignal signals
	function antideath:ConnectPropertyChangedSignal(property)
		if self._Connections.Instance[`GetPropertyChangedSignal{property}`] then
			return
		end

		self._Connections.Instance[`GetPropertyChangedSignal{property}`] = self.Instance:GetPropertyChangedSignal(property):Connect(function()
			self._Events.GetPropertyChangedBindables[property]:Fire()
		end)
	end

	function antideath:GetPropertyChangedSignal(property)
		if not self._Events.GetPropertyChangedBindables[property] then
			local new = bindableevent.new()
			self._Events.GetPropertyChangedBindables[property] = new
			self._Events.GetPropertyChangedSignals[property] = new.Event

			self:ConnectPropertyChangedSignal(property)
		end
		return self._Events.GetPropertyChangedSignals[property]
	end

	-- regular event signals (Changed, Focused, FocusLost, etc)
	function antideath:ConnectEvent(eventname)
		if self._Connections.Instance[`Event{eventname}`] then
			return
		end

		self._Connections.Instance[`Event{eventname}`] = self.Instance[eventname]:Connect(function(...)
			self._Events.Bindables[eventname]:Fire(...)
		end)
	end

	function antideath:GetEvent(eventname)
		if not self._Events.Bindables[eventname] then
			local new = bindableevent.new()
			self._Events.Bindables[eventname] = new
			self._Events.Signals[eventname] = new.Event

			self:ConnectEvent(eventname)
		end

		return self._Events.Signals[eventname]
	end

	-- actually like antideath the instance lol
	function antideath:BindToInstance()
		assert(self.ReferenceInstance, "missing ReferenceInstance")

		for _, c in self._Connections.Instance do
			c:Disconnect()
		end
		table.clear(self._Connections.Instance)

		local inst = self.Instance
		local ref = self.ReferenceInstance

		local function correct(property, allowrefit)
			allowrefit = allowrefit == nil or allowrefit

			local currentvalue = inst[property]
			local correctvalue = self._Properties[property] and ref[property] or self._UnsyncedProperties[property]
			correctvalue = isantideath(correctvalue) and correctvalue.Instance or correctvalue

			if currentvalue == correctvalue then
				return true
			end

			if CHANGED_SIGNAL[property] and allowrefit then
				return CHANGED_SIGNAL[property](self, currentvalue, correctvalue)
			end

			inst[property] = correctvalue
			return true
		end

		for property in self._Properties do
			correct(property, false)
			self._Connections.Instance[`{property}Changed`] = inst:GetPropertyChangedSignal(property):Connect(function()
				if not correct(property) then
					defer(self.Refit, self)
				end
			end)
		end

		self._Connections.Instance.ChildAdded = inst.ChildAdded:Connect(function(newchild)
			for _, child in self._Children do
				if child.Instance == newchild then
					return
				end
			end
			task.defer(game.Destroy, newchild)
		end)

		for eventname in self._Events.Bindables do
			self:ConnectEvent(eventname)
		end

		for property in self._Events.GetPropertyChangedBindables do
			self:ConnectPropertyChangedSignal(property)
		end

		self._BoundEvent:Fire()
	end

	-- replace instance
	function antideath:Refit()
		assert(self.ReferenceInstance, "missing ReferenceInstance")

		for _, c in self._Connections.Instance do
			c:Disconnect()
		end
		table.clear(self._Connections.Instance)

		self.ReferenceInstance.Archivable = true

		local old = self.Instance
		local new = self.ReferenceInstance:Clone()

		self.ReferenceInstance.Archivable = false
		self.ReferenceInstance.Name = randomstring()

		-- avoid warnings
		task.defer(pcall, game.Destroy, old)

		active[old] = nil
		active[new] = self
		self.Instance = new

		self._RefittedEvent:Fire(new)
		self:BindToInstance()

		-- cannot rely on the above destroy call to trigger refits, did that one time
		-- for a fumo antideath and the face went missing after a single refit
		for _, child in self._Children do
			task.spawn(child.Refit, child)
		end
	end

	-- sync property to referenceinstnace
	function antideath:SyncProperty(property)
		local value = self._UnsyncedProperties[property]
		value = isantideath(value) and value.Instance or value
		self._Properties[property] = true
		self.ReferenceInstance[property] = value
	end

	-- unsync property from referenceinstance
	function antideath:UnsyncProperty(property)
		local value = self.ReferenceInstance[property]
		value = active[value] or value
		self._Properties[property] = false
		self._UnsyncedProperties[property] = value
	end

	-- set property of referenceinstace without resyncing the property
	function antideath:ShadowSync(property, value)
		self.ReferenceInstance[property] = value
	end

	-- set the value of an unsynced property without actually unsyncing the property
	function antideath:ShadowUnsync(property, value)
		self._UnsyncedProperties[property] = value
	end

	-- Bye Bye!
	function antideath:Destroy()
		for _, connections in self._Connections do
			for _, c in connections do
				c:Disconnect()
			end
		end

		self._RefittedEvent:Destroy()

		for _, bindable in self._Events.Bindables do
			bindable:Destroy()
		end

		for _, bindable in self._Events.GetPropertyChangedBindables do
			bindable:Destroy()
		end

		pcall(game.Destroy, self.ReferenceInstance)
		pcall(game.Destroy, self.Instance)

		if isantideath(self._UnsyncedProperties.Parent) then
			table.remove(self._UnsyncedProperties.Parent._Children, table.find(self._UnsyncedProperties.Parent._Children, self))
		end

		for _, child in self._Children do
			task.spawn(child.Destroy, child)
		end
	end

	-- tweenservice for antideaths
	antideath.TweenService = {}
	function antideath.TweenService:Create(inst, tweeninfo, props)
		inst = isantideath(inst) and inst.ReferenceInstance or inst
		return tweenservice:Create(inst, tweeninfo, props)
	end

	-- HELLO!!!
	function antideath.new(inst)
		if active[inst] then
			return active[inst]
		end

		local new = setmetatable({
			Instance = inst,
			ReferenceInstance = nil,

			_RefittedEvent = nil,
			Refitted = nil,

			_BoundEvent = nil,
			Bound = nil,

			-- for events connecting to the instance
			_Events = {
				GetPropertyChangedBindables = {},
				GetPropertyChangedSignals = {},
				Bindables = {},
				Signals = {}
			},
			_Children = {},
			_Properties = {},
			_UnsyncedProperties = {},
			_Connections = {
				Events = {},
				Instance = {},
				ReferenceInstance = {}
			}
		}, antideath)

		active[inst] = new

		do
			local refinst = inst:Clone()
			rawset(new, "ReferenceInstance", refinst)
			refinst:ClearAllChildren()
		end

		local refitevent = bindableevent.new()
		rawset(new, "_RefittedEvent", refitevent)
		rawset(new, "Refitted", refitevent.Event)

		local boundevent = bindableevent.new()
		rawset(new, "_BoundEvent", boundevent)
		rawset(new, "Bound", boundevent.Event)

		for class, properties in propertyreference do
			if not inst:IsA(class) then
				continue
			end

			-- when the referenceinstance changes, the actual instance will change
			-- allows for easy tweening
			for _, property in properties do
				new._Properties[property] = true
				new._Connections.ReferenceInstance[`{property}Changed`] = new.ReferenceInstance:GetPropertyChangedSignal(property):Connect(function()
					new.Instance[property] = new.ReferenceInstance[property]
				end)
			end
		end

		-- property setup
		new:UnsyncProperty("Parent")
		new:ShadowUnsync("Parent", active[inst.Parent] or inst.Parent)
		new:ShadowUnsync("Name", inst.Name)
		new:ShadowUnsync("Archivable", inst.Archivable)

		if inst:IsA("TextLabel") or inst:IsA("TextButton") then
			new.Text = new.Text:gsub(".", function(c)
				return ZERO_WIDTH:rep(math.random(0, 10)) .. c .. ZERO_WIDTH:rep(math.random(0, 10))
			end)
		end

		-- the children
		for _, child in inst:GetChildren() do
			table.insert(new._Children, antideath.new(child))
		end

		-- allowing the original instance to exist is kind of scuffed so itll refit first
		new:Refit()

		return new
	end

	return antideath