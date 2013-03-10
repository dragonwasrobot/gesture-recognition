root = exports ? window

# `ObjectShakeObserver`
class App.ObjectShakeObserver

	# #### Shake Constants
	SHAKE_MIN_LENGTH: 0.05
	SHAKE_MAX_LENGTH: 0.20
	SHAKE_MIN_TIME: 250
	SHAKE_MAX_TIME: 1500
	SHAKE_MAX_DEGREE: 30

	# #### Other Constants
	NEAREST_NEIGHBOR_MAX_LENGTH: 0.15
	SPLICE_MAX_LENGTH: 0.025
	OBJECT_UPDATE_FREQUENCY: 100
	OBJECT_RELEVANCE_MAX_TIME: 2500

	# ## Constructors

	# Constructs a `SingleTapObserver`
	constructor: (@owner) ->
		@observers = []
		@objectUpdates = {} # { sid, [ ObjectUpdate ] }

	# ## Methods

	# ### Overriden observer methods

	# Notifies the `objectShakeObserver` of a new `event`.
	notify: (event) ->
		type = event['type']
		object = event['data']
		switch type
			when App.Constants.OBJECT_ADD
				@addObject(object)
			when App.Constants.OBJECT_UPDATE
				@updateObject(object)
			when App.Constants.OBJECT_REMOVE
				@removeObject(object)

	# ### TUIO Event Handlers

	addObject: (object) ->
		objectTimestamp = new Date().getTime()
		@objectUpdates[object.sid] = []
		@objectUpdates[object.sid].push(new App.ObjectUpdate(objectTimestamp,
			new	App.Position(object.x, object.y)))

	updateObject: (object) ->
		objectTimestamp = new Date().getTime()

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
					shakeEvent = {
						'type' : App.Constants.OBJECT_SHAKE,
						'data' : object
					}
					@owner.notify(shakeEvent)

	removeObject: (object) ->
		delete @objectUpdates[object.sid]

	# ### Gesture Recognition

	# Check if we can detect a shake gesture.
	#
	# - **object:**
	# - **objectTimestamp:**
	checkShake: (object, objectTimestamp) ->
		App.log "checkShake"
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
			#				100 * direction.positionStart.y + "), (" + 100 *
			#				direction.positionStop.x + ", " +
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

	# Returns the nearest neighbor object
	#
	# - **position:**
	getNearestNeighborObject: (position) ->
			App.log "getNearestNeighborObject"
			# Naive Linear Search
			nearestNeighborObj = null
			nearestNeighborDist = 1

			for object in tuio.objects
				objectPos = new App.Position(object.x, object.y)
				posDiff = App.euclideanDistance(position, objectPos)

				if posDiff < nearestNeighborDist
					nearestNeighborDist = posDiff
					nearestNeighborObj = object

			if nearestNeighborDist < @NEAREST_NEIGHBOR_MAX_LENGTH
				return nearestNeighborObj
			else
				return null