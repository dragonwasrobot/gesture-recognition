# **Author:** Peter Urbak<br/>
# **Version:** 2013-03-10

root = window ? exports

# The `TableApplication` receives movement and gesture events and adds semantic
# value to these by manipulating the data model accordingly.

class App.TableApplication

	# ### Constants
	NEAREST_NEIGHBOR_MAX_LENGTH: 0.15

	# ### Constructors

	# Constructs a `TableApplication`.
	#
	# - **tableModel:** The `TableModel` encapsulating the application state.
	constructor: (@tableModel) ->
		@objectsOnScreen = {} # { sid, { sid, fid, x, y, a } }

	# ### Methods

	# Notifies the `TableApplication` of a new movement or gesture event.
	#
	# - **event: ** The event received.
	notify: (event) ->
		switch event['type']

			# Movement updates
			when App.Constants.OBJECT_ADD
				object = event['data']
				@objectsOnScreen[object.sid] = object
				@tableModel.addObjectModel object
			when App.Constants.OBJECT_UPDATE
				object = event['data']
				@objectsOnScreen[object.sid] = object
				@tableModel.updateObjectModel object
			when App.Constants.OBJECT_REMOVE
				object = event['data']
				delete @objectsOnScreen[object.sid]
				@tableModel.removeObjectModel object

			# Gesture updates
			when App.Constants.FINGER_SINGLE_TAP
				tap = event['data']
				@performSingleTap tap

			when App.Constants.FINGER_DOUBLE_TAP
				tap = event['data']
				@performDoubleTap tap

			when App.Constants.FINGER_FLICK
				flick = event['data']
				@performFlick flick

			when App.Constants.FINGER_HOLD_FLICK
				flick = event['data']
				@performHoldFlick flick

			when App.Constants.OBJECT_SHAKE
				shake = event['data']
				@performShake shake

	# #### Gesture Semantics

	# Performs a single tap
	#
	# - **tap:**
	performSingleTap: (tap) ->
		App.log "performSingleTap"
		nearestNeighbor = @getNearestNeighborObject(tap.positionStart)
		if nearestNeighbor? then @tableModel.selectDeselectObjectModel(nearestNeighbor)

	# Performs a double tap
	#
	# - **tap:**
	performDoubleTap: (tap) ->
		App.log "performDoubleTap"
		nearestNeighbor = @getNearestNeighborObject(tap.positionStart)
		if nearestNeighbor? then @tableModel.foldUnfoldObjectModel(nearestNeighbor)

	# Performs a flick
	#
	# - **flick:**
	performFlick: (flick) ->
		App.log "performFlick"
		nearestNeighbor = @getNearestNeighborObject(flick.positionStart)
		@_performCommonFlick(flick, nearestNeighbor)

	# Performs a hold flick
	#
	# - **flick:**
	performHoldFlick: (flick) ->
		App.log "performHoldFlick"
		cursor = flick['cursor']
		nnQueryObject = flick['nearestNeighbor']
		nearestNeighbor = @getNearestNeighborObject(nnQueryObject.positionStart)
		@_performCommonFlick(cursor, nearestNeighbor)

	_performCommonFlick: (flick, nearestNeighbor) ->
		if nearestNeighbor?
			cursorVector = App.vectorFromPositions(flick.positionStart,
				flick.positionStop)
			cursorAngle = App.vectorAngle(cursorVector, { x : 0, y : 1 })

			if flick.positionStop.x < flick.positionStart.x
				cursorAngle = 360 - cursorAngle # A quick trigonometry hack.

			nearestNeighborAngle = App.radiansToDegrees(nearestNeighbor.angle)

			if App.sameDirection(cursorAngle, nearestNeighborAngle)
				@tableModel.unfoldObjectModel(nearestNeighbor)
			else if App.oppositeDirection(cursorAngle, nearestNeighborAngle)
				@tableModel.foldObjectModel(nearestNeighbor)

	# Performs a shake
	#
	# - **shake:**
	performShake: (shake) ->
		App.log "performShake"
		@tableModel.foldUnfoldObjectModel(shake)

	# #### Utility Methods

	# Returns the nearest neighbor object
	#
	# - **position:**
	getNearestNeighborObject: (position) ->
		App.log "getNearestNeighborObject"
		# Naive Linear Search
		nearestNeighborObj = null
		nearestNeighborDist = 1

		for sid, object of @objectsOnScreen
			objectPos = new App.Position(object.x, object.y)
			posDiff = App.euclideanDistance(position, objectPos)

			if posDiff < nearestNeighborDist
				nearestNeighborDist = posDiff
				nearestNeighborObj = object

		if nearestNeighborDist < @NEAREST_NEIGHBOR_MAX_LENGTH
			return nearestNeighborObj
		else
			return null