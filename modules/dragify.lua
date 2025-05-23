	local uis = game:GetService("UserInputService")
	--print("dragify init")

	local antichangetween = loadstring(game:HttpGet("https://raw.githubusercontent.com/Moltenius/coregui-fsev2/refs/heads/main/modules/antideath.lua", true))().TweenService

	local function dragify(frame, dragger)
		local dragtoggle = nil
		local dragspeed = 0.15
		local draginput = nil
		local dragstart = nil
		local dragpos = nil

		local PADDING = {
			Left = 0,
			Right = 150,
			Top = 0,
			Bottom = 80
		}

		local position
		local startpos

		local function updateInput(input)
			local delta = input.Position - dragstart
			position = UDim2.new(startpos.X.Scale, startpos.X.Offset + delta.X, startpos.Y.Scale, startpos.Y.Offset + delta.Y)
			antichangetween:Create(frame, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = position}):Play()
		end

		dragger.InputBegan:Connect(function(input)
			if (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) or uis:GetFocusedTextBox() ~= nil then
				return
			end

			dragtoggle = true
			dragstart = input.Position
			startpos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState ~= Enum.UserInputState.End then
					return
				end

				dragtoggle = false

				local vpsize = workspace.CurrentCamera.ViewportSize
				local endingposition

				if vpsize then
					endingposition = UDim2.new(
						0, math.clamp((vpsize.X * position.X.Scale + position.X.Offset), PADDING.Left, vpsize.X - PADDING.Right),
						0, math.clamp((vpsize.Y * position.Y.Scale + position.Y.Offset), PADDING.Top, vpsize.Y - PADDING.Bottom)
					)
				else
					endingposition = UDim2.new(
						position.X.Scale, (position.X.Offset), PADDING.Left, vpsize.X - PADDING.Right,
						position.Y.Scale, (position.Y.Offset), PADDING.Top, vpsize.Y - PADDING.Bottom
					)
				end

				antichangetween:Create(frame, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = endingposition}):Play()
			end)
		end)

		dragger.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				draginput = input
			end
		end)

		uis.InputChanged:Connect(function(input)
			if input == draginput and dragtoggle then
				updateInput(input)
			end
		end)
	end

	return dragify