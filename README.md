# Q-Sys Object Oriented Plugin Framework

An object oriented framework for plugin development in the Q-Sys Lua environment. This is a work in progress. Only very basic features are implemented. The following features are intended for a future release:

## Intended Features

1. Simple & concise plugin definition. __DONE__
1. Single line page defintion.  __DONE__
1. Single line control definition. __DONE__
1. Single line property creation & rectification. __DONE__
1. Single line graphic element creation.
1. Z-Order is inherent, but can be modified with 'send back', 'send forward', 'send to back', and 'send to front' methods.
1. Alighment method such as pack and distribute for control and graphic elements.
1. Other things as they are thought of...

## TODO

1. Modify visual methods to allow Z-Order property.
1. Use hidden tables to prevent overwrites?
1. Add `__func` metamethods to allow a table to be supplied to controls when direct indexing.
1. Add support from graphic elements.
1. Create other control types. Only knob is done.

# Documentation

## Basic Layout

When using this framework, there are four function that you need to use. These are located at the beginning of the file for convenience. Below these four functions is the framework itself, editing the framework below these four functions is not advised.

### 1. Plugin Definition

This section is where you define the basic information about your plugin.

Example

```lua
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
    plugin.description = "A plugin where all control & graphic elements are objects"

    -- Setting this to true will show the Lua debug window at the bottom of the UI.
    plugin.showDebug = true
end
```

In this section, the following properties should be defined:

| Property | Required? | Description |
|---|---|---|
| `plugin.guid` | Yes | A unique hyphenated GUID. A simple online guid generator can be found at guidgenerator.com. |
| `plugin.version` | Yes | A version number string. A differing version string will prompt the user whether to upgrade. See semver.org for information on a sensible versioning scheme. |
| `plugin.name` | Yes | The name that will appear in the Schematic Library. (Putting ~ inbetween words makes second word the name in a folder named as the first word.) |
| `plugin.prettyName` | No | The name that will appear on the plugin icon, and in the title bar. (This is optional. If not supplied, plugin.name will be used.) |
| `plugin.description` | No | This message may be seen when a version mismatch occurs. |
| `plugin.showDebug` | Yes | Setting this to true will show the Lua debug window at the bottom of the UI. |

### 2. Plugin Properties

This section is where the properties show in the 'Properties' window in QSD are defined. See the section further in this document on the full syntaxt for property definitions.

Example

```lua
function plugin:properties()
    show = property:boolean{name = "Show other properties?", value = false} -- Define a boolean property, and capture its handle as 'show'.
    property:string{name = "My String", value = "A pretty sentence", rectify = function(self) self.hidden = show.value end)} -- Define a string property, and attach a rectify eventhandler to hide the control if 'show' is false.
    property:combo{name = "My ComboBox", choices = {"a", "b", "c"} value = "a", rectify = function(self) self.hidden = show.value end)} -- Define a combo property, and attach a rectify eventhandler to hide the control if 'show' is false.
end
```

### 3. Plugin Layout

This section is where you define the pages, controls, and visual elements for your plugin. See the sections titled 'Page Creation', and 'Control Creation' for the full syntax for page, control, and visual element definiton.

Example

```lua
function plugin:layout(props)
    mainPage = page:new{name = "Main"} -- Create a page and capture its handle.
    setupPage = page:new{name = "Setup"} -- Create a page and capture its handle.

    volume = knob:new{name = "Volume", unit = "dB", min = -100, max = 10} -- Create a knob control and capture its handle.

    volume[1][mainPage] = {width = 60, height = 150, style = "Fader", hPos = 10, vPos = 10} -- Show as fader on main page.
    volume[1][setupPage] = {width = 60, height = 60, style = "Knob", hPos = 10, vPos = 10} -- Show as knob on setup page.
end
```

### 4. Runtime Code

This is where your actual runtime code lives. All code that is to be executed at runtime should be encapsualted within the `plugin:code()` function. At runtime, propertes can be accessed using the global 'Properties' table. E.g. `Properties['My String'].Value`.

Example

```lua
function plugin:code()
    print("Wow! Our Runtime code works!")
end
```

## Page Creation
Plugins pages may be defined in several ways.

