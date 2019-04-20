local plugin = {}

-- Name that will appear in the Schematic Library (putting ~ inbetween words makes second word the name in a folder called by the first word)
plugin.name = "My Object Oriented Plugin"

-- This message is seen when a version mismatch occurs.
plugin.description = "A plugin where all control & graphic elements are objects"

-- A version number string. A differing version string will prompt the user whether to upgrade.
plugin.version = "0.1"

-- A unique hyphenated GUID (guidgenerator.com)
plugin.guid = "5d98cfd3-8bd0-42c5-9768-d64e74bfd890"

-- Setting this to true will reveal the Lua debug window at the bottom of the UI
plugin.showDebug = true






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
		
			new = function(self, localData, staticData)	-- Universal 'new' function. Other functions can be passed as tables to reside in the new object.
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
			
			protect = function(self, key)	-- Set a key as immutable downstream.
				protect.checkMethod()
				self._immutableKeys[key] = true
			end,
			
			unprotect = function(self, key)	-- Unset a key as immutable downstream.
				protect.checkMethod()
				self._immutableKeys[key] = false
			end,
			
		},
		
		__newindex = function(t, k, v) error("Attempt to modify immutable global table / key: " .. k or "", 2) end,	-- Prevent modification or creation of any keys.
		__metatable = false,	-- Prevent anyone dicking with the metatable.
		
	}
)

page = protect:new(	-- Handler for all plugin pages.
	{
	},
	{
		
		_pages = {},	-- Table to hold the 'page' objects. This is protected from direct access.
		
		new = function(self, t)	-- Create a new page. This will return an optional handle to the page.
			assert(self == page, "Attempt to call 'new' as function instead of method. Check for correct operator (use : instead of .)")
			assert(t and type(t) == "table" and t.name, "Failure to supply valid table for new.")
			t.index = #self._pages + 1
			table.insert(self._pages, t)
			rawset(self, t.index, self._pages[t.index])
			print("Wow! It Works!", #self._pages)
			return self[t.index]
		end,
		
	}
)
getmetatable(page).__newindex = function(t, k, v) error("Attempt to index page directly. Use page:new{} method.") end

visual = protect:new(
	{
	},
	{
	}
)

control = visual:new()

knob = control:new()






a = page:new{name = "Temp Name"}
b = page:new{name = "Page 2"}

a.name = "Better Name"

page:new{name = "Raw call"}





local plugin = {}

-- Name that will appear in the Schematic Library (putting ~ inbetween words makes second word the name in a folder called by the first word)
plugin.name = "My Object Oriented Plugin"

-- This message is seen when a version mismatch occurs.
plugin.description = "A plugin where all control & graphic elements are objects"

-- A version number string. A differing version string will prompt the user whether to upgrade.
plugin.version = "0.1"

-- A unique hyphenated GUID (guidgenerator.com)
plugin.guid = "5d98cfd3-8bd0-42c5-9768-d64e74bfd890"

-- Setting this to true will reveal the Lua debug window at the bottom of the UI
plugin.showDebug = true


-- Static stuff. Don't dick with this.
	PluginInfo = {}
	PluginInfo.Name = plugin.name .. " v" .. plugin.version
	PluginInfo.Description = plugin.description
	PluginInfo.Version = plugin.version
	PluginInfo.Id = plugin.guid
	PluginInfo.ShowDebug = plugin.showDebug
	
	function GetPages()	-- Return all the pages for the plugin.
		local pages = {}
		for index, page in ipairs(page) do	-- Iterate through the 'page' table, and pass just the page.name.
			table.insert( pages, {name = page.name})
		end
		return pages
	end

	function GetProperties()
		--return {}
	end
	function GetControls()
	
	end


if Controls then	-- Runtime code lives here.
	print("Im running!")
end