# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-28

# ## Classes

# The `GestureInterpreter` registers gestures and callback functions on the
# `TUIOInterpreter` and then dispatches on the received gesture updates from the
# `TUIOInterpreter`.
class GestureInterpreter

	# ### Constructors

	# Constructs a `GestureInterpreter`.
	#
	# - **table:** The `TableModel` to be manipulated.
	# - **tuioInterpreter:** The `TUIOInterpreter` to infer the gestures.
	constructor: (@table, @tuioInterpreter) ->
		@setupInterpreter()

	# ### Methods

	# Sets up the `GestureInterpreter` by registering callback functions on the
	# tuioInterpreter.
	setupInterpreter: () ->
		@tuioInterpreter.fingerTap @handleFingerTap
		@tuioInterpreter.fingerDoubleTap @handleFingerDoubleTap
		@tuioInterpreter.fingerHoldPlusTap @handleFingerHoldPlusTap
		@tuioInterpreter.objectShake @handleObjectShake

	# #### Finger Gestures

	handleFingerTap: (gesture) ->
		log "handleFingerTap"

	handleFingerDoubleTap: (gesture) ->
		log "handleFingerDoubleTap"

	handleFingerHoldPlusTap: (gesture) ->
		log "handleFingerHoldPlusTap"

	# #### Object Gestures

	handleObjectShake: (gesture) ->
		log "handleObjectShake"