The most typical way to create a page is to use the `page:new{}` method. This method returns a handle that can be used when defining controls.

The page method must be supplied with a table containing a 'name' element. This defines the title for the page. Optionally you can also supply an 'index' index elemnt that specifies what index the new page should have. It it will result in an error if you supply an index that already exists.

Example:

```lua
myPage = page:new{name = "My Page"}
otherPage = page:new{name = "Other Page", index = 10}
```

It is also valid to define a page without capturing the handle, although this does make it diffucult to reference later.

Example:

```lua
page:new{name = "My Page"}
```

Pages can also be indexed directly using the following sytax:

```lua
page[200] = {name = "Page two hundred"}
```

## Control Creation

### Knobs

Knobs can be created using the `knob:new{}` method. This method must be supplied with a table containing the following elements:

| Key       | Type      | Description     |
|-----------|-----------|-----------|
| name      | String    | The runtime name for this control. |
| unit      | String    | The unit type that this knob should use. Can be dB, Hz, Float, Integer, Pan, Percent, Position or Seconds. |
| min       | Number    | The minimum value for this knob. |
| max       | Number    | The maximum value fot this knob. |

Faulure to supply all of these elements will result in an error.

Example

```lua
myKnob = knob:new{name = "My Knob", unit = "Integer", min = 0, max = 10}
```

The `knob:new{}` method returns a handle to the newly created control. You should capture this handle for use in creating control indexes, and visible instance of each index.

## Control Indexing

Each control can have one or more 'indexes'. 'indexes' are created using the `control:newIndex()` method. A table can optionally be supplied as the first arguemnt to this method, and will be passed into the new index object. This allows properties to be set to all child visual instances.

Example

```lua
firstIndex = myControl:newIndex({width = 50, height = 50})
secondIndex = myControls:newIndex()
```

When called in this manner, the index for the new element is automatically incremented. It is also possible to specify the index for the new control. This allows control indexes to be defined out of order.

There are two ways to acheive this, you can either specify the position in the second arguemnt, or as the element called 'index' in the table supplied in the first argument. The second argument takes precedent over the 'index' element if both are supplied.

Example

```lua
secondIndex = myControls:newIndex{index = 2)
firstIndex = myControl:newIndex({width = 50, height = 50}, 2)
thirdIndex = myControl:newIndex({index = 10}, 3) -- When both index methods are used, the second argument (3) takes precedence.
```

Using the `newIndex()` method may become somewhat clumsy & verbose, so an alternative is to simply access the new index on the control object. Special metamethods on the object pass new indexes to the newIndex method.

Example

```lua
-- Both of these produce the same result.
myControl:newIndex{index = 1, width = 50}
myControl[1] = {width = 50}
```

Each control __MUST__ have at least one 'index'. Controls with a single 'index' are refenced  in runtime using `Controls["Control Name"]`. Controls with multiple indexes become an array, and are referenced using `Controls["Controls Name"][index]`.

## Control Visual Instances

Each control 'index' can have __ONE__ visual instance one each page.

Visual instances are created using the `myIndex:newInstance{}` method. This method expects a table. Index 1 of this table should contant one or more page objects. Supplying an array of pages allows multiple instances to be defined simultaniously. All other values supplied in the table are passed to the new object.

Example

```lua
myIndex:newInstance{{myPage}, width = 10} -- Create one instance, and define the width for the new instance.
myIndex:newInstance{{page1, page2}, width = 10} --  Create a new instance on each of the supplied pages, and specify the width.
```

As with the `newIndex()` method, it is possible to index a control index directly using the page object. This can allow for exteremely concise control definition by chaing multiple methods together.

Example

```lua
myPage = page:new{name = "My Page"} -- Create a new page.

myKnob = knob:new{name = "My Knob", unt = "Integer", min = 0, max = 100} -- Define a new Control Object.

myKnob[1][myPage] = {width = 10, height = 50, style = "Fader"} -- In a single line we can create a control index, define a visual instance, and specify the properties for the new visual instance.
```

This method chaining can be taken even further.

Example

```lua
knob:new{name = "My Knob"}:[1][page:new{name = "My Page"}] = {width = 10} -- A single line defines the control, the page, and the visiual instance.
```
