# Q-Sys Object Oriented Plugin Framework

An object oriented framework for plugin development in the Q-Sys Lua environment. This is a work in progress. Only very basic features are implemented. The following features are intended for a future release:

### Features

1. Simple & concise plugin definition. __DONE__
1. Single line page defintion.  __DONE__
1. Single line control definition. __DONE__
1. Single line property creation & rectification.
1. Simple alighment method such as pack and distribute for control and graphic elements.
1. Other things as they are thought of...

### TODO

1. Use hidden tables to prevent overwrites?
1. Add `__func` metamethods to allow a table to be supplied to controls when direct indexing.
1. Add support for plugin properties.
1. Add support for the RectifyProperties() function.
1. Add support from graphic elements.
1. Refactor plugin:definition() code to remove the requirement to return the data. This will make this section cleaner.

# Documentation

## Page Creation
Plugins pages may be defined in several ways.

The most typical way to create a page is to use the `page:new{}` method. This method returns a handle that can be used when defining controls.

The page method must be supplied with a table containing a 'name' element. This defines the title for the page. Optionally you can also supply an 'index' index elemnt that specifies what index the new page should have. It is an error to supply an index that already exists.

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
| unit      | String    | The unit type that this knob should use. Can be Hz, Float, Integer, Pan, Percent, Position or Seconds. |
| min       | Number    | The minimum value for this knob. |
| max       | Number    | The maximum value fot this knob. |

Faulure to supply all of these elements is an error.

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
