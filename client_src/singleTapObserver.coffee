root = exports ? window

# `TapObserver`
class App.SingleTapObserver extends Observer # also extends Subject

	# ## Tap Constants
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
				return true;
		return false;

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
			else
				App.log "Unknown cursor event received: #{eventType}"

	addCursor: (cursor) ->
		timestampStart = new Date().getTime()
		positionStart = new App.Position(cursor.x, cursor.y)
		@cursorCurrentPresses[cursor.sid] =
			new App.CursorModel(timestampStart, null, positionStart, null)

	updateCursor: (cursor) -> # stub

	removeCursor: (cursor) ->
		timestampStop = new Date().getTime()
		positionStop = new App.Position(cursor.x, cursor.y)
		oldCursorModel = @cursorCurrentPresses[cursor.sid]
		delete @cursorCurrentPresses[cursor.sid]
		cursorObj = new App.CursorModel(oldCursorModel.timestampStart,
			timestampStop, oldCursorModel.positionStart, positionStop)

		if @checkSingleTap(cursorObj)
			App.log "Single Tap Detected!"
			@cursorRecentTaps.push(cursorModel)

			tapEvent = {
				'type' : App.Constants.FINGER_SINGLE_TAP,
				'data' : cursorModel
			}
			unless @notifyObservers(tapEvent)
				@owner.notify(tapEvent)

	# Check if a single tap has occured.
	#
	# - **cursorModel:** the
	checkSingleTap: (cursorModel) ->
		App.log "checkSingleTap"
		timeDiff = App.measureTime(cursorObj.timestampStart,
			cursorObj.timestampStop)
		positionDiff = App.euclideanDistance(cursorObj.positionStart,
			cursorObj.positionStop)
		if @TAP_MIN_TIME <= timeDiff and timeDiff <= @TAP_MAX_TIME and
		@TAP_MIN_LENGTH <= positionDiff and positionDiff <= @TAP_MAX_LENGTH
			return true
		else
			return false