protect = setmetatable(
	{	-- Local data. This data can be changed on the local 'protect' function.
	
		wow = "Wow!",	-- Test data.
		_protectedKeys = {},
		
	},
	{	-- Metamethods.
	
		__index = {	-- Static data that is protected from change locally and downstream.
		
			new = function(self, localData, staticData)	-- Universal 'new' function. Other functions can be passed as tables to reside in the new object.
				localData = localData or {}	-- Ensure the 'localData' table exists.
				localData["_protectedKeys"] = {}	-- Create a '_protectedKeys' value to allow keys to be protected after the object is created.
				return setmetatable(
					localData,	-- This table hold data 'local' to the object. This can be changed after creation unless 'protected' after creation.
					{
						__index = setmetatable(
							statidData or {},	-- Ensure the 'staticData' table exists. This cannot be changed after object creation.
							{
								__index = self,
							}
						),
						__newindex = function(self, k, v)	-- Metamethod to check if key is protected before setting. Raise an error if an overwrite is attempted on a protected key.
							print("Hit!", self, k, v)
							if self._protectedKeys[k] ~= false and (self._protectedKeys[k] or self._protectedKeys[self] or self[k]) then
								error("Attempt to modify protected table / key: " .. k or "", 2)
							end
							rawset(self, k, v)
						end,
						--__metatable = false,	-- Prevent anyone dicking with the metatable.
					}
				)
			end,
			
			protect = function(self, key)	-- Set a key as protected downstream.
				self._protectedKeys[key] = true
			end,
			
			unprotect = function(self, key)	-- Unset a key from being protected downstream.
				self._protectedKeys[key] = false
			end,
			
		},
		
		__newindex = function(t, k, v) error("Attempt to modify protected global table / key: " .. k or "", 2) end,	-- Prevent modification or creation of any keys.
		__metatable = false,	-- Prevent anyone dicking with the metatable.
		
	}
)