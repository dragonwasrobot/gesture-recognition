# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

root = exports ? window

# The `GestureInterpreter` registers gestures and callback functions on the
# `TUIOInterpreter` and then dispatches on the received gesture updates from the
# `TUIOInterpreter`.
class App.GestureInterpreter

	# ### Constructors

	# Constructs a `GestureInterpreter`.
	#
	# - **table:** The `TableModel` to be manipulated.
	# - **tuioInterpreter:** The `TUIOInterpreter` to infer the gestures.
	constructor: (@table, @tuioInterpreter) ->
		@registerCallbacks()

	# ### Methods

	# Sets up the `GestureInterpreter` by registering callback functions on the
	# tuioInterpreter.
	registerCallbacks: () ->
		@tuioInterpreter.fingerTap (tap) => @handleFingerTap(tap)
		@tuioInterpreter.fingerDoubleTap (tap) => @handleFingerDoubleTap(tap)
		@tuioInterpreter.fingerFlick (flick) => @handleFingerFlick(flick)
		@tuioInterpreter.fingerHoldPlusFlick (flick) =>
			@handleFingerHoldPlusFlick(flick)

		@tuioInterpreter.objectShake (shake) => @handleObjectShake(shake)

	# #### Finger Gestures

	handleFingerTap: (gesture) ->
		App.log "handleFingerTap"

	handleFingerDoubleTap: (gesture) ->
		App.log "handleFingerDoubleTap"

	handleFingerFlick: (gesture) ->
		App.log "handleFingerFlick"

	handleFingerHoldPlusFlick: (gesture) ->
		App.log "handleFingerHoldPlusFlick"

	# #### Object Gestures

	handleObjectShake: (gesture) ->
		App.log "handleObjectShake"

	# #### Object Manipulation

	# Selects or deselect the specified object
	#
	# - **object:**
	selectDeselectObject: (object) ->
		App.log "selectDeselectObject"
		modelObject = @models[object.sid]
		if modelObject.selected is false
			@selectObject(object)
		else
			@deselectObject(object)

	# Selects the specified object
	#
	# - **object:**
	selectObject: (object) ->
		App.log "selectObject"
		modelObject = @models[object.sid]
		if modelObject.selected is false
			modelObject.changeColor(@SELECTED_COLOR)
			modelObject.selected = true
			@objectsSelected[object.sid] = object

	# Deselect the specified object
	#
	# - **object:**
	deselectObject: (object) ->
		App.log "deselectObject"
		modelObject = @models[object.sid]
		if modelObject.selected is true
			if modelObject.unfolded is true
				modelObject.changeColor(@UNFOLDED_COLOR)
			else
				modelObject.changeColor(@FOLDED_COLOR)
			modelObject.selected = false
			delete @objectsSelected[object.sid]

	# Folds or unfolds the specified object
	#
	# - **object:**
	foldUnfoldObject: (object) ->
		App.log "foldUnfoldObject"
		modelObject = @_models[object.sid]
		if modelObject.unfolded is false
			@unfoldObject(object)
		else
			@foldObject(object)

	# Unfolds the specified object
	#
	# - **object:**
	unfoldObject: (object) ->
		App.log "unfoldObject"
		modelObject = @models[object.sid]
		modelObject.changeColor(@UNFOLDED_COLOR)
		modelObject.unfolded = true

	# Folds the specified object
	#
	# - **object:**
	foldObject: (object) ->
		App.log "hideObjectStats"
		modelObject = @models[object.sid]
		modelObject.changeColor(@FOLDED_COLOR)
		modelObject.unfolded = false
