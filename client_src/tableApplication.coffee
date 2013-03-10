# **Author:** Peter Urbak<br/>
# **Version:** 2013-03-10

root = window ? exports

# The `TableApplication` receives movement and gesture events and adds semantic
# value to these by manipulating the data model accordingly.

class App.TableApplication

	# ### Constructors

	# Constructs a `TableApplication`.
	#
	# - **tableModel:** The `TableModel` encapsulating the application state.
	constructor: (@tableModel) ->

	# ### Methods

	# Notifies the `TableApplication` of a new movement or gesture event.
	#
	# - **event: ** The event received.
	notify: (event) ->
		switch event['type']

			# Movement updates
			when App.Constants.OBJECT_ADD
				object = event['data']
				@tableModel.addObjectModel object
			when App.Constants.OBJECT_UPDATE
				object = event['data']
				@tableModel.updateObjectModel object
			when App.Constants.OBJECT_REMOVE
				object = event['data']
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

	performSingleTap: (tap) ->
		App.log "performSingleTap"

	performDoubleTap: (tap) ->
		App.log "performDoubleTap"

	performFlick: (flick) ->
		App.log "performFlick"

	performHoldFlick: (flick) ->
		App.log "performHoldFlick"

	performShake: (shake) ->
		App.log "performShake"
