root = exports ? window

# `FlickObserver`
class App.FlickObserver

	# ## Constants
	FLICK_MIN_LENGTH: 0.025
	FLICK_MAX_LENGTH: 0.15
	FLICK_MIN_TIME: 100
	FLICK_MAX_TIME: 750
	FLICK_MIN_DEGREE: 0
	FLICK_MAX_DEGREE: 45

	# ## Constructors

	# Constructs a `SingleTapObserver`
	constructor: (@owner) ->
		@observers = []
		@cursorCurrentPresses[cursor.sid]

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
			if observer.notify(event) then return true
		return false

	# ### Overriden observer methods

	# Notifies the `FlickObserver` of a new `event`.
	notify: (event) ->
		App.log "FlickObserver: notify"
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
				App.log "Unknown cursor event received: #{type}"

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
		cursorModel = new App.CursorModel(oldCursorModel.timestampStart,
			timestampStop, oldCursorModel.positionStart, positionStop)

		if @checkFlick(cursorModel)
			App.log "Flick Detected!"

			flickEvent = {
				'type' : App.Constants.FINGER_FLICK,
				'data' : cursorModel
			}
			unless @notifyObservers(flickEvent) then @owner.notify(flickEvent)

	# Check if we can detect a flick.
	#
	# - **cursorObj:**
	checkFlick: (cursorObj) ->
		# Calculate the angle of the flick gesture.
		cursorVector = App.vectorFromPositions(cursorObj.positionStart,
			cursorObj.positionStop)
		yUnitVector = { x : 0, y : 1 }
		cursorAngle = App.vectorAngle(cursorVector, yUnitVector)
		if cursorObj.positionStop.x < cursorObj.positionStart.x
			cursorAngle = 360 - cursorAngle # A quick trigonometry hack.

		posDiff = App.euclideanDistance(cursorObj.positionStart,
			cursorObj.positionStop)
		timeDiff = App.measureTime(cursorObj.timestampStart,
			cursorObj.timestampStop)

		if posDiff > @FLICK_MIN_LENGTH and posDiff < @FLICK_MAX_LENGTH and
		timeDiff > @FLICK_MIN_TIME and timeDiff < @FLICK_MAX_TIME
			return true
		else
			return false
