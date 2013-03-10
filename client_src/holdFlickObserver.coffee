root = exports ? window

# `HoldFlickObserver`
class App.HoldFlickObserver

	# ## Constants
	NEAREST_NEIGHBOR_MAX_LENGTH: 0.15

	# ## Constructors

	# Constructs a `HoldFlickObserver`
	constructor: (@owner) ->
		@cursorCurrentPresses = {}

	# ## Methods

	# ### Overriden observer methods

	# Notifies the `DoubleTapObserver` of a new `event`.
	#
	# - **event:**
	notify: (event) ->
		type = event['type']
		switch type
			when App.Constants.FINGER_FLICK
				cursorModel = event['data']
				return @checkHoldFlick(cursorModel)
			when App.Constants.CURSOR_ADD
				cursor = event['data']
				@addCursor(cursor)
				return false
			when App.Constants.CURSOR_UPDATE
				cursor = event['data']
				@updateCursor(cursor)
				return false
			when App.Constants.CURSOR_REMOVE
				cursor = event['data']
				@removeCursor(cursor)
				return false

	# ### TUIO Event handlers

	addCursor: (cursor) ->
		timestampStart = new Date().getTime()
		positionStart = new App.Position(cursor.x, cursor.y)
		@cursorCurrentPresses[cursor.sid] =
			new App.CursorModel(cursor.sid, timestampStart, null,
				positionStart, positionStart)

	updateCursor: (cursor) ->
		positionStop = new App.Position(cursor.x, cursor.y)
		currentCursor = @cursorCurrentPresses[cursor.sid]
		currentCursor.positionStop = positionStop

	removeCursor: (cursor) ->
		delete @cursorCurrentPresses[cursor.sid]

	# ### Gesture Recognition

	# Check if a hold flick has occured.
	checkHoldFlick: (cursorModel) ->
		nearestNeighborCursorModel =
			@getNearestNeighborCursor(cursorModel.positionStart, cursorModel.sid)
		if nearestNeighborCursorModel?
			App.log "Hold Flick Detected!"
			flickEvent = {
				'type' : App.Constants.FINGER_HOLD_FLICK,
				'data' : {
					nearestNeighbor : nearestNeighborCursorModel,
					cursor :	cursorModel
				}
			}
			@owner.notify(flickEvent)
			return true
		else
			return false

	# Returns the nearest neighbor cursor
	#
	# - **position:**
	getNearestNeighborCursor: (position, sid) ->
		nearestNeighborCursorModel = null
		nearestNeighborDistance = 1

		for cursorSID, cursorModel of @cursorCurrentPresses
			if parseInt(cursorSID) isnt sid
				cursorPosition = cursorModel.positionStop
				positionDelta = App.euclideanDistance(position, cursorPosition)

				if positionDelta < nearestNeighborDistance
					nearestNeighborDistance = positionDelta
					nearestNeighborCursorModel = cursorModel

		if nearestNeighborDistance < @NEAREST_NEIGHBOR_MAX_LENGTH
			return nearestNeighborCursorModel
		else
			return null
