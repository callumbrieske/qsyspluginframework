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
                    immutableGlobally = self._metatable.immutableGlobally,  --setmetatable(type(immutableGlobally) == "table" and immutableGlobally or {}, {__index = self._metatable.immutableGlobally}),

                    __index = function(t, k)
                        print("__index", k)
                        return rawget(self, k) or t._metatable.immutableLocally[k] or t._metatable.immutableDownstream[k] or t._metatable.immutableGlobally[k]
                    end,

                    __newindex = function(t, k, v)
                        print("__newindex", k)
                        if rawget(t._metatable.immutableLocally, k) ~= nil then
                            error("Attempt to change locally immutable key.", 2)
                        elseif rawget(t._metatable.immutableDownstream, k) ~= nil then
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

                if type(immutableGlobally) == "table" then
                    for k, v in pairs(immutableGlobally) do
                        if localData._metatable.immutableGlobally[k] then
                            error("Attempt to change globally immutable root key.", 2)
                        end
                        localData._metatable.immutableGlobally[k] = v   -- Copy globals to global metatable.
                    end
                end

                return setmetatable(localData, localData._metatable)
            end,
        },

    },

}
framework = framework._metatable.immutableGlobally.inherit(framework, nil, nil, nil, framework, true)    -- Make framework immutable.


--t = framework:inherit({c = "tr"}, {a = "a"}, {b = "c"})
t = framework:inherit({a = "a"},{b = "b"},{c = "c"})
d = t:inherit(nil, nil, {c = "see!"})















function plugin:controls(props)
    if not self._layoutDefined then self:layout(props) end
    self._layoutDefined = true
    --return controlsmethod
end

function plugin:pages(props)
    if not self._layoutDefined then self:layout(props) end
    self._layoutDefined = true
    --return pagemethod
end

function plugin:canvas(props)
    if not self._layoutDefined then self:layout(props) end
    self._layoutDefined = true
    --return layoutmethod
end

if Controls then plugin:code() else PluginInfo = plugin:definition() end    -- If Controls have been defined run code, otherwise supply plugin definition to QSD.
function GetPrettyName(props) return plugin.prettyName end  -- Supply the prettyName to QSD.
function GetProperties(props) return plugin:properties(props) end    -- Supply properties definition to QSD.
function GetControls(props) return plugin:controls(props) end -- Supply controls definition to QSD.
function GetControlLayout(props) return plugin:canvas(props) end    -- Supply layout information to QSD.



-- Test junk:

function list(t)
	for i, v in pairs(t) do print(i, v) end
end