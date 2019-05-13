local plugin = {}   -- Do not remove.

function plugin:definition()
    -- A unique hyphenated GUID. See http://guidgenerator.com/
    plugin.guid = "dda1b925-231a-4960-887e-410879395f04"

    -- A version number string. A differing version string will prompt the user whether to upgrade. See https://semver.org/
    plugin.version = "1.0.0"

    -- Name that will appear in the Schematic Library. (Putting ~ inbetween words makes second word the name in a folder called by the first word.)
    plugin.name = "My Object Oriented Plugin v" .. self.version -- We can append the version number for convenience.

    -- Name that will appear on the plugin icon, and in the title bar. (This is optional. If not supplied plugin.name will be used.)
    plugin.prettyName = "My Object Oriented Plugin With A Pretty Name"

    -- This message may be seen when a version mismatch occurs.
    --plugin.description = "A plugin where all control & graphic elements are objects"

    -- Setting this to true will show the Lua debug window at the bottom of the UI.
    plugin.showDebug = true
end

function plugin:properties()
    show = property:boolean{name = "Show other properties?", value = false}
    property:string{name = "My String", value = "A pretty sentence", rectify = function(self) self.hidden = not show.value end}
    property:combo{name = "My ComboBox", choices = {"a", "b", "c"}, value = "a", rectify = function(self) self.hidden = not show.value end}
end

function plugin:layout(props)
    mainPage = page:new{name = "Main"} -- Create a page and capture its handle.
    setupPage = page:new{name = "Setup"} -- Create a page and capture its handle.

    volume = knob:new{name = "Volume", unit = "dB", min = -100, max = 10} -- Create a knob control and capture its handle.

    volume[1][mainPage] = {width = 60, height = 150, style = "Fader", hPos = 10, vPos = 10} -- Show as fader on main page.
    volume[1][setupPage] = {width = 60, height = 60, style = "Knob", hPos = 10, vPos = 10} -- Show as knob on setup page.
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
                    parent = self,
                    immutableLocally = setmetatable(type(immutableLocally) == "table" and immutableLocally or {}, {__index = self._metatable.immutableLocally}),
                    immutableDownstream = setmetatable(type(immutableDownstream) == "table" and immutableDownstream or {}, {__index = self._metatable.immutableDownstream}),
                    immutableGlobally = self._metatable.immutableGlobally,

                    __index = function(t, k)
                        --print("__index", t, k)    -- Degub __index calls.

                        local function get(t, k)    -- Fix to get localData inheritance without invoking special metamethods.
                            if t then
                                if rawget(t, k) or t == t._metatable.parent then
                                    return rawget(t, k)
                                else
                                    return get(t._metatable.parent, k)
                                end
                            end
                        end

                        --return rawget(self, k) or t._metatable.immutableLocally[k] or t._metatable.immutableDownstream[k] or t._metatable.immutableGlobally[k]
                        return get(t, k) or t._metatable.immutableLocally[k] or t._metatable.immutableDownstream[k] or t._metatable.immutableGlobally[k]
                    end,

                    __newindex = function(t, k, v)
                        --print("__newindex", t, k) -- Debug __newindex calls.
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

            copyTable = function(dest, source)  -- Copy table contents invoking metamethods.
                if type(source) == "table" then
                    for k, v in pairs(source) do
                        dest[k] = v
                    end
                end
            end,

            packArray = function(self, a)   -- This is pretty gross. There is probably a much cleaner way to do this.
                local tab = {}
                for i, v in pairs(a) do
                    if type(i) == "number" then
                        local cnt = 1
                        while (tab[cnt] and tab[cnt][1] < i) do
                            cnt = cnt + 1
                        end  
                        table.insert(tab, cnt, {i, v})
                    end
                end
                a = {}
                for i, v in ipairs(tab) do
                    a[i] = v[2]
                end
                return a
            end,

            checkType = function(self, t, v)    -- Ensure 'v' is of the type 't', otherwise teturn nil.
                return type(v) == t and v or nil
            end,

            number = function(self, v) return self:checkType("number", v) or 0 end, -- Check v is integer.

            string = function(self, v) return self:checkType("string", v) or "" end, -- Check v is string.
        },

    },

    bleh = 7

}
framework = framework._metatable.immutableGlobally.inherit(framework, nil, nil, nil, framework, true)    -- Make framework immutable.

