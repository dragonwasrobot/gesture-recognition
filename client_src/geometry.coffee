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

# Creates a vector from a start- and endpoint
#
# - **start:** The start position
# - **end:** The stop position
vectorFromPositions = (start, end) ->
	v = new Vector((start.x - end.x) * 100,	(start.y - end.y) * 100)

# Creates a vector from a degree value
#
# - **degrees:** The degrees
vectorFromDegrees = (degrees) ->
	v = new Vector(Math.cos(degrees), Math.sin(degrees))

# Returns the angle between two vectors
#
# - **v1:** The first vector
# - **v2:** The second vector
vectorAngle = (v1, v2) ->
	radiansToDegrees(
		Math.acos vectorDotProduct(vectorNormalize(v1), vectorNormalize(v2)))

# Adds two vectors
#
# - **v1:** The first vector
# - **v2:** The second vector
vectorAddition = (v1, v2) ->
	v = new Vector(v1.x + v2.x, v1.y + v2.y)

# Returns the length of a vector
#
# - **v:** The vector whose length should be calculated
vectorLength = (v) -> Math.sqrt(v.x * v.x + v.y * v.y)

# Returns the dot product of two vectors
#
# - **v1:** The first vector
# - **v2:** The second vector
vectorDotProduct = (v1, v2) -> v1.x * v2.x + v1.y * v2.y

# Returns the normalized version of the specified vector
#
# - **v:** The vector to be normalized.
vectorNormalize = (v) ->
	length = vectorLength v
	normalized = new Vector(v.x / length, v.y / length)

# ### Metrics

# Checks if two angles have approximately the same direction.
#
# - **a1:** The first angle
# - **a2:** The second angle
sameDirection = (a1, a2) ->
	diffAngle = Math.abs(a1 - a2)
	return 0 <= diffAngle and diffAngle <= 30

# Checks if two angles have approximately the opposite directions.
#
# - **a1:** The first angle
# - **a2:** The second angle
oppositeDirection = (a1, a2) ->
	diffAngle = Math.abs(a1 - a2)
	return 150 <= diffAngle and diffAngle <= 210

# Converts a radian value to degrees
#
# - **radians:** The radian value
radiansToDegrees = (radians) -> radians * (180 / Math.PI)

# Calculates the Euclidean distance between two position.
#
# - **q:** The first position
# - **p:** The second position
euclideanDistance = (q, p) -> Math.sqrt(Math.pow(q.x-p.x,2)+Math.pow(q.y-p.y,2))

# Calculates the difference between two points in time
#
# - **start:** The start value
# - **stop:** The stop value
measureTime = (start, stop) -> Math.abs(stop - start)
