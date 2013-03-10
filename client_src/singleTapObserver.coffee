root = exports ? window

# `SingleTapObserver`
class App.SingleTapObserver

	# ## Constants
	TAP_MIN_LENGTH: 0
	TAP_MAX_LENGTH: 0.02
	TAP_MIN_TIME: 0
	TAP_MAX_TIME: 100

	# ## Constructors

	# Constructs a `SingleTapObserver`
	constructor: (@owner) ->
		@observers = []
		@cursorCurrentPresses = {} # { sid : CursorModel }

	# ## Methods

	# ### Subject methods

	registerObserver: (observer) ->
		@observers.push(observer)

	unregisterObserver: (observer) ->
		observerIndex = @observers.indexOf(observer)
		if observerIndex isnt -1
			@observers.splice(observerIndex, 1)

	notifyObservers: (event) ->
		for observer in @observers
			if observer.notify(event)
				return true
		return false

	# ### Overriden observer methods

	# Notifies the `SingleTapObserver` of a new `event`.
	notify: (event) ->
		type = event['type']
		cursor = event['data']
		switch type
			when App.Constants.CURSOR_ADD
				@addCursor(cursor)
			when App.Constants.CURSOR_UPDATE
				@updateCursor(cursor)
			when App.Constants.CURSOR_REMOVE
				@removeCursor(cursor)

	# ### TUIO Event Handlers

	addCursor: (cursor) ->
		timestampStart = new Date().getTime()
		positionStart = new App.Position(cursor.x, cursor.y)
		@cursorCurrentPresses[cursor.sid] =
			new App.CursorModel(cursor.sid, timestampStart, null, positionStart, null)

	updateCursor: (cursor) -> # stub

	removeCursor: (cursor) ->
		timestampStop = new Date().getTime()
		positionStop = new App.Position(cursor.x, cursor.y)
		oldCursorModel = @cursorCurrentPresses[cursor.sid]
		delete @cursorCurrentPresses[cursor.sid]
		cursorModel = new App.CursorModel(cursor.sid, oldCursorModel.timestampStart,
			timestampStop, oldCursorModel.positionStart, positionStop)

		if @checkSingleTap(cursorModel)
			App.log "Single Tap Detected!"

			tapEvent = {
				'type' : App.Constants.FINGER_SINGLE_TAP,
				'data' : cursorModel
			}
			unless @notifyObservers(tapEvent) then @owner.notify(tapEvent)

	# ### Gesture Recognition

	# Check if a single tap has occured.
	#
	# - **cursorModel:**
	checkSingleTap: (cursorModel) ->
		timeDiff = App.measureTime(cursorModel.timestampStart,
			cursorModel.timestampStop)
		positionDiff = App.euclideanDistance(cursorModel.positionStart,
			cursorModel.positionStop)
		if @TAP_MIN_TIME <= timeDiff and timeDiff <= @TAP_MAX_TIME and
		@TAP_MIN_LENGTH <= positionDiff and positionDiff <= @TAP_MAX_LENGTH
			return true
		else
			return false