property = framework:inherit(
    {   -- Local table.
    },
    {   -- Immutable Locally.

    },
    {   -- Immutable Downstream.
        _props = {},

        _new = function(self, t)
            if self ~= property then error("Invalid call. Must be used as method. Eg. property:number{}") end
            if type(t) ~= "table" then error("Invalid argument. Table expected, got " .. type(t), 2) end
            if type(t.name) ~= "string" then error("Failure to supply valid name for property.", 2) end
            if property._metatable.immutableDownstream._props[t.name] then error("A property named \"" .. t.name .. "\" already exists.", 2) end

            table.insert(property._metatable.immutableDownstream._props, t)  -- Move table to new _props object.
            return property._metatable.immutableDownstream._props[#property._metatable.immutableDownstream._props] -- Return handle for new property.
        end,

        boolean = function(self, t)
            if type(t) ~= "table" then error("Invalid argument. Table expected, got " .. type(t), 2) end
            t.value = t.value ~= nil and (not not t.value) or nil
            t.type = "boolean"
            return self:_new(t)
        end,

        number = function(self, t)
            if type(t) ~= "table" then error("Invalid argument. Table expected, got " .. type(t), 2) end
            if type(t.min) ~= "number" then error("Failure to supply 'min' for new integer property.", 2) end
            if type(t.max) ~= "number" then error("Failure to supply 'max' for new integer property.", 2) end
            t.value = t.value and tonumber(t.value) or nil  -- Ensure we are passing a number type.
            t.type = "double"   -- Do we need to differentiate between 'integer' and 'double' types?
            return self:_new(t)
        end,
        
        string = function(self, t)
            if type(t) ~= "table" then error("Invalid argument. Table expected, got " .. type(t), 2) end
            t.value = t.value and tostring(t.value) or nil  -- Ensure we are passing string type.
            t.type = "string"
            return self:_new(t)
        end,

        combo = function(self, t)
            if type(t) ~= "table" then error("Invalid argument. Table expected, got " .. type(t), 2) end
            if type(t.choices) ~= "table" or #t.choices < 1 then error("No choices supplied for the combobox property." .. #t.choices, 2) end
            t.value = t.value and tostring(t.value) or tostring(t.choices[1])  -- Ensure we are passing string type, and if no 'value' is supplied, use the 1st index of the 'choices' array.
            t.type = "enum"
            return self:_new(t)
        end,

        _list = function(self)   -- Reurn a list of properties formatted for the 'GetProperties' funciton.
            if not plugin._propsDefined then plugin:properties() plugin._propsDefined = true end
            local props = {}
            for i, v in ipairs(property._metatable.immutableDownstream._props) do
                table.insert(props,
                {
                    Name = v.name,
                    Type = v.type,
                    Value = v.value,
                    Min = (v.type == "double" or v.type == "integer") and v.min or nil,
                    Max = (v.type == "double" or v.type == "integer") and v.max or nil,
                    Choices = (v.type == "enum") and v.choices or nil,
                })
            end
            return props
        end,

        _rectify = function(self, props) -- Load plugin values, and invoke 'rectify' event handler functions when present. Add 'IsHidden' element & return props table.
            if not plugin._propsDefined then plugin:properties() plugin._propsDefined = true end
            for i, v in pairs(property._metatable.immutableDownstream._props) do
                v.value = props[v.name] and props[v.name].Value
            end
            for i, v in pairs(property._metatable.immutableDownstream._props) do
                if type(v.rectify) == "function" then v.rectify(v) end
                props[v.name].IsHidden = v.hidden
            end
            return props
        end,
    },
    {   -- Immutable Global Table.

    }
)

visual = framework:inherit(
    {   -- Local table.

    },
    {   -- Immutable Locally.

    },
    {   -- Immutable Downstream.
        _type = "visual prototype",

        newInstance = function(self, t)
            if self._type ~= "control index" then error("Only control indices can have instances. eg myKnob[1]:newInstance{{page1}, hPos = 10, vPos = 20}", 2) end -- Is this example correct?
            if not t or type(t) ~= "table" then error("Invalid argument. Table expected, got " .. type(t), 2) end
            if not t[1] then error("No pages supplied.", 2) end
            
            local function checkPage(v) if type(v) ~= "table" or v._type ~= "page" then error("Invalid page. A new instance can only exist on a page.", 2) end end
            local pageCnt, handle = 0, nil

            local function createInstance(page, t)
                pageCnt = pageCnt + 1
                if rawget(self, page) then error("This control already exists on '" .. page.name .. "'.", 2) end
                rawset(self, page, self:inherit(
                    --{   -- Local table.
                    --}
                    {},
                    {   -- Immutable Locally.
                
                    },
                    {   -- Immutable Downstream.
                        _type = "visual instance"
                    },
                    {   -- Immutable Global Table.
                
                    }
                ))

                self[page]:copyTable(t)  -- Copy table contents invoking metamethods.

                return self[page]
            end

            local pages = t[1] t[1] = nil   -- Make pages local.

            if type(pages) == "table" and #pages > 0 then   -- Make sure we have a valid page table.
                for _, page in pairs(pages) do
                    checkPage(page)
                    createInstance(pages, t)
                end
            else
                checkPage(pages)
                handle = createInstance(pages, t)    -- If we were only supplied a single page, we can return a handle.
            end

            if pageCnt < 1 then error("No pages supplied.", 2) end
            return handle
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

        list = function(self)	-- Return a clean array of all pages.
			local pages = {}
            for i, p in pairs(self:packArray(page)) do	-- Iterate through the 'page' array, and pass just the page.name.
                if type(i) == "number" and p~= nil then table.insert(pages, {name = p.name}) end
			end
			return pages
        end,

        currentPage = function(self, idx)	-- Return the currently active page object.
            return self:packArray(page)[idx]
        end,

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

            --local name = t.name --t.name = nil	-- Make t.name local.

            t._type = "control"

            control._metatable.immutableDownstream._controlObjects[t.name] = self:inherit(
                {   -- Local table.
                    _metatable = {
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
                },
                {   -- Immutable Locally.
                    --new = {},   -- Blank table to block method downstream. Why did I put this here?
                },
                --{   -- Immutable Downstream.
                --    name = name,    -- Name cannot be changed after definition.
                --    _type = "control"
                --},
                t,
                {   -- Immutable Global Table.
            
                }
            )

            return control._metatable.immutableDownstream._controlObjects[t.name]
        end,

        newIndex = function(self, t, position)	-- Create a new index of the control.
            if self._type ~= "control" then error("Only control objects can be indexed.", 2) end
            if t and type(t) ~= "table" then error("Invalid argument. Table expected, got " .. type(t), 2) end
            
            local position = position ~= nil and position or ((type(t) == "table" and t.index ~= nil) and t.index or (#self + 1))	-- Get the index for the new control.
            
            t = type(t) == "table" and t or {}  -- Ensure t is a table.
            t.index = nil   -- Ensure that t.index isnt passed to new object.

            if rawget(self, position) then error("Index alread exists", 2) end            

            -- Rawset to prevent invoking special metamethods.
            rawset(self, position, self:inherit(
                {   -- Local table.
                    _metatable = {
                        ---[[ We probably dont need this method. It works, but is kind of pointless.
                        __index = function(t, k)    -- Special metamethod to allow calling empty indexes instead on newIndex method.
                            if type(k) == "table" and k._type == "page" then
                                print("This is a page!")
                                return self._metatable.immutableDownstream.newInstance(t, {k})   -- Index array using newIndex method.
                            else
                                return control._metatable.__index(t, k)    -- Index table using upstream method.
                            end
                        end,
                        --]]
        
                        __newindex = function(t, k, v)  -- Special metamethod to handle direct indexig.
                            if type(k) == "table" and k._type == "page" then
                                if type(v) == "table" then
                                    v[1] = k
                                else
                                    v = {k}
                                end
                                return self._metatable.immutableDownstream.newInstance(t, v)   -- Index array using newIndex method.
                            else
                                return control._metatable.__newindex(t, k, v)    -- Index table using upstream method.
                            end
                        end,
                    }
                },
                {   -- Immutable Locally.

                },
                {   -- Immutable Downstream.
                    _type = "control index"
            
                },
                {   -- Immutable Global Table.
            
                }
            ))

            self[position]:copyTable(t)

            return self[position]
        end,

        list = function()   -- Return an array formatted for GetControls.
			local controls = {}
			for name, p in pairs(control._metatable.immutableDownstream._controlObjects) do	-- Iterate through the '_controlObjects' table, build the control definitions table.
				--print(name, p.unit, p.min, p.max, #p)   -- Debug contrlol listing,
				local ctl = {}
				ctl["Name"] = name
				ctl["ControlType"] = p._controlType
				ctl["ControlUnit"] = p.unit
				ctl["Min"] = p.min
				ctl["Max"] = p.max
				ctl["Count"] = #p
				table.insert(controls, ctl)
			end
			return controls
        end,

        layout = function(self, page)   -- Return a table formatted for GetControlLayout.
            local controls = {}
            for _, controlObject in pairs(control._metatable.immutableDownstream._controlObjects) do
                for i, controlIndex in pairs(controlObject) do  -- Using 'pairs' to prevent invoking special __index methods.
                    --print(i)
                    --print("Tick", controlObject.name, #controlObject, i)
                    --print(not not controlIndex[page])
                    ---[[
                    if rawget(controlIndex, page) then
                        print("Boo!", (#controlObject > 1) and (controlObject.name .. " " .. i) or controlObject.name)
                        controls[(#controlObject > 1) and (controlObject.name .. " " .. i) or controlObject.name] = {
                            Style = controlIndex[page].style,
                            Position = {self:number(controlIndex[page].hPos), self:number(controlIndex[page].vPos)},
                            Size = {self:number(controlIndex[page].width), self:number(controlIndex[page].height)},
                        }
                    end
                    --]]
                end
            end
            return controls
        end,

    },
    {   -- Immutable Global Table.

    }
)

knob = control:inherit(
    {   -- Local table.
        style = "Knob",
        width = 32,
        height = 32,
    },
    {   -- Immutable Locally.

    },
    {   -- Immutable Downstream.
        _type = "control prototype",
        _controlType = "Knob",

        new = function(self, t)
            if self ~= knob then error("Invalid call to 'new'. Use knob:new{}", 2) end
            if not t then error("Failed to supply valid table for new knob.", 2) end
            if not t.unit or not (t.unit == "dB" or t.unit == "Hz" or t.unit == "Float" or t.unit == "Integer" or t.unit == "Pan" or t.unit == "Percent" or t.unit == "Position" or t.unit == "Seconds") then error("Failed to supply valid unit type for new knob.", 2) end
            if not t.min then error("Failed to supply valid min value for new knob.", 2) end
            if not t.max then error("Failed to supply valid max value for new knob.", 2) end
            
            return self:newControl(t)
        end,
    },
    {   -- Immutable Global Table.

    }
)

button = control:inherit(
    {   -- Local table.
        style = "Button",
        width = 32,
        height = 16,
    },
    {   -- Immutable Locally.

    },
    {   -- Immutable Downstream.
        _type = "control prototype",
        _controlType = "Button",

        new = function(self, t)
            if self ~= button then error("Invalid call to 'new'. Use button:new{}", 2) end
            if not t then error("Failed to supply valid table for new button.", 2) end
            --if type(t.buttonType) ~= "string" or t.buttonType ~= "Trigger" then error("Failed to supply valid max value for new knob.", 2) end
            
            return self:newControl(t)
        end,
    },
    {   -- Immutable Global Table.

    }
)

if Controls then    -- If Controls have been defined run code, otherwise supply plugin definition to QSD.
    plugin:code()
else
    plugin:definition()
    plugin._pluginDefined = true
    PluginInfo =  {Name = plugin.name, Description = plugin.description, Version = plugin.version, Id = plugin.guid, ShowDebug = plugin.showDebug}
end
function GetPrettyName(props)                                               -- Supply the prettyName to QSD.
    return plugin.prettyName or plugin.name
end
function GetProperties()                                               -- Supply properties definition to QSD.
    return property:_list()
end
function RectifyProperties(props)                                           -- Decide which properties should be hidden.
    return property:_rectify(props)
end
function GetPages(props)                                                    -- Supply page definitions to QDS.
    if not plugin._layoutDefined then plugin:layout(props) end
    plugin._layoutDefined = true
    return page:list()
end
function GetControls(props)                                                 -- Supply controls definition to QSD.
    if not plugin._layoutDefined then plugin:layout(props) end
    plugin._layoutDefined = true
    return control:list()
end
function GetControlLayout(props)                                            -- Supply layout information to QSD.
    if not plugin._layoutDefined then plugin:layout(props) end
    plugin._layoutDefined = true
    return control:layout(page:currentPage(props["page_index"].Value))
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

