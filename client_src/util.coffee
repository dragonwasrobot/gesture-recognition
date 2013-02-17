# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

# Initialize namespace
root = exports ? window
root.App = {}

# Add `first` and `last` functions to the `Array` class.
Array::first = () -> @[0]
Array::last = () -> @[@.length-1]

# Add a `length` function to the `Object` class.
#
# Returns the number of properties on the object minus length itself.
# Note: not sure if this is bad style.
ObjectLength = () ->
	length = 0
	for key, value of @
		if key isnt length
			length += 1
	return length

# Logging
App.log = (string) -> console.log string
