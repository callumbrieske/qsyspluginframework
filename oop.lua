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
				localData["_protectedKeys"] = {}	-- Create a '_protectedKeys' value to allow keys to be protected after the object is created.
				return setmetatable(
					localData,	-- This table hold data 'local' to the object. This can be changed after creation unless 'protected' after creation.
					{
						__index = setmetatable(
							staticData or {},	-- Ensure the 'staticData' table exists. This cannot be changed after object creation.
							{
								__index = self,
							}
						),
						__newindex = function(self, k, v)	-- Metamethod to check if key is immutable before setting. Raise an error if an overwrite is attempted on an immutable key.
							--print("Hit!", self, k, v)
							--if self._immutableKeys[k] ~= false and (self._immutableKeys[k] or self._immutableKeys[self] or self[k]) then	-- Protect all by default.
							if self._immutableKeys[k] or self._immutableKeys[self] or self[k] then	-- Protect only static.
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
				self._protectedKeys[key] = true
			end,
			
			unprotect = function(self, key)	-- Unset a key as immutable downstream.
				protect.checkMethod()
				self._protectedKeys[key] = false
			end,
			
		},
		
		__newindex = function(t, k, v) error("Attempt to modify immutable global table / key: " .. k or "", 2) end,	-- Prevent modification or creation of any keys.
		__metatable = false,	-- Prevent anyone dicking with the metatable.
		
	}
)

visual = protect:new()

control = visual:new()

knob = control:new()