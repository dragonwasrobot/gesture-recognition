# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

# Initialize Namespace
root = exports ? window
root.App = {}

# `util.coffee` contains a small range of convenience functions.

App.first = (arr) -> arr[0]

App.last = (arr) -> arr[(arr.length)-1]

App.log = (string) -> console.log string

App.map = (list, func) -> func(x) for x in list

App.filter = (list, func) -> x for x in list when func(x)

App.objectLength = (obj) ->
	length = 0
	for key, value of obj
		length += 1
	return length