	--print("highlighter init")

	local lexer = (function() 
		--print("lexer init")

		local lexer = {}

		local Prefix, Suffix, Cleaner = "^[%c%s]*", "[%c%s]*", "[%c%s]+"
		local UNICODE = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]+"
		local NUMBER_A = "0[xX][%da-fA-F_]+"
		local NUMBER_B = "0[bB][01_]+"
		local NUMBER_C = "%d+%.?%d*[eE][%+%-]?%d+"
		local NUMBER_D = "%d+[%._]?[%d_eE]*"
		local OPERATORS = "[:;<>/~%*%(%)%-={},%.#%^%+%%]+"
		local BRACKETS = "[%[%]]+" -- needs to be separate pattern from other operators or it'll mess up multiline strings
		local IDEN = "[%a_][%w_]*"
		local STRING_EMPTY = "(['\"])%1" --Empty String
		local STRING_PLAIN = "(['\"])[^\n]-([^\\]%1)" --TODO: Handle escaping escapes
		local STRING_INTER = "`[^\n]-`"
		local STRING_INCOMP_A = "(['\"]).-\n" --Incompleted String with next line
		local STRING_INCOMP_B = "(['\"])[^\n]*" --Incompleted String without next line
		local STRING_MULTI = "%[(=*)%[.-%]%1%]" --Multiline-String
		local STRING_MULTI_INCOMP = "%[=*%[.-.*" --Incompleted Multiline-String
		local COMMENT_MULTI = "%-%-%[(=*)%[.-%]%1%]" --Completed Multiline-Comment
		local COMMENT_MULTI_INCOMP = "%-%-%[=*%[.-.*" --Incompleted Multiline-Comment
		local COMMENT_PLAIN = "%-%-.-\n" --Completed Singleline-Comment
		local COMMENT_INCOMP = "%-%-.*" --Incompleted Singleline-Comment
		-- local TYPED_VAR = ":%s*([%w%?%| \t]+%s*)" --Typed variable, parameter, function

		local lang = (function() 
			local language = {
				keyword = {
					["and"] = "keyword",
					["break"] = "keyword",
					["continue"] = "keyword",
					["do"] = "keyword",
					["else"] = "keyword",
					["elseif"] = "keyword",
					["end"] = "keyword",
					["export"] = "keyword",
					["false"] = "keyword",
					["for"] = "keyword",
					["function"] = "keyword",
					["if"] = "keyword",
					["in"] = "keyword",
					["local"] = "keyword",
					["nil"] = "keyword",
					["not"] = "keyword",
					["or"] = "keyword",
					["repeat"] = "keyword",
					["return"] = "keyword",
					["self"] = "keyword",
					["then"] = "keyword",
					["true"] = "keyword",
					["type"] = "keyword",
					["typeof"] = "keyword",
					["until"] = "keyword",
					["while"] = "keyword",
				},

				builtin = {
					-- Luau Functions
					["assert"] = "function",
					["error"] = "function",
					["getfenv"] = "function",
					["getmetatable"] = "function",
					["ipairs"] = "function",
					["loadstring"] = "function",
					["newproxy"] = "function",
					["next"] = "function",
					["pairs"] = "function",
					["pcall"] = "function",
					["print"] = "function",
					["rawequal"] = "function",
					["rawget"] = "function",
					["rawlen"] = "function",
					["rawset"] = "function",
					["select"] = "function",
					["setfenv"] = "function",
					["setmetatable"] = "function",
					["tonumber"] = "function",
					["tostring"] = "function",
					["unpack"] = "function",
					["xpcall"] = "function",

					-- Luau Functions (Deprecated)
					["collectgarbage"] = "function",

					-- Luau Variables
					["_G"] = "table",
					["_VERSION"] = "string",

					-- Luau Tables
					["bit32"] = "table",
					["coroutine"] = "table",
					["debug"] = "table",
					["math"] = "table",
					["os"] = "table",
					["string"] = "table",
					["table"] = "table",
					["utf8"] = "table",

					-- Roblox Functions
					["DebuggerManager"] = "function",
					["delay"] = "function",
					["gcinfo"] = "function",
					["PluginManager"] = "function",
					["require"] = "function",
					["settings"] = "function",
					["spawn"] = "function",
					["tick"] = "function",
					["time"] = "function",
					["UserSettings"] = "function",
					["wait"] = "function",
					["warn"] = "function",

					-- Roblox Functions (Deprecated)
					["Delay"] = "function",
					["ElapsedTime"] = "function",
					["elapsedTime"] = "function",
					["printidentity"] = "function",
					["Spawn"] = "function",
					["Stats"] = "function",
					["stats"] = "function",
					["Version"] = "function",
					["version"] = "function",
					["Wait"] = "function",
					["ypcall"] = "function",

					-- Roblox Variables
					["game"] = "Instance",
					["plugin"] = "Instance",
					["script"] = "Instance",
					["shared"] = "Instance",
					["workspace"] = "Instance",

					-- Roblox Variables (Deprecated)
					["Game"] = "Instance",
					["Workspace"] = "Instance",

					-- fse Variables
					["owner"] = "Instance",

					-- Roblox Tables
					["Axes"] = "table",
					["BrickColor"] = "table",
					["CatalogSearchParams"] = "table",
					["CFrame"] = "table",
					["Color3"] = "table",
					["ColorSequence"] = "table",
					["ColorSequenceKeypoint"] = "table",
					["DateTime"] = "table",
					["DockWidgetPluginGuiInfo"] = "table",
					["Enum"] = "table",
					["Faces"] = "table",
					["FloatCurveKey"] = "table",
					["Font"] = "table",
					["Instance"] = "table",
					["NumberRange"] = "table",
					["NumberSequence"] = "table",
					["NumberSequenceKeypoint"] = "table",
					["OverlapParams"] = "table",
					["PathWaypoint"] = "table",
					["PhysicalProperties"] = "table",
					["Random"] = "table",
					["Ray"] = "table",
					["RaycastParams"] = "table",
					["Rect"] = "table",
					["Region3"] = "table",
					["Region3int16"] = "table",
					["RotationCurveKey"] = "table",
					["task"] = "table",
					["TweenInfo"] = "table",
					["UDim"] = "table",
					["UDim2"] = "table",
					["Vector2"] = "table",
					["Vector2int16"] = "table",
					["Vector3"] = "table",
					["Vector3int16"] = "table",
				},

				libraries = {

					-- Luau Libraries
					bit32 = {
						arshift = "function",
						band = "function",
						bnot = "function",
						bor = "function",
						btest = "function",
						bxor = "function",
						countlz = "function",
						countrz = "function",
						extract = "function",
						lrotate = "function",
						lshift = "function",
						replace = "function",
						rrotate = "function",
						rshift = "function",
					},

					coroutine = {
						close = "function",
						create = "function",
						isyieldable = "function",
						resume = "function",
						running = "function",
						status = "function",
						wrap = "function",
						yield = "function",
					},

					debug = {
						dumpheap = "function",
						info = "function",
						loadmodule = "function",
						profilebegin = "function",
						profileend = "function",
						resetmemorycategory = "function",
						setmemorycategory = "function",
						traceback = "function",
					},

					math = {
						abs = "function",
						acos = "function",
						asin = "function",
						atan2 = "function",
						atan = "function",
						ceil = "function",
						clamp = "function",
						cos = "function",
						cosh = "function",
						deg = "function",
						exp = "function",
						floor = "function",
						fmod = "function",
						frexp = "function",
						ldexp = "function",
						log10 = "function",
						log = "function",
						max = "function",
						min = "function",
						modf = "function",
						noise = "function",
						pow = "function",
						rad = "function",
						random = "function",
						randomseed = "function",
						round = "function",
						sign = "function",
						sin = "function",
						sinh = "function",
						sqrt = "function",
						tan = "function",
						tanh = "function",

						huge = "number",
						pi = "number",
					},

					os = {
						clock = "function",
						date = "function",
						difftime = "function",
						time = "function",
					},

					string = {
						byte = "function",
						char = "function",
						find = "function",
						format = "function",
						gmatch = "function",
						gsub = "function",
						len = "function",
						lower = "function",
						match = "function",
						pack = "function",
						packsize = "function",
						rep = "function",
						reverse = "function",
						split = "function",
						sub = "function",
						unpack = "function",
						upper = "function",
					},

					table = {
						clear = "function",
						clone = "function",
						concat = "function",
						create = "function",
						find = "function",
						foreach = "function",
						foreachi = "function",
						freeze = "function",
						getn = "function",
						insert = "function",
						isfrozen = "function",
						maxn = "function",
						move = "function",
						pack = "function",
						remove = "function",
						sort = "function",
						unpack = "function",
					},

					utf8 = {
						char = "function",
						codepoint = "function",
						codes = "function",
						graphemes = "function",
						len = "function",
						nfcnormalize = "function",
						nfdnormalize = "function",
						offset = "function",

						charpattern = "string",
					},

					-- Roblox Libraries
					Axes = {
						new = "function",
					},

					BrickColor = {
						Black = "function",
						Blue = "function",
						DarkGray = "function",
						Gray = "function",
						Green = "function",
						new = "function",
						New = "function",
						palette = "function",
						Random = "function",
						random = "function",
						Red = "function",
						White = "function",
						Yellow = "function",
					},

					CatalogSearchParams = {
						new = "function",
					},

					CFrame = {
						Angles = "function",
						fromAxisAngle = "function",
						fromEulerAngles = "function",
						fromEulerAnglesXYZ = "function",
						fromEulerAnglesYXZ = "function",
						fromMatrix = "function",
						fromOrientation = "function",
						lookAt = "function",
						new = "function",

						identity = "CFrame",
					},

					Color3 = {
						fromHex = "function",
						fromHSV = "function",
						fromRGB = "function",
						new = "function",
						toHSV = "function",
					},

					ColorSequence = {
						new = "function",
					},

					ColorSequenceKeypoint = {
						new = "function",
					},

					DateTime = {
						fromIsoDate = "function",
						fromLocalTime = "function",
						fromUniversalTime = "function",
						fromUnixTimestamp = "function",
						fromUnixTimestampMillis = "function",
						now = "function",
					},

					DockWidgetPluginGuiInfo = {
						new = "function",
					},

					Enum = {},

					Faces = {
						new = "function",
					},

					FloatCurveKey = {
						new = "function",
					},

					Font = {
						fromEnum = "function",
						fromId = "function",
						fromName = "function",
						new = "function",
					},

					Instance = {
						new = "function",
					},

					NumberRange = {
						new = "function",
					},

					NumberSequence = {
						new = "function",
					},

					NumberSequenceKeypoint = {
						new = "function",
					},

					OverlapParams = {
						new = "function",
					},

					PathWaypoint = {
						new = "function",
					},

					PhysicalProperties = {
						new = "function",
					},

					Random = {
						new = "function",
					},

					Ray = {
						new = "function",
					},

					RaycastParams = {
						new = "function",
					},

					Rect = {
						new = "function",
					},

					Region3 = {
						new = "function",
					},

					Region3int16 = {
						new = "function",
					},

					RotationCurveKey = {
						new = "function",
					},

					task = {
						cancel = "function",
						defer = "function",
						delay = "function",
						desynchronize = "function",
						spawn = "function",
						synchronize = "function",
						wait = "function",
					},

					TweenInfo = {
						new = "function",
					},

					UDim = {
						new = "function",
					},

					UDim2 = {
						fromOffset = "function",
						fromScale = "function",
						new = "function",
					},

					Vector2 = {
						new = "function",

						one = "Vector2",
						xAxis = "Vector2",
						yAxis = "Vector2",
						zero = "Vector2",
					},

					Vector2int16 = {
						new = "function",
					},

					Vector3 = {
						fromAxis = "function",
						FromAxis = "function",
						fromNormalId = "function",
						FromNormalId = "function",
						new = "function",

						one = "Vector3",
						xAxis = "Vector3",
						yAxis = "Vector3",
						zAxis = "Vector3",
						zero = "Vector3",
					},

					Vector3int16 = {
						new = "function",
					},
				},
			}

			-- Filling up language.libraries.Enum table
			local enumLibraryTable = language.libraries.Enum

			for _, enum in ipairs(Enum:GetEnums()) do
				--TODO: Remove tostring from here once there is a better way to get the name of an Enum
				enumLibraryTable[tostring(enum)] = "Enum"
			end
			return language
		end)()
		local lua_keyword = lang.keyword
		local lua_builtin = lang.builtin
		local lua_libraries = lang.libraries

		lexer.language = lang

		local lua_matches = {
			-- Indentifiers
			{ Prefix .. IDEN .. Suffix, "var" },

			-- Numbers
			{ Prefix .. NUMBER_A .. Suffix, "number" },
			{ Prefix .. NUMBER_B .. Suffix, "number" },
			{ Prefix .. NUMBER_C .. Suffix, "number" },
			{ Prefix .. NUMBER_D .. Suffix, "number" },

			-- Strings
			{ Prefix .. STRING_EMPTY .. Suffix, "string" },
			{ Prefix .. STRING_PLAIN .. Suffix, "string" },
			{ Prefix .. STRING_INCOMP_A .. Suffix, "string" },
			{ Prefix .. STRING_INCOMP_B .. Suffix, "string" },
			{ Prefix .. STRING_MULTI .. Suffix, "string" },
			{ Prefix .. STRING_MULTI_INCOMP .. Suffix, "string" },
			{ Prefix .. STRING_INTER .. Suffix, "string_inter" },

			-- Comments
			{ Prefix .. COMMENT_MULTI .. Suffix, "comment" },
			{ Prefix .. COMMENT_MULTI_INCOMP .. Suffix, "comment" },
			{ Prefix .. COMMENT_PLAIN .. Suffix, "comment" },
			{ Prefix .. COMMENT_INCOMP .. Suffix, "comment" },

			-- Operators
			{ Prefix .. OPERATORS .. Suffix, "operator" },
			{ Prefix .. BRACKETS .. Suffix, "operator" },

			-- Unicode
			{ Prefix .. UNICODE .. Suffix, "iden" },

			-- Unknown
			{ "^.", "iden" },
		}

		-- To reduce the amount of table indexing during lexing, we separate the matches now
		local PATTERNS, TOKENS = {}, {}
		for i, m in lua_matches do
			PATTERNS[i] = m[1]
			TOKENS[i] = m[2]
		end

		--- Create a plain token iterator from a string.
		-- @tparam string s a string.

		function lexer.scan(s: string)
			local index = 1
			local size = #s
			local previousContent1, previousContent2, previousContent3, previousToken = "", "", "", ""

			local thread = coroutine.create(function()
				while index <= size do
					local matched = false
					for tokenType, pattern in ipairs(PATTERNS) do
						-- Find match
						local start, finish = string.find(s, pattern, index)
						if start == nil then continue end

						-- Move head
						index = finish + 1
						matched = true

						-- Gather results
						local content = string.sub(s, start, finish)
						local rawToken = TOKENS[tokenType]
						local processedToken = rawToken

						-- Process token
						if rawToken == "var" then
							-- Since we merge spaces into the tok, we need to remove them
							-- in order to check the actual word it contains
							local cleanContent = string.gsub(content, Cleaner, "")

							if lua_keyword[cleanContent] then
								processedToken = "keyword"
							elseif lua_builtin[cleanContent] then
								processedToken = "builtin"
							elseif string.find(previousContent1, "%.[%s%c]*$") and previousToken ~= "comment" then
								-- The previous was a . so we need to special case indexing things
								local parent = string.gsub(previousContent2, Cleaner, "")
								local lib = lua_libraries[parent]
								if lib and lib[cleanContent] and not string.find(previousContent3, "%.[%s%c]*$") then
									-- Indexing a builtin lib with existing item, treat as a builtin
									processedToken = "builtin"
								else
									-- Indexing a non builtin, can't be treated as a keyword/builtin
									processedToken = "iden"
								end
								-- print("indexing",parent,"with",cleanTok,"as",t2)
							else
								processedToken = "iden"
							end
						elseif rawToken == "string_inter" then
							if not string.find(content, "[^\\]{") then
								-- This inter string doesnt actually have any inters
								processedToken = "string"
							else
								-- We're gonna do our own yields, so the main loop won't need to
								-- Our yields will be a mix of string and whatever is inside the inters
								processedToken = nil

								local isString = true
								local subIndex = 1
								local subSize = #content
								while subIndex <= subSize do
									-- Find next brace
									local subStart, subFinish = string.find(content, "^.-[^\\][{}]", subIndex)
									if subStart == nil then
										-- No more braces, all string
										coroutine.yield("string", string.sub(content, subIndex))
										break
									end

									if isString then
										-- We are currently a string
										subIndex = subFinish + 1
										coroutine.yield("string", string.sub(content, subStart, subFinish))

										-- This brace opens code
										isString = false
									else
										-- We are currently in code
										subIndex = subFinish
										local subContent = string.sub(content, subStart, subFinish-1)
										for innerToken, innerContent in lexer.scan(subContent) do
											coroutine.yield(innerToken, innerContent)
										end

										-- This brace opens string/closes code
										isString = true
									end
								end
							end
						end

						-- Record last 3 tokens for the indexing context check
						previousContent3 = previousContent2
						previousContent2 = previousContent1
						previousContent1 = content
						previousToken = processedToken or rawToken
						if processedToken then
							coroutine.yield(processedToken, content)
						end
						break
					end

					-- No matches found
					if not matched then
						return
					end
				end

				-- Completed the scan
				return
			end)

			return function()
				if coroutine.status(thread) == "dead" then
					return
				end

				local success, token, content = coroutine.resume(thread)
				if success and token then
					return token, content
				end

				return
			end
		end

		function lexer.navigator()
			local nav = {
				Source = "",
				TokenCache = table.create(50),

				_RealIndex = 0,
				_UserIndex = 0,
				_ScanThread = nil,
			}

			function nav:Destroy()
				self.Source = nil
				self._RealIndex = nil
				self._UserIndex = nil
				self.TokenCache = nil
				self._ScanThread = nil
			end

			function nav:SetSource(SourceString)
				self.Source = SourceString

				self._RealIndex = 0
				self._UserIndex = 0
				table.clear(self.TokenCache)

				self._ScanThread = coroutine.create(function()
					for Token, Src in lexer.scan(self.Source) do
						self._RealIndex += 1
						self.TokenCache[self._RealIndex] = { Token, Src }
						coroutine.yield(Token, Src)
					end
				end)
			end

			function nav.Next()
				nav._UserIndex += 1

				if nav._RealIndex >= nav._UserIndex then
					-- Already scanned, return cached
					return table.unpack(nav.TokenCache[nav._UserIndex])
				else
					if coroutine.status(nav._ScanThread) == "dead" then
						-- Scan thread dead
						return
					else
						local success, token, src = coroutine.resume(nav._ScanThread)
						if success and token then
							-- Scanned new data
							return token, src
						else
							-- Lex completed
							return
						end
					end
				end
			end

			function nav.Peek(PeekAmount)
				local GoalIndex = nav._UserIndex + PeekAmount

				if nav._RealIndex >= GoalIndex then
					-- Already scanned, return cached
					if GoalIndex > 0 then
						return table.unpack(nav.TokenCache[GoalIndex])
					else
						-- Invalid peek
						return
					end
				else
					if coroutine.status(nav._ScanThread) == "dead" then
						-- Scan thread dead
						return
					else
						local IterationsAway = GoalIndex - nav._RealIndex

						local success, token, src = nil, nil, nil

						for _ = 1, IterationsAway do
							success, token, src = coroutine.resume(nav._ScanThread)
							if not (success or token) then
								-- Lex completed
								break
							end
						end

						return token, src
					end
				end
			end

			return nav
		end

		return lexer
	end)()

	local ZERO_WIDTH = "â€‹"

	local function randtext(text)
		local new = text:gsub(".", function(c)
			if math.random(0, 1) == 0 then
				return c
			else
				return ZERO_WIDTH:rep(math.random(0, 2)) .. c .. ZERO_WIDTH:rep(math.random(0, 2))
			end
		end)

		return new
	end

	local function sanitizerichtext(s: string): string
		return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;")
	end

	local function sanitizecontrols(s: string): string
		return s:gsub("[\0\1\2\3\4\5\6\7\8\11\12\13\14\15\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]+", "")
	end

	local colors = {} do
		local base = {
			background = Color3.fromRGB(47, 47, 47),
			--iden = Color3.fromRGB(234, 234, 234),
			iden = Color3.fromRGB(204, 204, 204),
			keyword = Color3.fromRGB(248, 109, 124),
			builtin = Color3.fromRGB(131, 206, 255),
			string = Color3.fromRGB(173, 241, 149),
			number = Color3.fromRGB(255, 198, 0),
			comment = Color3.fromRGB(102, 102, 102),
			operator = Color3.fromRGB(255, 239, 148)
		}

		for index, color : Color3 in next, base do
			local openbracket = `<font color="#{color:ToHex()}">`

			colors[index] = function(str, shouldrandtext)
				if shouldrandtext then
					str = randtext(str)
				end

				return `{openbracket}{sanitizerichtext(str)}</font>`
			end
		end
	end

	local function highlighttext(str, shouldrandtext)
		local newstring = ""

		for key, token in lexer.scan(sanitizecontrols(str)) do
			newstring ..= (colors[key] or colors.iden)(token, shouldrandtext)
		end

		return newstring
	end

	return highlighttext