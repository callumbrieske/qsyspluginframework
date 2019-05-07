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
    myPage = page:new{name = "Main Page"}   -- Create a page and capture its handle.
    page[2] = {name = "Other Page"}         -- Alternatively we can index 'page' directly.
    page:new{name = "Last Page"}            -- We can also create a page without capturing its handle.
    page[200] = {name = "New Last Page"}    -- The page array can also have 'holes' in it.

    
end

function plugin:code()
    print("Wow! Our Runtime code works!")
end

framework = {   -- Framework boilerplate & inheritance methods.

    _metatable = {

        immutableLocally = {},
        immutableDownstream = {
            _type = "framework"
        },
        immutableGlobally = {
            inherit = function(self, localData, immutableLocally, immutableDownstream, immutableGlobally, immutableRootKey)
                localData = type(localData) == "table" and localData or {}    -- Ensure that we have a table for the local data.
                localData._metatable = type(localData._metatable) == "table" and localData._metatable or {}    -- Ensure that we have a table for the local data.

                local _metatable = {
                    immutableLocally = setmetatable(type(immutableLocally) == "table" and immutableLocally or {}, {__index = self._metatable.immutableLocally}),
                    immutableDownstream = setmetatable(type(immutableDownstream) == "table" and immutableDownstream or {}, {__index = self._metatable.immutableDownstream}),
                    immutableGlobally = self._metatable.immutableGlobally,

                    __index = function(t, k)
                        print("__index", t, k)
                        return rawget(self, k) or t._metatable.immutableLocally[k] or t._metatable.immutableDownstream[k] or t._metatable.immutableGlobally[k]
                    end,

                    __newindex = function(t, k, v)
                        print("__newindex", t, k)
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
                for k, v in pairs(_metatable) do    -- Copy the new metamethods to the supplied local _metatable.
                    localData._metatable[k] = localData._metatable[k] or v  -- Do not overwrite any supplied metemethods.
                end

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

visual = framework:inherit(
    {   -- Local table.

    },
    {   -- Immutable Locally.

    },
    {   -- Immutable Downstream.
        _type = "visual prototype",

        newInstance = function(self, p, t)
            if self._type ~= "control index" then error("Only control indices can have instances. eg myKnob[1]:newInstance{{page1}, hPos = 10, vPos = 20}", 2) end -- Is this example correct?
            local function checkPage(v) if type(v) ~= "table" or v._type ~= "page" then error("Invalid page. A new instance can only exist on a page.", 2) end end
            if type(p) == "table" and #p > 0 then
                for _, v in pairs(p) do
                    checkPage(v)
                end
            else
                checkPage(v)
            end
        end
    },
    {   -- Immutable Global Table.

    }
)

page = visual:inherit(
    {   -- Local table.
        _metatable = {
            __newindex = function(t, k, v)  -- Special __newindex method to allow direct indexing via page[x] = {name = "new page"}
                if type(k) == "number" and type(v) == "table" and v.name and type(v.name) == "string" and not (rawget(t, k) == nil and t[k] ~= nil) then
                    return page:new{name = v.name, index = k}
                else
                    error("Invalid attempt to index page. Try the page:new{} method.", 2)
                end
            end
        }
    }, nil,
    {   -- Immutable Downstream.
        _type = "page prototype",

        new = function(self, t)
            if self ~= page then error("Invalid call to 'new'. Use page:new{}", 2) end
            if not t or type(t) ~= "table" then error("Failure to supply valid table for new.", 2) end
            if not t.name or type(t.name) ~= "string" then error("Failure to supply valid name for page.", 2) end
            if t.index and type(t.index) ~= "number" then error("Failure to supply valid index for page.", 2) end
            t.index = t.index or (#self + 1)    -- Find next index, or use supplied index.
            rawset(self, t.index, self:inherit({name = t.name}, nil, {_type = "page"}))    -- Create new page index.
			return self[t.index]	-- Return a handle to the new page.
        end,

        list = function()	-- Return a clean array of all pages.
			local pages = {}
            for i, p in pairs(page) do	-- Iterate through the 'page' array, and pass just the page.name.
                if type(i) == "number" and p~= nil then table.insert(pages, {name = p.name}) end
			end
			return pages
		end

    }
)

control = visual:inherit(
    {   -- Local table.

    },
    {   -- Immutable Locally.

    },
    {   -- Immutable Downstream.
        _type = "control framework",
        _controlObjects = {},

        newControl = function(self, t)
            if self._type ~= "control prototype" then error("Only new control types can be created. eg. knob:new{}", 2) end
            if not t.name or type(t.name) ~= "string" or t.name:len() < 1 then error("Failed to supply valid name for new control.", 2) end
            if control._metatable.immutableDownstream._controlObjects[t.name] then error("Control \"" .. t.name .. "\" already exists.", 2) end

            local name = t.name t.name = nil	-- Make t.name local.

            t._metatable = {
                __index = function(t, k)    -- Special metamethod to allow calling empty indexes instead on newIndex method.
                    if type(k) == "number" then
                        return self._metatable.immutableDownstream.newIndex(t, {}, k)   -- Index array using newIndex method.
                    else
                        return control._metatable.__index(t, k)    -- Index table using upstream method.
                    end
                end,

                __newindex = function(t, k, v)  -- Special metamethod to handle direct indexig.
                    if type(k) == "number" then
                        return self._metatable.immutableDownstream.newIndex(t, v, k)   -- Index array using newIndex method.
                    else
                        return control._metatable.__newindex(t, k, v)    -- Index table using upstream method.
                    end
                end,
            }

            control._metatable.immutableDownstream._controlObjects[name] = self:inherit(
                t,   -- Local table.
                {   -- Immutable Locally.
                    --new = {},   -- Blank table to block method downstream. Why did I put this here?
                },
                {   -- Immutable Downstream.
                    name = name,    -- Name cannot be changed after definition.
                    _type = "control"
                },
                {   -- Immutable Global Table.
            
                }
            )
            return control._metatable.immutableDownstream._controlObjects[name]
        end,

        newIndex = function(self, t, position)	-- Create a new index of the control.
            if self._type ~= "control" then error("Only control objects can be indexed.", 2) end
            if t and type(t) ~= "table" then error("Invalid argument. Table expected, got " .. type(t), 2) end

            local pages = {}
            local position = position ~= nil and position or ((type(t) == "table" and t.index ~= nil) and t.index or (#self + 1))	-- Get the index for the new control.
            
            if type(t) == "table" then
                t.index = nil	-- Ensure that index gets removed. This will be stored in the metatable.
                if type(t[1]) == "table" then
                    for i, v in pairs(t[1]) do
                        if v._isPage then table.insert(pages, v) end
                    end
                end
            else
                t = {}	-- Ensure that t is a table.
            end

            print(position)

            rawset(self, position, self:inherit(
                {   -- Local table.
            
                },
                {   -- Immutable Locally.

                },
                {   -- Immutable Downstream.
                    _type = "control index"
            
                },
                {   -- Immutable Global Table.
            
                }
            ))

            return self[position]

			--local cleanIndex = getmetatable(self).__index	-- Capture the deired index.
            
            --[[
			if getmetatable(self).__index[position] ~= nil then	-- self[k] protect agains overwrite. Is this necessary??
				error("Unable to create index. Control index " .. position .. " already exists.", 3)	-- Cant overwrite!
			else

				local pages = {}
				position = position ~= nil and position or ((type(t) == "table" and t.index ~= nil) and t.index or (#getmetatable(self).__index + 1))	-- Get the index for the new control.

				if type(t) == "table" then
					t.index = nil	-- Ensure that index gets removed. This will be stored in the metatable.
					if type(t[1]) == "table" then
						for i, v in pairs(t[1]) do
							if v._isPage then table.insert(pages, v) end
						end
					end
				else
					t = {}	-- Ensure that t is a table, and discard singular values.
				end

				rawset(getmetatable(self).__index, position, self:inherit(t, {index = position, _level = self._level + 1})) -- Maybe t should be writeable?
				getmetatable(self).__index[position]:unprotect(getmetatable(self).__index[position])

				


				

				getmetatable(getmetatable(self).__index[position]).__newindex = function(t, k, v)	-- Method to create a visual instance.
					if type(k) == "table" and k._isPage then
						print("Its a page!")
						rawset(t, k, t:inherit(v))
						t[k]:unprotect(t[k])
					else
						rawset(t, k, v)
					end
				end

				for _, v in ipairs(pages) do	-- If pages are supplied in method call, then create those tables in the new object.
					getmetatable(self).__index[position][v] = {}
					--getmetatable(self).__index[position][v]:unprotect(getmetatable(self).__index[position][v])
				end

                return getmetatable(self).__index[position]
                
			end
            --]]
        end,

        list = function()
			local controls = {}
			for name, p in pairs(control._metatable.immutableDownstream._controlObjects) do	-- Iterate through the '_controlObjects' table, build the control definitions table.
				print(name, p.unit, p.min, p.max, #p)
				local ctl = {}
				ctl["Name"] = name
				ctl["ControlType"] = p.controlType
				ctl["ControlUnit"] = p.unit
				ctl["Min"] = p.min
				ctl["Max"] = p.max
				ctl["Count"] = #p -- #p
				table.insert(controls, ctl)
			end
			return controls
		end,
    },
    {   -- Immutable Global Table.

    }
)

knob = control:inherit(
    {   -- Local table.

    },
    {   -- Immutable Locally.

    },
    {   -- Immutable Downstream.
        _type = "control prototype",
        _controlType = "Knob",

        new = function(self, t)
            if self ~= knob then error("Invalid call to 'new'. Use knob:new{}", 2) end
            if not t then error("Failed to supply valid table for new knob.", 2) end
            if not t.unit or not (t.unit == "Hz" or t.unit == "Float" or t.unit == "Integer" or t.unit == "Pan" or t.unit == "Percent" or t.unit == "Position" or t.unit == "Seconds") then error("Failed to supply valid unit type for new knob.", 2) end
            if not t.min then error("Failed to supply valid min value for new knob.", 2) end
            if not t.max then error("Failed to supply valid max value for new knob.", 2) end
            
            return self:newControl(t)
        end,
    },
    {   -- Immutable Global Table.

    }
)


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
















myPage = page:new{name = "Main Page"}   -- Create a page and capture its handle.
a = knob:new{name = "a", unit = "Integer", min = 0, max = 10}
b = knob:new{name = "b", unit = "Integer", min = 0, max = 10}
c = knob:new{name = "c", unit = "Integer", min = 0, max = 10}
d = knob:new{name = "d", unit = "Integer", min = 0, max = 10}




















if Controls then plugin:code() else PluginInfo = plugin:definition() end    -- If Controls have been defined run code, otherwise supply plugin definition to QSD.
function GetPrettyName(props)                                               -- Supply the prettyName to QSD.
    return plugin.prettyName or plugin.name
end
function GetProperties(props)                                               -- Supply properties definition to QSD.
    return plugin:properties(props)
end
function GetPages(props)                                                    -- Supply page definitions to QDS.
    if not plugin._layoutDefined then plugin:layout(props) end
    plugin._layoutDefined = true
    return page:list()
end
function GetControls(props)                                                 -- Supply controls definition to QSD.
    if not plugin._layoutDefined then plugin:layout(props) end
    plugin._layoutDefined = true
    --return controlsmethod
end
function GetControlLayout(props)                                            -- Supply layout information to QSD.
    if not plugin._layoutDefined then plugin:layout(props) end
    plugin._layoutDefined = true
    --return layoutmethod
end



-- Test junk:

function list(t, prefix)
    prefix = prefix or 0
    for i, v in pairs(t) do
        if type(v) == "table" then
            print("")
            print(("        "):rep(prefix) .. i .. " = {")
            --print(("    "):rep(prefix) .. "{")
            list(v, prefix + 1)
            print(("        "):rep(prefix) .. "}")
            print("")
        else
            print(("        "):rep(prefix) .. i, v)
        end
    end
end

