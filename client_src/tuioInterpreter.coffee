# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

root = exports ? window

# The `TUIOInterpreter` receives raw JSON updates from the TUIO plugin and use
# these to update the basic properties of the `ObjectModel`s present on the
# table. Furthermore, it also infers higher level gestures from the cursor and
# object movement and propagates these as gesture objects to the upper layers of
# the application.
class App.TUIOInterpreter

	# ### Constructors

	# Constructs a `TUIOInterpreter`.
	#
	# - **table:** The `TableModel` object.
	constructor: (@table) ->
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
		cursorObj = new App.CursorModel(cursor.sid, oldCursorObj.timestampStart,
			timestampStop, oldCursorObj.positionStart, positionStop)

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