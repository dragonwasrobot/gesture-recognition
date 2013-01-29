# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

# ## Classes

# The `Vector` encapsulates a vector's magnitude and direction.
class Vector
	constructor: (@x, @y) ->

# The `Position` encapsulates a point.
class Position
	constructor: (@x, @y) ->

# The `Direction` encapsulates a direction having a start- and endpoint.
class Direction
	constructor: (@positionStart, @positionStop, @vector) ->

# ## Functions

# ### Vectors

vectorFromPositions = (start, end) ->
	v = new Vector((start.x - end.x) * 100,	(start.y - end.y) * 100)

vectorFromDegrees = (degrees) ->
	v = new Vector(Math.cos(degrees), Math.sin(degrees))

vectorAngle = (v1, v2) ->
	radiansToDegrees(
		Math.acos vectorDotProduct(vectorNormalize(v1), vectorNormalize(v2)))

vectorAddition = (v1, v2) ->
	v = new Vector(v1.x + v2.x, v1.y + v2.y)

vectorLength = (v) -> Math.sqrt(v.x * v.x + v.y * v.y)

vectorDotProduct = (v1, v2) -> v1.x * v2.x + v1.y * v2.y

vectorNormalize = (v) ->
	length = vectorLength v
	normalized = new Vector(v.x / length, v.y / length)

# ### Metrics

sameDirection = (a1, a2) ->
	diffAngle = Math.abs(a1 - a2)
	return 0 <= diffAngle and diffAngle <= 30

oppositeDirection = (a1, a2) ->
	diffAngle = Math.abs(a1 - a2)
	return 150 <= diffAngle and diffAngle <= 210

radiansToDegrees = (radians) -> radians * (180 / Math.PI)

euclideanDistance = (q, p) -> Math.sqrt(Math.pow(q.x-p.x,2)+Math.pow(q.y-p.y,2))

measureTime = (start, stop) -> Math.abs(stop - start)
