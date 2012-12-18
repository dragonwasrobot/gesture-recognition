# flick.coffee
#
# Receives TUIO events and infers a range of gestures based on the received
# event data.
#
# @author Peter Urbak
# @version 2012-12-18

# Cursor Gestures:
# - Single Tap
# - Double Tap
# - Flick
# - Press+Flick

# Object Gestures:
# - Shake

# Conventions:
# - Constants are prefixed by an underscore and written in all caps.
# - Fields are prefixed by an underscore and written in CamelCase.
# - Class methods are prefixed by an underscore and written in CamelCase.
# - Functions are written in CamelCase.

# Documentation:
# The constants specified at the top of the Table class should be adjusted
# according to the actual table and objects used.

root = exports ? window

# -*- Classes -*-

# * Helper Classes *

class Vector
	constructor: (@x, @y) ->

class Position
	constructor: (@x, @y) ->

class Cursor
	constructor: (@timestampStart, @timestampStop, \
		@positionStart, @positionStop) ->

class ObjectUpdate
	constructor: (@timestamp, @position) ->

class Direction
	constructor: (@positionStart, @positionStop, @vector) ->

# * Main Class *

class Table

	# * Constants *

	# Tap Constants
	_TAP_MIN_LENGTH: 0
	_TAP_MAX_LENGTH: 0.02
	_TAP_MIN_TIME: 0
	_TAP_MAX_TIME: 100

	# Double Tap Constants
	_DOUBLE_TAP_MIN_LENGTH: 0
	_DOUBLE_TAP_MAX_LENGTH: 0.04
	_DOUBLE_TAP_MIN_TIME: 0
	_DOUBLE_TAP_MAX_TIME: 200

	# Flick Constants
	_FLICK_MIN_LENGTH: 0.025
	_FLICK_MAX_LENGTH: 0.15
	_FLICK_MIN_TIME: 100
	_FLICK_MAX_TIME: 750
	_FLICK_MIN_DEGREE: 0
	_FLICK_MAX_DEGREE: 45

	# Pressed + Flick Constants
	_PRESSED_MIN_LENGTH: 0
	_PRESSED_MAX_LENGTH: 0.10

	# Shake Constants
	_SHAKE_MIN_LENGTH: 0.05
	_SHAKE_MAX_LENGTH: 0.20
	_SHAKE_MIN_TIME: 250
	_SHAKE_MAX_TIME: 2000 # Probably too large
	_SHAKE_MAX_DEGREE: 60

	# Other Constants
	_SPLICE_MAX_LENGTH: 0.025
	_OBJECT_UPDATE_FREQUENCY: 100
	_OBJECT_RELEVANCE_MAX_TIME: 2500
	_CURSOR_RELEVANCE_MAX_TIME: 1000
	_NEAREST_NEIGHBOR_MAX_LENGTH: 0.15

	_X_UNIT_VECTOR: { x : 1 , y : 0 }
	_Y_UNIT_VECTOR: { x : 0 , y : 1 }

	_SELECTED_COLOR: "rgba(100,45,214)"
	_FOLDED_COLOR: "rgba(214,135,45)"
	_UNFOLDED_COLOR: "rgb(45,214,24)"

	# * Constructors *
	constructor: () ->

		# Initialize fields
		@_models = {} # { sid , CommonObjectModel }
		@_objectsOnScreen = {} # { sid, CommonObjectModel }
		@_objectsSelected = {} # { sid, object }

		@_objectUpdates = {} # { sid, [ ObjectUpdate ] }

		@_cursorRecentTaps = [] # [ Cursor ]
		@_cursorCurrentPresses = {} # { sid : Cursor }

		# Setup TUIO
		@setupTUIO()

	# * Methods *

	setupTUIO: () ->
		tuio.object_add (object) =>
			@addTuioObject(object)

		tuio.object_update (object) =>
			@updateTuioObject(object)

		tuio.object_remove (object) =>
			@removeTuioObject(object)

		tuio.cursor_add (cursor) =>
			@addTuioCursor(cursor)

		tuio.cursor_update (cursor) =>
			@updateTuioCursor(cursor)

		tuio.cursor_remove (cursor) =>
			@removeTuioCursor(cursor)

	# * UI Event Listeners *

	# Objects

	addTuioObject: (object) ->
		log "addTuioObject"
		log object

		if not @_objectsOnScreen[object.sid]?
			model_object = new root.Model(object, root.surface, true)
			# model_object.setText object.fid
			@_models[object.sid] = model_object
			@_objectsOnScreen[object.sid] = model_object
			objectTimestamp = new Date().getTime()
			@_objectUpdates[object.sid] = []
			@_objectUpdates[object.sid].push(new ObjectUpdate(objectTimestamp,
				new	Position(object.x, object.y)))

	updateTuioObject: (object) ->
		objectTimestamp = new Date().getTime()
		model_object = @_objectsOnScreen[object.sid]
		angle = radiansToDegrees(object.angle)

		if model_object?
			# Update visuals.
			model_object.rotate(angle)
			model_object.moveToTUIOCord(object.x, object.y)

			# Update set of object updates.
			objectRecentUpdates = @_objectUpdates[object.sid]
			latestUpdate = lastElement(objectRecentUpdates)
			timeDiff = measureTime(latestUpdate.timestamp, objectTimestamp)

			# Add new entry if a sufficient amount of time has passed.
			if timeDiff >= 100
					objectRecentUpdates.push(new ObjectUpdate(objectTimestamp,
						new Position(object.x, object.y)))

					# Then remove old entries
					sliceIndex = 0
					for objectUpdate in objectRecentUpdates
						timeDiff = measureTime(objectUpdate.timestamp, objectTimestamp)
						if timeDiff >= @_OBJECT_RELEVANCE_MAX_TIME
							sliceIndex += 1
						else
							@_objectUpdates[object.sid] = objectRecentUpdates[sliceIndex...]
							break

					# Try to recognise a shake gesture
					if @checkShake(object, objectTimestamp)
						log "Shake Detected!"
						@foldUnfoldObject(object)

	removeTuioObject: (object) ->
		log "removeTuioObject"
		model_object = @_objectsOnScreen[object.sid]
		model_object.remove() # HTML tag bookkeeping
		delete @_objectsOnScreen[object.sid]
		delete @_models[object.sid]
		delete @_objectUpdates[object.sid]

	# Cursors

	addTuioCursor: (cursor) ->
		log "addTuioCursor"
		log cursor
		timestampStart = new Date().getTime()
		positionStart = new Position(cursor.x, cursor.y)
		@_cursorCurrentPresses[cursor.sid] =
			new Cursor(timestampStart, null, positionStart, null)

	updateTuioCursor: (cursor) -> # do nothing

	removeTuioCursor: (cursor) ->
		log "removeTuioCursor"
		log cursor
		timestampStop	= new Date().getTime()
		positionStop = new Position(cursor.x, cursor.y)
		oldCursorObj = @_cursorCurrentPresses[cursor.sid]
		delete @_cursorCurrentPresses[cursor.sid]
		cursorObj = new Cursor(oldCursorObj.timestampStart, timestampStop,
			oldCursorObj.positionStart, positionStop)

		if @checkSingleTap(cursorObj)
			log "Single Tap Detected!"

			if @checkDoubleTap(cursorObj)
				nearestNeighbor = @getNearestNeighborObject(cursorObj.positionStart)
				log "Double Tap Detected!"

				if objectLength(@_objectsSelected) > 0
					objectsSelected = @_objectsSelected
					for sid, object of objectsSelected
						@deselectObject(object)
						@foldUnfoldObject(object)

				else if nearestNeighbor?
					nearestNeighborModel = @_models[nearestNeighbor.sid]
					@deselectObject(nearestNeighbor)
					@foldUnfoldObject(nearestNeighbor)

			else
				nearestNeighbor = @getNearestNeighborObject(cursorObj.positionStart)
				@selectDeselectObject(nearestNeighbor) if nearestNeighbor?

			@_cursorRecentTaps.push(cursorObj)
		else if @checkFlick(cursorObj)
			# log "Flick Detected!"

			neighborQueryObject = cursorObj
			nearestNeighborCursor = @getNearestNeighborCursor(cursorObj.positionStart)
			if nearestNeighborCursor?
				log "Pressed+Flick Detected!"
				neighborQueryObject = nearestNeighborCursor

			nearestNeighbor = @getNearestNeighborObject(neighborQueryObject.positionStart)

			if nearestNeighbor?
					cursorVector = vectorFromPositions(cursorObj.positionStart, cursorObj.positionStop)
					cursorAngle = vectorAngle(cursorVector, @_Y_UNIT_VECTOR)

					if cursorObj.positionStop.x < cursorObj.positionStart.x
						cursorAngle = 360 - cursorAngle # A quick trigonometry hack.

					nearestNeighborModel = @_models[nearestNeighbor.sid]
					nearestNeighborAngle = radiansToDegrees(nearestNeighbor.angle)

					if sameDirection(cursorAngle, nearestNeighborAngle)
						@unfoldObject(nearestNeighbor)
					else if oppositeDirection(cursorAngle, nearestNeighborAngle)
						@foldObject(nearestNeighbor)

	# * Gesture Recognition *

	# * Shake Recognition *
	checkShake: (object, objectTimestamp) ->
		objectRecentUpdates = @_objectUpdates[object.sid]

		# Extract relevant updates
		relevantUpdates = []
		sliceIndex = 0
		for objectUpdate in objectRecentUpdates
			timeDiff = measureTime(objectUpdate.timestamp, objectTimestamp)
			if timeDiff >= @_SHAKE_MAX_TIME
				sliceIndex += 1
			else
				relevantUpdates = objectRecentUpdates[sliceIndex...]
				break

		if relevantUpdates.length < 10
			return false # Too few sample points
		else
			directionObjects = []
			currentPositionStart = relevantUpdates[0].position
			currentPositionStop = relevantUpdates[1].position
			oldPosition = relevantUpdates[1].position
			oldDirectionVector = vectorFromPositions(relevantUpdates[0].position,
				relevantUpdates[1].position)

			for objectUpdate in relevantUpdates[2...]
				newPosition = objectUpdate.position
				newDirectionVector = vectorFromPositions(oldPosition,
					newPosition)

				diffAngle = vectorAngle(oldDirectionVector, newDirectionVector)
				# log "diffAngle1:" + diffAngle
				# if newPosition.x < oldPosition.x
				#			diffAngle = 360 - diffAngle # A quick trigonometry hack.
					# log "diffAngle2:" + diffAngle

				# Check if same, or new, direction.
				if diffAngle <= @_SHAKE_MAX_DEGREE
					oldDirectionVector = vectorAddition(oldDirectionVector,
						newDirectionVector)
					currentPositionStop = newPosition
				else # A new direction has been taken (maybe)
					# Save old direction object
					# log "diffAngle: " + diffAngle
					directionObject = new Direction(currentPositionStart,
						currentPositionStop, oldDirectionVector)
					# log "new direction: " + directionObject
					directionObjects.push(directionObject)

					# Start recording the new direction
					currentPositionStart = oldPosition
					currentPositionStop = newPosition

				# Update pointers before next iteration
				oldPosition = newPosition
				oldDirectionVector = newDirectionVector

			# Make sense of the gathered vectors
			# log "Unfiltered directions"
			# for direction in directionObjects
			#			log("direction: ( (" + 100 * direction.positionStart.x + ", "
			#				100 * direction.positionStart.y + "), (" + 100 * direction.positionStop.x + ", " +
			#				100 * direction.positionStop.y + "), (" + direction.vector.x + ", "+
			#				direction.vector.y + ") )")

			# 1. Remove directions with too short a distance
			# refinedDirectionObjects = filter(directionObjects,
			#		((obj) -> euclideanDistance(obj.positionStart, obj.positionStop) >=
			#			@_SHAKE_MIN_LENGTH))

			refinedDirectionObjects = []
			for direction in directionObjects
							diffDistance = euclideanDistance(
								direction.positionStart, direction.positionStop)
							if diffDistance >= @_SHAKE_MIN_LENGTH
								refinedDirectionObjects.push(direction)

			log "Refined directions"
			for direction in refinedDirectionObjects
						log("direction: ( (" + 100 * direction.positionStart.x + ", " +
							100 * direction.positionStart.y + "), (" +
							100 *	direction.positionStop.x + ", " +
							100 * direction.positionStop.y + "), (" +
							direction.vector.x + ", "+ direction.vector.y + ") )")
					log("length: " + euclideanDistance(direction.positionStart,
						direction.positionStop))

			# 2. Splice neighbors if possible

			splicedDirectionObjects = []
			if refinedDirectionObjects.length > 1
				currentDirection = refinedDirectionObjects[0]
				i = 1
				for direction in refinedDirectionObjects[1...]
					if euclideanDistance(currentDirection.positionStop,
						direction.positionStart) <= @_SPLICE_MAX_LENGTH and
							vectorAngle(currentDirection.vector,
							direction.vector) <= @_SHAKE_MAX_DEGREE

						currentDirection = new Direction(currentDirection.positionStart,
							direction.positionStop, vectorAddition(currentDirection.vector,
							direction.vector))
					else
						splicedDirectionObjects.push(currentDirection)
						currentDirection = direction

					if i is refinedDirectionObjects.length - 1
						splicedDirectionObjects.push(currentDirection)
					i += 1

			log "Spliced directions"
			for direction in splicedDirectionObjects
				log("direction: ( (" + 100 * direction.positionStart.x + ", " +
					100 * direction.positionStart.y + "), (" + 100 *
					direction.positionStop.x + ", " + 100 * direction.positionStop.y +
					"), (" + direction.vector.x +	", " + direction.vector.y + ") )")

			# TEST DATA! LINE BELOW SHOULD BE REMOVED
			# splicedDirectionObjects = refinedDirectionObjects

			if splicedDirectionObjects.length > 2
				firstDirection = splicedDirectionObjects[0]
				secondDirection = splicedDirectionObjects[1]
				detectedShake = false
				for direction in splicedDirectionObjects[2...]

					diffFirstAngle = vectorAngle(firstDirection.vector,
						secondDirection.vector)
					diffSecondAngle = vectorAngle(secondDirection.vector,
						direction.vector)
					# log "diffFirstAngle: " + diffFirstAngle
					# log "diffSecondAngle: " + diffSecondAngle

					if diffFirstAngle >= 180 - @_SHAKE_MAX_DEGREE and
						diffSecondAngle >=	180 - @_SHAKE_MAX_DEGREE
							detectedShake = true
							break;

					firstDirection = secondDirection
					secondDirection = direction

				if detectedShake is true
					newObjectUpdate = new ObjectUpdate(objectTimestamp,
						new Position(object.x, object.y))

					@_objectUpdates[object.sid] = [ newObjectUpdate ]
					return true

			return false

	# * Single Tap Recognition *

	checkSingleTap: (cursorObj) ->
		log "checkSingleTap"
		# log cursorObj.timestampStart
		# log cursorObj.timestampStop
		timeDiff = measureTime(cursorObj.timestampStart, cursorObj.timestampStop)
		positionDiff = euclideanDistance(cursorObj.positionStart,
			cursorObj.positionStop)
		# log "timeDiff:" + timeDiff
		# log "positionDiff:" + positionDiff
		if @_TAP_MIN_TIME <= timeDiff and timeDiff <= @_TAP_MAX_TIME and
				@_TAP_MIN_LENGTH <= positionDiff and positionDiff <= @_TAP_MAX_LENGTH
			return true
		else
			return false

	# * Double Tap Recognition *

	checkDoubleTap: (cursorObj) ->
		log "checkDoubleTap"
		for cursor in @_cursorRecentTaps
			timeDiff = measureTime(cursorObj.timestampStop, cursor.timestampStop)
			posDiff = euclideanDistance(cursorObj.positionStop, cursor.positionStop)
			if (@_DOUBLE_TAP_MIN_TIME <= timeDiff and
			timeDiff <=	@_DOUBLE_TAP_MAX_TIME and
			@_DOUBLE_TAP_MIN_LENGTH <= posDiff and
			posDiff <= @_DOUBLE_TAP_MAX_LENGTH)
				# log "timeDiff:" + timeDiff
				# log "positionDiff:" + posDiff
				return true
		return false

	# * Pressed + Flick Recognition *

	getNearestNeighborCursor: (position) ->
			log "getNearestNeighborCursor"
			# Naive Linear Search
			nearestNeighborCursor = null
			nearestNeighborDist = 1

			for k, cursor of @_cursorCurrentPresses
				cursorPos = cursor.positionStart
				posDiff = euclideanDistance(position, cursorPos)

				if posDiff < nearestNeighborDist
					nearestNeighborDist = posDiff
					nearestNeighborCursor = cursor

			if nearestNeighborDist < @_NEAREST_NEIGHBOR_MAX_LENGTH
				return nearestNeighborCursor
			else
				return null

	# * Flick Recognition *

	checkFlick: (cursorObj) ->
		log "checkFlick"
		# Calculate the angle of the flick gesture.
		cursorVector = vectorFromPositions(cursorObj.positionStart,
			cursorObj.positionStop)
		cursorAngle = vectorAngle(cursorVector, @_Y_UNIT_VECTOR)
		if cursorObj.positionStop.x < cursorObj.positionStart.x
			cursorAngle = 360 - cursorAngle # A quick trigonometry hack.

		posDiff = euclideanDistance(cursorObj.positionStart, cursorObj.positionStop)
		timeDiff = measureTime(cursorObj.timestampStart, cursorObj.timestampStop)

		if posDiff > @_FLICK_MIN_LENGTH and posDiff < @_FLICK_MAX_LENGTH and
				timeDiff > @_FLICK_MIN_TIME and timeDiff < @_FLICK_MAX_TIME
			return true
		else
			return false

	getNearestNeighborObject: (position) ->
			log "getNearestNeighborObject"
			# Naive Linear Search
			nearestNeighborObj = null
			nearestNeighborDist = 1

			for object in tuio.objects
				if @_objectsOnScreen[object.sid]?
					objectPos = new Position(object.x, object.y)
					posDiff = euclideanDistance(position, objectPos)

					if posDiff < nearestNeighborDist
						nearestNeighborDist = posDiff
						nearestNeighborObj = object

			if nearestNeighborDist < @_NEAREST_NEIGHBOR_MAX_LENGTH
				return nearestNeighborObj
			else
				return null

	# * Object Manipulation *

	selectDeselectObject: (object) ->
		log "selectDeselectObject"
		model_object = @_models[object.sid]
		if model_object.selected is false
			@selectObject(object)
		else
			@deselectObject(object)

	selectObject: (object) ->
		log "selectObject"
		model_object = @_models[object.sid]
		if model_object.selected is false
			model_object.changeColor(@_SELECTED_COLOR)
			model_object.selected = true
			@_objectsSelected[object.sid] = object

	deselectObject: (object) ->
		log "deselectObject"
		model_object = @_models[object.sid]
		if model_object.selected is true
			if model_object.unfolded is true
				model_object.changeColor(@_UNFOLDED_COLOR)
			else
				model_object.changeColor(@_FOLDED_COLOR)
			model_object.selected = false
			delete @_objectsSelected[object.sid]

	foldUnfoldObject: (object) ->
		log "foldUnfoldObject"
		model_object = @_models[object.sid]
		if model_object.unfolded is false
			@unfoldObject(object)
		else
			@foldObject(object)

	unfoldObject: (object) ->
		log "unfoldObject"
		model_object = @_models[object.sid]
		model_object.changeColor(@_UNFOLDED_COLOR)
		model_object.unfolded = true

	foldObject: (object) ->
		log "hideObjectStats"
		model_object = @_models[object.sid]
		model_object.changeColor(@_FOLDED_COLOR)
		model_object.unfolded = false

# -*- Functions -*-

# Vectors

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

# Metrics

sameDirection = (a1, a2) ->
	diffAngle = Math.abs(a1 - a2)
	return 0 <= diffAngle and diffAngle <= 30

oppositeDirection = (a1, a2) ->
	diffAngle = Math.abs(a1 - a2)
	return 150 <= diffAngle and diffAngle <= 210

radiansToDegrees = (radians) -> radians * (180 / Math.PI)

euclideanDistance = (q, p) -> Math.sqrt(Math.pow(q.x-p.x,2)+Math.pow(q.y-p.y,2))

measureTime = (start, stop) -> Math.abs(stop - start)

lastElement = (arr) -> arr[(arr.length)-1]

# Misc

log = (string) -> # console.log string

map = (list, func) -> func(x) for x in list

filter = (list, func) -> x for x in list when func(x)

objectLength = (obj) ->
	length = 0
	for key, value of obj
		length += 1
	return length

# -*- Initialization -*-

$(document).ready () ->

	root._stylesheetDocs = {}
	root._modelDocs = {}

	root.surface = $("#surface")

	#Wait a bit and load stuff
	setTimeout () =>
		table = new Table()
		2000

# end-of-flick.coffee