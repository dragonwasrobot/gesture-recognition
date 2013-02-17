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
			new App.CursorModel(timestampStart, null, positionStart, null)

	updateCursor: (cursor) -> # stub

	removeCursor: (cursor) ->
		delete @cursorCurrentPresses[cursor.sid]

	# ### Gesture Recognition

	# Check if a hold flick has occured.
	checkHoldFlick: (cursorModel) ->
		nearestNeighborCursor = @getNearestNeighborCursor(cursorModel.positionStart)
		if nearestNeighborCursor?
			App.log "Hold Flick Detected!"
			flickEvent = {
				'type' : App.Constants.FINGER_HOLD_FLICK,
				'data' : cursorModel
			}
			@owner.notify(flickEvent)
			return true
		else
			return false

	# Returns the nearest neighbor cursor
	#
	# - **position:**
	getNearestNeighborCursor: (position) ->
		nearestNeighborCursor = null
		nearestNeighborDist = 1

		for id, cursor of @cursorCurrentPresses
			# Have to check that the cursor isn't the same as the one from the flick
			# event -> introduce an sid property on the CursorModel.
			cursorPos = cursor.positionStart
			posDiff = App.euclideanDistance(position, cursorPos)

			if posDiff < nearestNeighborDist
				nearestNeighborDist = posDiff
				nearestNeighborCursor = cursor

		if nearestNeighborDist < @NEAREST_NEIGHBOR_MAX_LENGTH
			return nearestNeighborCursor
		else
			return null