class TUIOInterpreter

	# ### Constants

	# **Tap Constants**
	TAP_MIN_LENGTH: 0
	TAP_MAX_LENGTH: 0.02
	TAP_MIN_TIME: 0
	TAP_MAX_TIME: 100

	# **Double Tap Constants**
	DOUBLE_TAP_MIN_LENGTH: 0
	DOUBLE_TAP_MAX_LENGTH: 0.04
	DOUBLE_TAP_MIN_TIME: 0
	DOUBLE_TAP_MAX_TIME: 200

	# **Flick Constants**
	FLICK_MIN_LENGTH: 0.025
	FLICK_MAX_LENGTH: 0.15
	FLICK_MIN_TIME: 100
	FLICK_MAX_TIME: 750
	FLICK_MIN_DEGREE: 0
	FLICK_MAX_DEGREE: 45

	# **Pressed + Flick Constants**
	PRESSED_MIN_LENGTH: 0
	PRESSED_MAX_LENGTH: 0.10

	# **Shake Constants**
	SHAKE_MIN_LENGTH: 0.05
	SHAKE_MAX_LENGTH: 0.20
	SHAKE_MIN_TIME: 250
	SHAKE_MAX_TIME: 2000 # Probably too large
	SHAKE_MAX_DEGREE: 60

	# **Other Constants**
	SPLICE_MAX_LENGTH: 0.025
	OBJECT_UPDATE_FREQUENCY: 100
	OBJECT_RELEVANCE_MAX_TIME: 2500
	CURSOR_RELEVANCE_MAX_TIME: 1000
	NEAREST_NEIGHBOR_MAX_LENGTH: 0.15

	X_UNIT_VECTOR: { x : 1 , y : 0 }
	Y_UNIT_VECTOR: { x : 0 , y : 1 }

	# ### Constructors

	# Constructs a `TUIOInterpreter`.
	constructor: (@table) ->
		@objectUpdates = {} # { sid, [ ObjectUpdate ] }
		@cursorRecentTaps = [] # [ Cursor ]
		@cursorCurrentPresses = {} # { sid : Cursor }
		@setupTUIO()

	# ### Methods

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

	# #### Callbacks

	callbackFingerTap: (f) -> # stub
	callbackFingerDoubleTap: (f) -> # stub
	callbackFingerHoldPlusTap: (f) -> # stub
	callbackObjectShake: (f) -> # stub

	fingerTap : (f) -> @callbackFingerTap = f
	fingerDoubleTap : (f) -> @callbackFingerDoubleTap = f
	fingerHoldPlusTap : (f) -> @callbackFingerHoldPlusTap = f
	objectShake : (f) -> @callbackObjectShake = f

	# #### UI Event Listeners

	# ##### Objects

	addTuioObject: (object) ->
		if not @table.isObjectModelOnScreen(object.sid)?
			objectTimestamp = new Date().getTime()
			@objectUpdates[object.sid] = []
			@objectUpdates[object.sid].push(new ObjectUpdate(objectTimestamp,
				new	Position(object.x, object.y)))

	updateTuioObject: (object) ->
		objectTimestamp = new Date().getTime()
		modelObject = @table.getObjectModel(object.sid)
		angle = radiansToDegrees(object.angle)

		if modelObject?
			# Update visuals.
			modelObject.rotate(angle)
			modelObject.moveToTUIOCord(object.x, object.y)

			# Update set of object updates.
			objectRecentUpdates = @objectUpdates[object.sid]
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
						if timeDiff >= @OBJECT_RELEVANCE_MAX_TIME
							sliceIndex += 1
						else
							@objectUpdates[object.sid] = objectRecentUpdates[sliceIndex...]
							break

					# Try to recognise a shake gesture
					if @checkShake(object, objectTimestamp)
						log "Shake Detected!"
						@foldUnfoldObject(object)

	removeTuioObject: (object) ->
		delete @objectUpdates[object.sid]
		@table.removeObjectModel(object)

	# ##### Cursors

	addTuioCursor: (cursor) ->
		timestampStart = new Date().getTime()
		positionStart = new Position(cursor.x, cursor.y)
		@cursorCurrentPresses[cursor.sid] =
			new Cursor(timestampStart, null, positionStart, null)

	updateTuioCursor: (cursor) -> # do nothing

	removeTuioCursor: (cursor) ->
		timestampStop	= new Date().getTime()
		positionStop = new Position(cursor.x, cursor.y)
		oldCursorObj = @cursorCurrentPresses[cursor.sid]
		delete @cursorCurrentPresses[cursor.sid]
		cursorObj = new Cursor(oldCursorObj.timestampStart, timestampStop,
			oldCursorObj.positionStart, positionStop)

		if @checkSingleTap(cursorObj)
			log "Single Tap Detected!"

			if @checkDoubleTap(cursorObj)
				nearestNeighbor = @getNearestNeighborObject(cursorObj.positionStart)
				log "Double Tap Detected!"

				if objectLength(@objectsSelected) > 0
					objectsSelected = @objectsSelected
					for sid, object of objectsSelected
						@deselectObject(object)
						@foldUnfoldObject(object)

				else if nearestNeighbor?
					nearestNeighborModel = @models[nearestNeighbor.sid]
					@deselectObject(nearestNeighbor)
					@foldUnfoldObject(nearestNeighbor)

			else
				nearestNeighbor = @getNearestNeighborObject(cursorObj.positionStart)
				@selectDeselectObject(nearestNeighbor) if nearestNeighbor?

			@cursorRecentTaps.push(cursorObj)
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
					cursorAngle = vectorAngle(cursorVector, @Y_UNIT_VECTOR)

					if cursorObj.positionStop.x < cursorObj.positionStart.x
						cursorAngle = 360 - cursorAngle # A quick trigonometry hack.

					nearestNeighborModel = @models[nearestNeighbor.sid]
					nearestNeighborAngle = radiansToDegrees(nearestNeighbor.angle)

					if sameDirection(cursorAngle, nearestNeighborAngle)
						@unfoldObject(nearestNeighbor)
					else if oppositeDirection(cursorAngle, nearestNeighborAngle)
						@foldObject(nearestNeighbor)

	# #### Gesture Recognition

	# ##### Shake Recognition
	checkShake: (object, objectTimestamp) ->
		objectRecentUpdates = @objectUpdates[object.sid]

		# Extract relevant updates
		relevantUpdates = []
		sliceIndex = 0
		for objectUpdate in objectRecentUpdates
			timeDiff = measureTime(objectUpdate.timestamp, objectTimestamp)
			if timeDiff >= @SHAKE_MAX_TIME
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
				if diffAngle <= @SHAKE_MAX_DEGREE
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
							if diffDistance >= @SHAKE_MIN_LENGTH
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
						direction.positionStart) <= @SPLICE_MAX_LENGTH and
							vectorAngle(currentDirection.vector,
							direction.vector) <= @SHAKE_MAX_DEGREE

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

					if diffFirstAngle >= 180 - @SHAKE_MAX_DEGREE and
						diffSecondAngle >=	180 - @SHAKE_MAX_DEGREE
							detectedShake = true
							break;

					firstDirection = secondDirection
					secondDirection = direction

				if detectedShake is true
					newObjectUpdate = new ObjectUpdate(objectTimestamp,
						new Position(object.x, object.y))

					@objectUpdates[object.sid] = [ newObjectUpdate ]
					return true

			return false

	# ##### Single Tap Recognition

	checkSingleTap: (cursorObj) ->
		log "checkSingleTap"
		# log cursorObj.timestampStart
		# log cursorObj.timestampStop
		timeDiff = measureTime(cursorObj.timestampStart, cursorObj.timestampStop)
		positionDiff = euclideanDistance(cursorObj.positionStart,
			cursorObj.positionStop)
		# log "timeDiff:" + timeDiff
		# log "positionDiff:" + positionDiff
		if @TAP_MIN_TIME <= timeDiff and timeDiff <= @TAP_MAX_TIME and
				@TAP_MIN_LENGTH <= positionDiff and positionDiff <= @TAP_MAX_LENGTH
			return true
		else
			return false

	# ##### Double Tap Recognition

	checkDoubleTap: (cursorObj) ->
		log "checkDoubleTap"
		for cursor in @_cursorRecentTaps
			timeDiff = measureTime(cursorObj.timestampStop, cursor.timestampStop)
			posDiff = euclideanDistance(cursorObj.positionStop, cursor.positionStop)
			if (@DOUBLE_TAP_MIN_TIME <= timeDiff and
			timeDiff <=	@DOUBLE_TAP_MAX_TIME and
			@DOUBLE_TAP_MIN_LENGTH <= posDiff and
			posDiff <= @DOUBLE_TAP_MAX_LENGTH)
				# log "timeDiff:" + timeDiff
				# log "positionDiff:" + posDiff
				return true
		return false

	# ##### Pressed + Flick Recognition

	getNearestNeighborCursor: (position) ->
			log "getNearestNeighborCursor"
			# Naive Linear Search
			nearestNeighborCursor = null
			nearestNeighborDist = 1

			for k, cursor of @cursorCurrentPresses
				cursorPos = cursor.positionStart
				posDiff = euclideanDistance(position, cursorPos)

				if posDiff < nearestNeighborDist
					nearestNeighborDist = posDiff
					nearestNeighborCursor = cursor

			if nearestNeighborDist < @NEAREST_NEIGHBOR_MAX_LENGTH
				return nearestNeighborCursor
			else
				return null

	# ##### Flick Recognition

	checkFlick: (cursorObj) ->
		log "checkFlick"
		# Calculate the angle of the flick gesture.
		cursorVector = vectorFromPositions(cursorObj.positionStart,
			cursorObj.positionStop)
		cursorAngle = vectorAngle(cursorVector, @Y_UNIT_VECTOR)
		if cursorObj.positionStop.x < cursorObj.positionStart.x
			cursorAngle = 360 - cursorAngle # A quick trigonometry hack.

		posDiff = euclideanDistance(cursorObj.positionStart, cursorObj.positionStop)
		timeDiff = measureTime(cursorObj.timestampStart, cursorObj.timestampStop)

		if posDiff > @FLICK_MIN_LENGTH and posDiff < @FLICK_MAX_LENGTH and
				timeDiff > @FLICK_MIN_TIME and timeDiff < @FLICK_MAX_TIME
			return true
		else
			return false

	getNearestNeighborObject: (position) ->
			log "getNearestNeighborObject"
			# Naive Linear Search
			nearestNeighborObj = null
			nearestNeighborDist = 1

			for object in tuio.objects
				if @objectsOnScreen[object.sid]?
					objectPos = new Position(object.x, object.y)
					posDiff = euclideanDistance(position, objectPos)

					if posDiff < nearestNeighborDist
						nearestNeighborDist = posDiff
						nearestNeighborObj = object

			if nearestNeighborDist < @NEAREST_NEIGHBOR_MAX_LENGTH
				return nearestNeighborObj
			else
				return null

	# #### Object Manipulation

	selectDeselectObject: (object) ->
		log "selectDeselectObject"
		modelObject = @models[object.sid]
		if modelObject.selected is false
			@selectObject(object)
		else
			@deselectObject(object)

	selectObject: (object) ->
		log "selectObject"
		modelObject = @models[object.sid]
		if modelObject.selected is false
			modelObject.changeColor(@SELECTED_COLOR)
			modelObject.selected = true
			@objectsSelected[object.sid] = object

	deselectObject: (object) ->
		log "deselectObject"
		modelObject = @models[object.sid]
		if modelObject.selected is true
			if modelObject.unfolded is true
				modelObject.changeColor(@UNFOLDED_COLOR)
			else
				modelObject.changeColor(@FOLDED_COLOR)
			modelObject.selected = false
			delete @objectsSelected[object.sid]

	foldUnfoldObject: (object) ->
		log "foldUnfoldObject"
		modelObject = @_models[object.sid]
		if modelObject.unfolded is false
			@unfoldObject(object)
		else
			@foldObject(object)

	unfoldObject: (object) ->
		log "unfoldObject"
		modelObject = @models[object.sid]
		modelObject.changeColor(@UNFOLDED_COLOR)
		modelObject.unfolded = true

	foldObject: (object) ->
		log "hideObjectStats"
		modelObject = @models[object.sid]
		modelObject.changeColor(@FOLDED_COLOR)
		modelObject.unfolded = false

# ## Functions

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

# ### Initialization
#
# Sets up the gesture recognition installation by initializing the
# three main components: `TableModel`, `GestureInterpreter`, and
#`TUIOInterpreter` along with a range of minor convenience classes.
root = exports ? window

$(document).ready () ->

	root.surface = $('#surface')

	# Wait a bit and load stuff
	setTimeout () =>
		# The `table` is our main data model while the `tuioInterpreter` is in
		# charge of inferring gestures from low-level sensor data and update the
		# data model according to object and cursor movement. Lastly, the
		# `gestureInterpreter` dispatches on gesture updates received from the
		# `tuioInterpreter` and manipulates the state of objects found in the data
		# model.
		stylesheet = {
			objectSelectedColor : {
				red : 100,
				green : 45,
				blue : 214
			},
			objectFoldedColor : {
				red : 214,
				green : 135,
				blue : 45
			},
			objectUnfoldedColor : {
				red : 45,
				green : 214,
				blue : 24
			}
		}

		table = new Table(root.surface, stylesheet)
		tuioInterpreter = new TUIOInterpreter(table) # Infers motion and gestures
		gestureInterpreter = new GestureInterpreter(table, tuioInterpreter) # Manipulates
		2000

# end-of-flick.coffee