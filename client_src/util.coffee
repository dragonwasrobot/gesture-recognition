# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

# `util.coffee` contains a small range of convenience functions.

first = (arr) -> arr[0]

last = (arr) -> arr[(arr.length)-1]

log = (string) -> console.log string

map = (list, func) -> func(x) for x in list

filter = (list, func) -> x for x in list when func(x)

objectLength = (obj) ->
	length = 0
	for key, value of obj
		length += 1
	return length