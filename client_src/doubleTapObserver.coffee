root = exports ? window

# `DoubleTapObserver`
class App.DoubleTapObserver

	# ## Constants
	DOUBLE_TAP_MIN_LENGTH: 0
	DOUBLE_TAP_MAX_LENGTH: 0.04
	DOUBLE_TAP_MIN_TIME: 0
	DOUBLE_TAP_MAX_TIME: 200

	# ## Constructors

	# Constructs a `SingleTapObserver`
	constructor: (@owner) ->
		@recentTaps = [] # [ CursorModel ]

	# ## Methods

	# ### Overriden observer methods

	# Notifies the `DoubleTapObserver` of a new `event`.
	#
	# - **event:**
	notify: (event) ->
		type = event['type']
		cursorModel = event['data']
		if type is App.Constants.FINGER_SINGLE_TAP
			if @checkDoubleTap(cursorModel)
				App.log "Double Tap Detected!"

				doubleTapEvent = {
					'type' : App.Constants.FINGER_DOUBLE_TAP,
					'data' : cursorModel
				}
				@owner.notify(doubleTapEvent)
				return true
			else
				@recentTaps.push(cursorModel)
				return false
		else
			App.log "Unknown cursor event received: #{type}"
			return false

	# Check if a double tap has occured.
	#
	# - **cursorModel:**
	checkDoubleTap: (cursorModel) ->
		App.log "checkDoubleTap"
		for cursor in @recentTaps
			timeDiff = App.measureTime(cursorModel.timestampStop, cursor.timestampStop)
			posDiff = App.euclideanDistance(cursorModel.positionStop,
				cursor.positionStop)
			if (@DOUBLE_TAP_MIN_TIME <= timeDiff and
			timeDiff <=	@DOUBLE_TAP_MAX_TIME and
			@DOUBLE_TAP_MIN_LENGTH <= posDiff and
			posDiff <= @DOUBLE_TAP_MAX_LENGTH)
				return true
		return false
