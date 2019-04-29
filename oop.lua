local plugin
function PluginDefinition(caller, props)
	--_G.props = props or setmetatable({}, {__index = nil, __newindex = nil}) -- Friendly nils for undefined props.
	
	local function info()

		plugin = {}

		-- A unique hyphenated GUID. (guidgenerator.com)
		plugin.guid = "5d98cfd3-8bd0-42c5-9768-d64e74bfd890"

		-- A version number string. A differing version string will prompt the user whether to upgrade.
		plugin.version = "0.1"
		
		-- Name that will appear in the Schematic Library. (Putting ~ inbetween words makes second word the name in a folder called by the first word.)
		plugin.name = "My Object Oriented Plugin"

		-- Name that will appear on the plugin icon, and in the title bar. (This is optional. If not supplied plugin.name will be used.)
		plugin.prettyName = "My Object Oriented Plugin With A Pretty Name"

		-- This message may be seen when a version mismatch occurs.
		plugin.description = "A plugin where all control & graphic elements are objects"

		-- Setting this to true will reveal the Lua debug window at the bottom of the UI.
		plugin.showDebug = true

	end
	local function layout()
	
		-- Example page definitions:
		local a = page:new{name = "Temp Name"}	-- Define a new page, and capture its handle.
		local b = page:new{name = "Page 2"}		-- Define another page, and capture its handle.
		a.name = "Better Name"				-- Rename our first page using its handle.
		--page:new{name = "Raw call"}			-- Define a new page without a handle.
		--page[4] = {name = "Test"}			-- Define a new page directly. Use with caution. (page.__newindex metamethod calls page:new() to facilitate this behavour.)
		
		ka = knob:new{name = "knob1"}
		--ka.min = 0
		ka.max = 100
		--ka.unit = "Integer"
		--kb = knob:new{name = "knob2"}
		
	end
	local function runtime()
		print("Wow! We are running code!")
	end
	
	
	if caller == "info" then	-- Return plugin information table.
		info()
		layout()	-- Move this call. We should call this after the properties have been defined & rectified.
		return {Name = plugin.name, Description = plugin.description, Version = plugin.version, Id = plugin.guid, ShowDebug = plugin.showDebug}
	
	elseif caller == "name" then
		return plugin.prettyName and plugin.prettyName:len() > 0 and plugin.prettyName or plugin.name
	
	elseif caller == "pages" then	-- Return plugin pages.
		return page:list()
	
	elseif caller == "controls" then
		return control:list()
		
	elseif caller == "layout" then
		return visual:list(page:list()[props["page_index"].Value])
	
	elseif caller == "runtime" then
		return runtime
	
	end
end


protect = setmetatable(	-- This is the root object. It contains various universal functions that will be inherited downstream. This entire object is immutable.
	{	-- Local data. This data can be changed on the local 'protect' function, is immutable downstream.
	
		wow = "Wow!",	-- Test data.
		_immutableKeys = {},
		
	},
	{	-- Metamethods.
	
		__index = {	-- Static data that is immutable from change locally and downstream.
		
			checkMethod = function()	-- Check that a function was called using the ':' method operator.
				local caller = debug.getinfo(2)
				local _, self = debug.getlocal(2, 1)
				assert(type(self) == "table" and self[caller.name] == caller.func, "Attempt to call '" .. (caller.name or "unkown call") .. "' as function instead of method. Check for correct operator (use : instead of .)")
			end,
		
			inherit = function(self, localData, staticData)	-- Universal 'new' function. Other functions can be passed as tables to reside in the new object.
				protect.checkMethod()
				localData = localData or {}	-- Ensure the 'localData' table exists.
				localData["_immutableKeys"] = setmetatable({}, {__index = self._immutableKeys})	-- Create a '_immutableKeys' value to allow keys to be immutable after the object is created.
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
							if self._immutableKeys[k] ~= false and (self._immutableKeys[k] or self._immutableKeys[self] or self[k]) then	-- Only static is immutable.
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
		
		list = function()	-- Return a clean array of all pages.
			local pages = {}
			for i, p in ipairs(page) do	-- Iterate through the 'page' table, and pass just the page.name.
				table.insert(pages, {name = p.name})
			end
			return pages
		end
		
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
		height = 32,
		width = 32,
	},
	{
	
		_visualObjects = {},
		
		newVisual = function(self, t)
		
		end,

		list = function(self, t)
			print(t.name)
		end
	
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
			assert(t and type(t) == "table" and t.name and self.controlType, "Failure to supply valid table for new.")
			assert(not self._controlObjects[t.name], "A Control by the name '" .. t.name .. "' already exists.")
			local name = t.name t.name = nil	-- Move t.name to local.
			control._controlObjects[name] = self:inherit(t, {name = name})	-- Perhaps t should be unprotected?
			
			control._controlObjects[name].__newindexold = getmetatable(control._controlObjects[name]).__newindex	-- Tricks for control indexing.
			getmetatable(control._controlObjects[name]).__newindex = function(t, k, v)
				if type(k) == "number" then
					--t:newindex()
					error("Bugger Off!",2)
				else
					return control._controlObjects[name].__newindexold(t, k, v)
				end
			end
			
			return control._controlObjects[name]
		end,
		
		list = function()
			local controls = {}
			for _, p in pairs(control._controlObjects) do	-- Iterate through the '_controlObjects' table, build the control definitions table.
				print(p.name, p.unit, p.min, p.max, #p)
				local ctl = {}
				ctl["Name"] = p.name
				ctl["ControlType"] = p.controlType
				ctl["ControlUnit"] = p.unit
				ctl["Min"] = p.min
				ctl["Max"] = p.max
				ctl["Count"] = 1 -- #p
				table.insert(controls, ctl)
			end
			return controls
		end
	
	}
)
getmetatable(control).__newindex = function(t, k, v)
	error("Invalid attempt to index control. Use control:new{} method.")
end


knob = control:inherit(
	{
		blah = "blah",

		-- Default values.
		unit = "Integer",
		min = 0,
		max = 1,

	},
	{
		controlType = "Knob",
		
		new = function(self, t)	--function(self, t) return control.newControl(t) end,
			--assert(self == control, "Attempt to call 'new' as function instead of method. Check for correct operator (use : instead of .)")
			assert(
				t.name
				--and t.unit and (t.unit == "Hz" or t.unit == "Float" or t.unit == "Integer" or t.unit == "Pan" or t.unit == "Percent" or t.unit == "Position" or t.unit == "Seconds")
				--and (t.min and type(t.min) == "number")
				--and (t.max and type(t.max) == "number")
			, "Failure to supply valid table for new.")
			protect.checkMethod()
			local ctl = self:newControl(t)
			ctl:unprotect(
				--"controlType", -- do this only on indices.
				"unit",
				"min",
				"max"
			)
			return ctl
		end,
	}
)

-- Q-Sys functions. These are called by QSD to generate the plugin layout.

function GetPrettyName()
	return PluginDefinition("name")
end

function GetPages() return PluginDefinition("pages") end

function GetProperties()	-- Define plugin properties.
end

function GetControls(props) return PluginDefinition("controls", props) end

function GetControlLayout(props)
	local page = props["page_index"].Value
	return {
		["knob1"] = {
			Style = "Knob",
			Position = {10, 10},
			Size = {50, 50}
		}
	}, {}
end








if Controls then	-- Runtime code lives here.
	--print("Im running!")
	PluginDefinition("runtime")()
else
	PluginInfo = PluginDefinition("info")	-- Generate global PluginInfo definition. Do not remove.
end
