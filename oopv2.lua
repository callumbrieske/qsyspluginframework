plugin = {}
function plugin:definition()

    -- A unique hyphenated GUID. (guidgenerator.com)
    self.guid = "dda1b925-231a-4960-887e-410879395f04"

    -- A version number string. A differing version string will prompt the user whether to upgrade.
    self.version = "0.1.1"

    -- Name that will appear in the Schematic Library. (Putting ~ inbetween words makes second word the name in a folder called by the first word.)
    self.name = "My New Object Oriented Plugin v" .. self.version

    -- Name that will appear on the plugin icon, and in the title bar. (This is optional. If not supplied plugin.name will be used.)
    self.prettyName = "My New Object Oriented Plugin With A Pretty Name"

    -- This message may be seen when a version mismatch occurs.
    self.description = "A plugin where all control & graphic elements are objects"

    -- Setting this to true will show the Lua debug window at the bottom of the UI.
    self.showDebug = true


    self._pluginDefined = true
    return {Name = self.name, Description = self.description, Version = self.version, Id = self.guid, ShowDebug = self.showDebug}
end

function plugin:properties(props)

end

function plugin:layout(props)
    page:new{name = "Main Page"}
    --page:new{name = "Other Page"}
end

function plugin:code()
    print("Wow! Our Runtime code works!")
end

framework = {   -- Framework boilerplate & inheritance methods.

    _metatable = {

        immutableLocally = {},
        immutableDownstream = {},
        immutableGlobally = {
            inherit = function(self, localData, immutableLocally, immutableDownstream, immutableGlobally, immutableRootKey)
                localData = type(localData) == "table" and localData or {}    -- Ensure that we have a table for the local data.

                localData._metatable = {
                    immutableLocally = setmetatable(type(immutableLocally) == "table" and immutableLocally or {}, {__index = self._metatable.immutableLocally}),
                    immutableDownstream = setmetatable(type(immutableDownstream) == "table" and immutableDownstream or {}, {__index = self._metatable.immutableDownstream}),
                    immutableGlobally = self._metatable.immutableGlobally,

                    __index = function(t, k)
                        print("__index", k)
                        return rawget(self, k) or t._metatable.immutableLocally[k] or t._metatable.immutableDownstream[k] or t._metatable.immutableGlobally[k]
                    end,

                    __newindex = function(t, k, v)
                        print("__newindex", k)
                        if rawget(t._metatable.immutableLocally, k) ~= nil then
                            error("Attempt to change locally immutable key.", 2)
                        elseif t._metatable.immutableDownstream[k] ~= nil then
                            error("Attempt to change upstream immutable key.", 2)
                        elseif t._metatable.immutableGlobally[k] ~= nil then
                            error("Attempt to change globally immutable key.", 2)
                        elseif immutableRootKey then
                            error("Attempt to change globally immutable root key.", 2)
                        else
                            rawset(t, k, v)
                        end
                    end,
                }

                if type(immutableGlobally) == "table" then   -- Copy globals to global metatable.
                    for k, v in pairs(immutableGlobally) do
                        if localData._metatable.immutableGlobally[k] then
                            error("Attempt to change globally immutable root key.", 2)
                        end
                        localData._metatable.immutableGlobally[k] = v
                    end
                end

                return setmetatable(localData, localData._metatable)
            end,
        },

    },

}
framework = framework._metatable.immutableGlobally.inherit(framework, nil, nil, nil, framework, true)    -- Make framework immutable.

page = framework:inherit(
    {   -- Local table.

    },
    {   -- Immutable Locally.

    },
    {   -- Immutable Downstream.
        _isPage = true,

        new = function(self, t)
            if self ~= page then error("Attempt to call 'new' as function instead of method. Check for correct operator (use : instead of .)", 2) end
            if not t or type(t) ~= "table" or not t.name then error("Failure to supply valid table for new.", 2) end

            t.index = t.index or (#self + 1)
            print(t.index)
            rawset(self, t.index, self:inherit(
				{   -- Local table.

                    name = t.name

                },
                {   -- Immutable Locally.

                },
				{   -- Immutable Downstream.

				}
            ))
			return self[t.index]	-- Return a handle to the new page.
        end,

        list = function()	-- Return a clean array of all pages.
			local pages = {}
			for i, p in ipairs(page) do	-- Iterate through the 'page' table, and pass just the page.name.
				table.insert(pages, {name = p.name})
			end
			return pages
		end

    },
    {   -- Immutable Global Table.

    }
)
--page._metatable.__newindex = function() print("beep") end

--[[
page = framework:inherit(	-- Handler for all plugin pages.
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
					
					index = t.index,
					_isPage = true
					
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
--]]




--[[
page = framework:inherit(
    {   -- Local table.

    },
    {   -- Immutable Locally.

    },
    {   -- Immutable Downstream.

    },
    {   -- Immutable Global Table.

    }
)
--]]
































--t = framework:inherit({c = "tr"}, {a = "a"}, {b = "c"})
--t = framework:inherit({a = "a"},{b = "b"},{c = "c"})
--d = t:inherit(nil, nil, {c = "see!"})

--page:new()














function plugin:controls(props)
    if not self._layoutDefined then self:layout(props) end
    self._layoutDefined = true
    --return controlsmethod
end

function plugin:canvas(props)
    if not self._layoutDefined then self:layout(props) end
    self._layoutDefined = true
    --return layoutmethod
end

if Controls then plugin:code() else PluginInfo = plugin:definition() end    -- If Controls have been defined run code, otherwise supply plugin definition to QSD.
function GetPrettyName(props) return plugin.prettyName end                  -- Supply the prettyName to QSD.
function GetProperties(props) return plugin:properties(props) end           -- Supply properties definition to QSD.

function GetPages(props)                                                    -- Supply page definitions to QDS.
    if not plugin._layoutDefined then plugin:layout(props) end
    plugin._layoutDefined = true
    return page:list()
end

function GetControls(props) return plugin:controls(props) end               -- Supply controls definition to QSD.
function GetControlLayout(props) return plugin:canvas(props) end            -- Supply layout information to QSD.



-- Test junk:

function list(t)
	for i, v in pairs(t) do print(i, v) end
end