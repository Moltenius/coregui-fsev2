	--print("bindableevent init")

	local bindableevent = {}
	local event = {}
	local connection = {}
	bindableevent.__index = bindableevent
	event.__index = event
	connection.__index = connection


	function connection:Disconnect()
		self.Connected = false
		self._Callback = nil
		table.remove(self._Parent._Connections, table.find(self._Parent._Connections, self))
	end

	connection.disconnect = connection.Disconnect

	function connection.new(parentevent, callback, isonce)
		local new = setmetatable({
			Connected = true,

			_Parent = parentevent,
			_Once = isonce,
			_Callback = callback,
		}, connection)

		return new
	end


	function event:Connect(callback)
		local c = connection.new(self, callback)
		table.insert(self._Connections, c)
		return c
	end

	function event:Wait()
		local currentargs = self._LatestArgs
		repeat
			task.wait()
		until self._LatestArgs ~= currentargs
		return unpack(self._LatestArgs)
	end

	function event:Once(callback)
		local c = connection.new(self, callback, true)
		table.insert(self._Connections, c)
		return c
	end

	event.connect = event.Connect
	event.wait = event.Wait
	event.once = event.Once

	function event.new(name)
		local new = setmetatable({
			_Name = name,
			_LatestArgs = {},
			_Connections = {},
		}, event)

		return new
	end


	function bindableevent:Fire(...)
		self.Event._LatestArgs = {...}

		for i, connection in self.Event._Connections do
			task.spawn(connection._Callback, ...)

			if connection._Once then
				connection:Disconnect()
			end
		end
	end

	function bindableevent:Destroy()
		for _, c in self.Event._Connections do
			c:Disconnect()
		end
	end

	bindableevent.fire = bindableevent.Fire
	bindableevent.destroy = bindableevent.Destroy

	function bindableevent.new(name): BindableEvent
		local new = setmetatable({
			Event = event.new(name)
		}, bindableevent)

		return new
	end


	function bindableevent.isbindable(any)
		return typeof(any) == "table" and any.Event and any.Event._LatestArgs ~= nil
	end

	return bindableevent