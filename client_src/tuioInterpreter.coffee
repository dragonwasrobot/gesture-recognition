# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

# The `TUIOInterpreter` receives raw JSON updates from the TUIO plugin and use
# these to update the basic properties of the `ObjectModel`s present on the
# table. Furthermore, it also infers higher level gestures from the cursor and
# object movement and propagates these as gesture objects to the upper layers of
# the application.
class TUIOInterpreter

	# ### Constants

	# ##### Tap Constants
	TAP_MIN_LENGTH: 0
	TAP_MAX_LENGTH: 0.02
	TAP_MIN_TIME: 0
	TAP_MAX_TIME: 100

	# ##### Double Tap Constants
	DOUBLE_TAP_MIN_LENGTH: 0
	DOUBLE_TAP_MAX_LENGTH: 0.04
	DOUBLE_TAP_MIN_TIME: 0
	DOUBLE_TAP_MAX_TIME: 200

	# ##### Flick Constants
	FLICK_MIN_LENGTH: 0.025
	FLICK_MAX_LENGTH: 0.15
	FLICK_MIN_TIME: 100
	FLICK_MAX_TIME: 750
	FLICK_MIN_DEGREE: 0
	FLICK_MAX_DEGREE: 45

	# ##### Pressed + Flick Constants
	PRESSED_MIN_LENGTH: 0
	PRESSED_MAX_LENGTH: 0.10

	# ##### Shake Constants
	SHAKE_MIN_LENGTH: 0.05
	SHAKE_MAX_LENGTH: 0.20
	SHAKE_MIN_TIME: 250
	SHAKE_MAX_TIME: 2000 # Probably too large
	SHAKE_MAX_DEGREE: 60

	# ##### Other Constants
	SPLICE_MAX_LENGTH: 0.025
	OBJECT_UPDATE_FREQUENCY: 100
	OBJECT_RELEVANCE_MAX_TIME: 2500
	CURSOR_RELEVANCE_MAX_TIME: 1000
	NEAREST_NEIGHBOR_MAX_LENGTH: 0.15

	X_UNIT_VECTOR: { x : 1 , y : 0 }
	Y_UNIT_VECTOR: { x : 0 , y : 1 }

	# ### Constructors

	# Constructs a `TUIOInterpreter`.
	#
	# - **table:** The `TableModel` object.
	constructor: (@table) ->
		@objectUpdates = {} # { sid, [ ObjectUpdate ] }
		@cursorRecentTaps = [] # [ Cursor ]
		@cursorCurrentPresses = {} # { sid : Cursor }
		@registerCallbacks()

	# ### Methods

	# Registers the callback function on the TUIO plugin.
	registerCallbacks: () ->
		tuio.object_add(@addTuioObject)
		tuio.object_update(@updateTuioObject)
		tuio.object_remove(@removeTuioObject)

		tuio.cursor_add(@addTuioCursor)
		tuio.cursor_update(@updateTuioCursor)
		tuio.cursor_remove(@removeTuioCursor)

	# #### Callbacks

	# The `TUIOInterpreter` allows adding callback functions for handling
	# four gestures:
	#
	# - Finger: tap
	# - Finger: double tap
	# - Finger: hold + tap
	# - Object: shake
	callbackFingerTap: (gesture) -> # stub
	callbackFingerDoubleTap: (gesture) -> # stub
	callbackFingerHoldPlusTap: (gesture) -> # stub
	callbackObjectShake: (gesture) -> # stub

	fingerTap : (f) -> @callbackFingerTap = f
	fingerDoubleTap : (f) -> @callbackFingerDoubleTap = f
	fingerHoldPlusTap : (f) -> @callbackFingerHoldPlusTap = f
	objectShake : (f) -> @callbackObjectShake = f

	# #### UI Event Listeners

	# ##### Objects

	# Adds a new object.
	#
	# - **object:** The object to be added.
	addTuioObject: (object) ->
		if not @table.isObjectModelOnScreen(object.sid)?
			objectTimestamp = new Date().getTime()
			@objectUpdates[object.sid] = []
			@objectUpdates[object.sid].push(new ObjectUpdate(objectTimestamp,
				new	Position(object.x, object.y)))

	# Updates an object.
	#
	# - **object:** The object to be updated.
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

	# Removes an object
	#
	# - **object:** The object to be removed.
	removeTuioObject: (object) ->
		delete @objectUpdates[object.sid]
		@table.removeObjectModel(object)

	# ##### Cursors

	# Adds a new cursor.
	#
	# - **cursor:** The cursor to be added.
	addTuioCursor: (cursor) ->
		timestampStart = new Date().getTime()
		positionStart = new Position(cursor.x, cursor.y)
		@cursorCurrentPresses[cursor.sid] =
			new Cursor(timestampStart, null, positionStart, null)

	# Update a cursor.
	#
	# - **cursor:** The cursor to be updated.
	updateTuioCursor: (cursor) -> # do nothing

	# Removes a cursor.
	#
	# - **cursor:** The cursor to be removed.
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

	# Check if we can detect a shake gesture.
	#
	# - **object:**
	# - **objectTimestamp:**
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

	# Check if we can detect a single tap
	#
	# - **cursorObj:**
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

	# Check if we can detect a double tap
	#
	# - **cursorObj:**
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

	# Returns the nearest neighbor cursor
	#
	# - **position:**
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

	# Check if we can detect a flick.
	#
	# - **cursorObj:**
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

	# Returns the nearest neighbor object
	#
	# - **position:**
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