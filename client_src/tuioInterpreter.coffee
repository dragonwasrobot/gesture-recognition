# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

root = exports ? window

# The `TUIOInterpreter` receives raw JSON updates from the TUIO plugin and use
# these to update the basic properties of the `ObjectModel`s present on the
# table. Furthermore, it also infers higher level gestures from the cursor and
# object movement and propagates these as gesture objects to the upper layers of
# the application.
class App.TUIOInterpreter

	# ### Constants

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
		# @registerCallbacks()

	# ### Methods

	# ##### Objects

	# Adds a new object.
	#
	# - **object:** The object to be added.
	addTuioObject: (object) ->
		if not @table.getObjectModel(object.sid)?
			@table.addObjectModel(object)

			objectTimestamp = new Date().getTime()
			@objectUpdates[object.sid] = []
			@objectUpdates[object.sid].push(new App.ObjectUpdate(objectTimestamp,
				new	App.Position(object.x, object.y)))

	# Updates an object.
	#
	# - **object:** The object to be updated.
	updateTuioObject: (object) ->
		objectTimestamp = new Date().getTime()
		modelObject = @table.getObjectModel(object.sid)
		angle = App.radiansToDegrees(object.angle)

		if modelObject?
			# Update visuals.
			modelObject.rotate(angle)
			modelObject.moveToPosition(object.x, object.y)

			# Update set of object updates.
			objectRecentUpdates = @objectUpdates[object.sid]
			latestUpdate = objectRecentUpdates.last()
			timeDiff = App.measureTime(latestUpdate.timestamp, objectTimestamp)

			# Add new entry if a sufficient amount of time has passed.
			if timeDiff >= 100
					objectRecentUpdates.push(new App.ObjectUpdate(objectTimestamp,
						new App.Position(object.x, object.y)))

					# Then remove old entries
					sliceIndex = 0
					for objectUpdate in objectRecentUpdates
						timeDiff = App.measureTime(objectUpdate.timestamp, objectTimestamp)
						if timeDiff >= @OBJECT_RELEVANCE_MAX_TIME
							sliceIndex += 1
						else
							@objectUpdates[object.sid] = objectRecentUpdates[sliceIndex...]
							break

					# Try to recognise a shake gesture
					if @checkShake(object, objectTimestamp)
						App.log "Shake Detected!"
						@callbackObjectShake(object)

	# Removes an object
	#
	# - **object:** The object to be removed.
	removeTuioObject: (object) ->
		delete @objectUpdates[object.sid]
		@table.removeObjectModel(object)

	# ##### Cursors

	# Removes a cursor.
	#
	# - **cursor:** The cursor to be removed.
	removeTuioCursor: (cursor) ->
		timestampStop	= new Date().getTime()
		positionStop = new App.Position(cursor.x, cursor.y)
		oldCursorObj = @cursorCurrentPresses[cursor.sid]
		delete @cursorCurrentPresses[cursor.sid]
		cursorObj = new App.CursorModel(oldCursorObj.timestampStart, timestampStop,
			oldCursorObj.positionStart, positionStop)

		if @checkSingleTap(cursorObj)
			App.log "Single Tap Detected!"

			if @checkDoubleTap(cursorObj)
				nearestNeighbor = @getNearestNeighborObject(cursorObj.positionStart)
				App.log "Double Tap Detected!"

				if @objectsSelected.length() > 0
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
			# App.log "Flick Detected!"

			neighborQueryObject = cursorObj
			nearestNeighborCursor = @getNearestNeighborCursor(cursorObj.positionStart)
			if nearestNeighborCursor?
				App.log "Pressed+Flick Detected!"
				neighborQueryObject = nearestNeighborCursor

			nearestNeighbor = @getNearestNeighborObject(neighborQueryObject.positionStart)

			if nearestNeighbor?
					cursorVector = App.vectorFromPositions(cursorObj.positionStart,
						cursorObj.positionStop)
					cursorAngle = App.vectorAngle(cursorVector, @Y_UNIT_VECTOR)

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
			timeDiff = App.measureTime(objectUpdate.timestamp, objectTimestamp)
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
			oldDirectionVector = App.vectorFromPositions(relevantUpdates[0].position,
				relevantUpdates[1].position)

			for objectUpdate in relevantUpdates[2...]
				newPosition = objectUpdate.position
				newDirectionVector = App.vectorFromPositions(oldPosition,
					newPosition)

				diffAngle = App.vectorAngle(oldDirectionVector, newDirectionVector)
				# App.log "diffAngle1:" + diffAngle
				# if newPosition.x < oldPosition.x
				#			diffAngle = 360 - diffAngle # A quick trigonometry hack.
					# App.log "diffAngle2:" + diffAngle

				# Check if same, or new, direction.
				if diffAngle <= @SHAKE_MAX_DEGREE
					oldDirectionVector = App.vectorAddition(oldDirectionVector,
						newDirectionVector)
					currentPositionStop = newPosition
				else # A new direction has been taken (maybe)
					# Save old direction object
					# App.log "diffAngle: " + diffAngle
					directionObject = new App.Direction(currentPositionStart,
						currentPositionStop, oldDirectionVector)
					# App.log "new direction: " + directionObject
					directionObjects.push(directionObject)

					# Start recording the new direction
					currentPositionStart = oldPosition
					currentPositionStop = newPosition

				# Update pointers before next iteration
				oldPosition = newPosition
				oldDirectionVector = newDirectionVector

			# Make sense of the gathered vectors
			# App.log "Unfiltered directions"
			# for direction in directionObjects
			#			App.log("direction: ( (" + 100 * direction.positionStart.x + ", "
			#				100 * direction.positionStart.y + "), (" + 100 * direction.positionStop.x + ", " +
			#				100 * direction.positionStop.y + "), (" + direction.vector.x + ", "+
			#				direction.vector.y + ") )")

			# 1. Remove directions with too short a distance
			# refinedDirectionObjects = filter(directionObjects,
			#		((obj) -> App.euclideanDistance(obj.positionStart, obj.positionStop) >=
			#			@_SHAKE_MIN_LENGTH))

			refinedDirectionObjects = []
			for direction in directionObjects
							diffDistance = App.euclideanDistance(
								direction.positionStart, direction.positionStop)
							if diffDistance >= @SHAKE_MIN_LENGTH
								refinedDirectionObjects.push(direction)

			App.log "Refined directions"
			for direction in refinedDirectionObjects
						App.log("direction: ( (" + 100 * direction.positionStart.x + ", " +
							100 * direction.positionStart.y + "), (" +
							100 *	direction.positionStop.x + ", " +
							100 * direction.positionStop.y + "), (" +
							direction.vector.x + ", "+ direction.vector.y + ") )")
					App.log("length: " + App.euclideanDistance(direction.positionStart,
						direction.positionStop))

			# 2. Splice neighbors if possible

			splicedDirectionObjects = []
			if refinedDirectionObjects.length > 1
				currentDirection = refinedDirectionObjects[0]
				i = 1
				for direction in refinedDirectionObjects[1...]
					if App.euclideanDistance(currentDirection.positionStop,
						direction.positionStart) <= @SPLICE_MAX_LENGTH and
							App.vectorAngle(currentDirection.vector,
							direction.vector) <= @SHAKE_MAX_DEGREE

						currentDirection = new App.Direction(currentDirection.positionStart,
							direction.positionStop, App.vectorAddition(
								currentDirection.vector, direction.vector))
					else
						splicedDirectionObjects.push(currentDirection)
						currentDirection = direction

					if i is refinedDirectionObjects.length - 1
						splicedDirectionObjects.push(currentDirection)
					i += 1

			App.log "Spliced directions"
			for direction in splicedDirectionObjects
				App.log("direction: ( (" + 100 * direction.positionStart.x + ", " +
					100 * direction.positionStart.y + "), (" + 100 *
					direction.positionStop.x + ", " + 100 * direction.positionStop.y +
					"), (" + direction.vector.x +	", " + direction.vector.y + ") )")

			if splicedDirectionObjects.length > 2
				firstDirection = splicedDirectionObjects[0]
				secondDirection = splicedDirectionObjects[1]
				detectedShake = false
				for direction in splicedDirectionObjects[2...]

					diffFirstAngle = App.vectorAngle(firstDirection.vector,
						secondDirection.vector)
					diffSecondAngle = App.vectorAngle(secondDirection.vector,
						direction.vector)
					# App.log "diffFirstAngle: " + diffFirstAngle
					# App.log "diffSecondAngle: " + diffSecondAngle

					if diffFirstAngle >= 180 - @SHAKE_MAX_DEGREE and
						diffSecondAngle >=	180 - @SHAKE_MAX_DEGREE
							detectedShake = true
							break;

					firstDirection = secondDirection
					secondDirection = direction

				if detectedShake is true
					newObjectUpdate = new App.ObjectUpdate(objectTimestamp,
						new App.Position(object.x, object.y))

					@objectUpdates[object.sid] = [ newObjectUpdate ]
					return true

			return false

	# ##### Single Tap Recognition

	# Returns the nearest neighbor cursor
	#
	# - **position:**
	getNearestNeighborCursor: (position) ->
			App.log "getNearestNeighborCursor"
			# Naive Linear Search
			nearestNeighborCursor = null
			nearestNeighborDist = 1

			for k, cursor of @cursorCurrentPresses
				cursorPos = cursor.positionStart
				posDiff = App.euclideanDistance(position, cursorPos)

				if posDiff < nearestNeighborDist
					nearestNeighborDist = posDiff
					nearestNeighborCursor = cursor

			if nearestNeighborDist < @NEAREST_NEIGHBOR_MAX_LENGTH
				return nearestNeighborCursor
			else
				return null

	# ##### Flick Recognition

	# Returns the nearest neighbor object
	#
	# - **position:**
	getNearestNeighborObject: (position) ->
			App.log "getNearestNeighborObject"
			# Naive Linear Search
			nearestNeighborObj = null
			nearestNeighborDist = 1

			for object in tuio.objects
				if @objectsOnScreen[object.sid]?
					objectPos = new App.Position(object.x, object.y)
					posDiff = App.euclideanDistance(position, objectPos)

					if posDiff < nearestNeighborDist
						nearestNeighborDist = posDiff
						nearestNeighborObj = object

			if nearestNeighborDist < @NEAREST_NEIGHBOR_MAX_LENGTH
				return nearestNeighborObj
			else
				return null