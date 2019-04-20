local plugin = {}
do
	protect = setmetatable(	-- This is the root object. It contains various universal functions that will be inherited downstream. This entire object is immutable.
		{	-- Local data. This data can be changed on the local 'protect' function.
		
			wow = "Wow!",	-- Test data.
			_immutableKeys = {},
			
		},
		{	-- Metamethods.
		
			__index = {	-- Static data that is protected from change locally and downstream.
			
				checkMethod = function()	-- Check that a function was called using the ':' method operator.
					local caller = debug.getinfo(2)
					local _, self = debug.getlocal(2, 1)
					assert(type(self) == "table" and self[caller.name] == caller.func, "Attempt to call '" .. (caller.name or "unkown call") .. "' as function instead of method. Check for correct operator (use : instead of .)")
				end,
			
				inherit = function(self, localData, staticData)	-- Universal 'new' function. Other functions can be passed as tables to reside in the new object.
					protect.checkMethod()
					localData = localData or {}	-- Ensure the 'localData' table exists.
					localData["_immutableKeys"] = {}	-- Create a '_immutableKeys' value to allow keys to be immutable after the object is created.
					return setmetatable(
						localData,	-- This table hold data 'local' to the object. This can be changed after creation unless set as immutable after creation.
						{
							__index = setmetatable(
								staticData or {},	-- Ensure the 'staticData' table exists. This cannot be changed after object creation.
								{
									__index = self,
								}
							),
							__newindex = function(self, k, v)	-- Metamethod to check if key is immutable before setting. Raise an error if an overwrite is attempted on an immutable key.
								--print("Hit!", self, k, v)
								--if self._immutableKeys[k] ~= false and (self._immutableKeys[k] or self._immutableKeys[self] or self[k]) then	-- All by default are immutable.
								if self._immutableKeys[k] or self._immutableKeys[self] or self[k] then	-- Only static is immutable.
									error("Attempt to modify immutable table / key: " .. k or "", 2)
								end
								rawset(self, k, v)
							end,
							--__metatable = false,	-- Prevent anyone dicking with the metatable.
						}
					)
				end,
				
				protect = function(self, ...)	-- Set a key as immutable downstream.
					protect.checkMethod()
					for _, key in ipairs{...} do
						self._immutableKeys[key] = true
					end
				end,
				
				unprotect = function(self, ...)	-- Unset a key as immutable downstream.
					protect.checkMethod()
					for _, key in ipairs{...} do
						self._immutableKeys[key] = false
					end
				end,
				
			},
			
			__newindex = function(t, k, v) error("Attempt to modify immutable global table / key: " .. k or "", 2) end,	-- Prevent modification or creation of any keys.
			__metatable = false,	-- Prevent anyone dicking with the metatable.
			
		}
	)


	page = protect:inherit(	-- Handler for all plugin pages.
		{
		},
		{
			
			_pageObjects = {},	-- Table to hold the 'page' objects. This is protected from direct access.
			
			new = function(self, t)	-- Create a new page. This will return an optional handle to the page.
				assert(self == page, "Attempt to call 'new' as function instead of method. Check for correct operator (use : instead of .)")
				assert(t and type(t) == "table" and t.name, "Failure to supply valid table for new.")
				t.index = t.index or (#self._pageObjects + 1)
				--self._pageObjects[t.index] = getmetatable(getmetatable(page).__index).__index:new({name = t.name},{index = t.index})	-- Longhand way to make inheritance work when overwriting key.
				self._pageObjects[t.index] = self:inherit(
					{
						
						name = t.name
						
					},
					{
						
						index = t.index
						
					}
				)
				rawset(self, t.index, self._pageObjects[t.index])
				return self[t.index]	-- Return a handle to the new page.
			end,
			
		}
	)
	getmetatable(page).__newindex = function(t, k, v) 
		--print(t, k, v, type(k))
		if type(k) == "number" and v.name and type(v.name) == "string" then	-- Allow direct indexing via page[x] = {name = "new page"}
			page:new{name = v.name, index = k}
		else
			error("Invalid attempt to index page. Use page:new{} method.")
		end
	end


	visual = protect:inherit(
		{
		},
		{
		
			_visualObjects = {},
		
		}
	)
	getmetatable(visual).__newindex = function(t, k, v)
		error("Invalid attempt to index visual. Use visual:new{} method.")
	end


	control = visual:inherit(
		{
		},
		{
		
			_controlObjects = {},
		
			newControl = function(self, t)
				--assert(self == control, "Attempt to call 'new' as function instead of method. Check for correct operator (use : instead of .)")
				assert(t and type(t) == "table" and t.name and self.controlType, "Failure to supply valid table for new.")
				assert(not self._controlObjects[t.name], "A Control by the name '" .. t.name .. "' already exists.")
				control._controlObjects[t.name] = self:inherit({}, t)
				return control._controlObjects[t.name]
			end,
		
		}
	)
	getmetatable(control).__newindex = function(t, k, v)
		error("Invalid attempt to index control. Use control:new{} method.")
	end


	knob = control:inherit(
		{
		},
		{
			controlType = "Knob",
			
			new = function(self, t) return self:newControl(t) end	--function(self, t) return control.newControl(t) end,
		}
	)
	
	-- Q-Sys functions. These are called by QSD to generate the plugin layout.
	
	function GetPages()	-- Define pages for the plugin.
		local pages = {}
		for index, page in ipairs(page) do	-- Iterate through the 'page' table, and pass just the page.name.
			table.insert( pages, {name = page.name})
		end
		return pages
	end

	function GetProperties()	-- Define plugin properties.
		--return {}
	end
	
	function GetControls()	-- Define plugin controls.
	
	end
	
	function GetPluginInfo()	-- Generate global PluginInfo definition.
		PluginInfo = {Name = plugin.name .. " v" .. plugin.version, Description = plugin.description, Version = plugin.version,Id = plugin.guid, ShowDebug = plugin.showDebug}
	end

end

-- Name that will appear in the Schematic Library. (Putting ~ inbetween words makes second word the name in a folder called by the first word.)
plugin.name = "My Object Oriented Plugin"

-- This message is seen when a version mismatch occurs.
plugin.description = "A plugin where all control & graphic elements are objects"

-- A version number string. A differing version string will prompt the user whether to upgrade.
plugin.version = "0.1"

-- A unique hyphenated GUID. (guidgenerator.com)
plugin.guid = "5d98cfd3-8bd0-42c5-9768-d64e74bfd890"

-- Setting this to true will reveal the Lua debug window at the bottom of the UI.
plugin.showDebug = true


a = page:new{name = "Temp Name"}
b = page:new{name = "Page 2"}

a.name = "Better Name"

page:new{name = "Raw call"}

if Controls then	-- Runtime code lives here.
	print("Im running!")
end
GetPluginInfo()	-- Generate global PluginInfo definition. Do not remove.

