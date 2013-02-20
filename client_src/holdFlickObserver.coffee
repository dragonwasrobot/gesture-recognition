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
			new App.CursorModel(cursor.sid, timestampStart, null, positionStart, null)

	updateCursor: (cursor) -> # stub

	removeCursor: (cursor) ->
		delete @cursorCurrentPresses[cursor.sid]

	# ### Gesture Recognition

	# Check if a hold flick has occured.
	checkHoldFlick: (cursorModel) ->
		nearestNeighborCursorModel =
			@getNearestNeighborCursor(cursorModel.positionStart, cursorModel.sid)
		if nearestNeighborCursor?
			App.log "Hold Flick Detected!"
			flickEvent = {
				'type' : App.Constants.FINGER_HOLD_FLICK,
				'data' : nearestNeighborCursorModel
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

		# This guy is still a bit broken, doesn't seem to find the nearest neighbor
		# cursor.
		for cursorSID, cursorModel of @cursorCurrentPresses
			if cursorSID is sid then continue
			cursorPosition = cursorModel.positionStart
			positionDelta = App.euclideanDistance(position, cursorPosition)

			if positionDelta < nearestNeighborDistance
				nearestNeighborDistance = positionDelta
				nearestNeighborCursorModel = cursorModel

		if nearestNeighborDistance < @NEAREST_NEIGHBOR_MAX_LENGTH
			return nearestNeighborCursorModel
		else
			return null
