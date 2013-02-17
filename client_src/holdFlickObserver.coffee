root = exports ? window

# `HoldFlickObserver`
class App.HoldFlickObserver

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
		cursor = event['data']
		switch type
			when App.Constants.FINGER_FLICK
				if @checkHoldFlick(cursor)
					App.log "Hold Flick Detected!"

					flickEvent = {
						'type' : App.Constants.FINGER_HOLD_FLICK,
						'data' : cursor
					}
					@owner.notify(flickEvent)
					return true
				else
					return false
			when App.Constants.CURSOR_ADD
				@addCursor(cursor)
				return false
			when App.Constants.CURSOR_UPDATE
				@updateCursor(cursor)
				return false
			when App.Constants.CURSOR_REMOVE
				@removeCursor(cursor)
				return false

	# ### TUIO Event handlers

	addCursor: (cursor) ->
		timestampStart = new Date().getTime()
		positionStart = new App.Position(cursor.x, cursor.y)
		@cursorCurrentPresses[cursor.sid] =
			new App.CursorModel(timestampStart, null, positionStart, null)

	updateCursor: (cursor) -> # stub
		@cursorCurrentPresses[cursor.sid]['x'] = cursor['x']
		@cursorCurrentPresses[cursor.sid]['y'] = cursor['y']

	removeCursor: (cursor) ->
		timestampStop = new Date().getTime()
		positionStop = new App.Position(cursor.x, cursor.y)
		oldCursorModel = @cursorCurrentPresses[cursor.sid]
		delete @cursorCurrentPresses[cursor.sid]

	# ### Gesture Recognition

	# Check if a hold flick has occured.
	checkHoldFlick: (cursor) ->
