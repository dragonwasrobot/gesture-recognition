# **Author:** Peter Urbak<br/>
# **Version:** 2013-02-12

root = exports ? window

# `TUIOSubject` implements the `Subject` interface and notifies any observers of
# incoming TUIO events.
class App.TUIOSubject extends App.Subject

	# ## Constructors

	constructor: () ->
		@observers = []
		@registerCallbacks()

	# ## Methods

	# ### Initialization methods

	# Registers the callback functions on `tuio.js`.
	registerCallbacks: () ->

		tuio.object_add (object) =>
			objectAddEvent = {
				'type' : App.Constants.OBJECT_ADD,
				'data' : object
			}
			@notifyObservers(objectAddEvent)

		tuio.object_update (object) =>
			objectUpdateEvent = {
				'type' : App.Constants.OBJECT_UPDATE,
				'data' : object
			}
			@notifyObservers(objectUpdateEvent)

		tuio.object_remove (object) =>
			objectRemoveEvent = {
				'type' : App.Constants.OBJECT_REMOVE,
				'data' : object
			}
			@notifyObservers(objectRemoveEvent)

		tuio.cursor_add (cursor) =>
			cursorAddEvent = {
				'type' : App.Constants.CURSOR_ADD,
				'data' : cursor
			}
			@notifyObservers(cursorAddEvent)

		tuio.cursor_update (cursor) =>
			cursorUpdateEvent = {
				'type' : App.Constants.CURSOR_UPDATE,
				'data' : cursor
			}
			@notifyObservers(cursorUpdateEvent)

		tuio.cursor_remove (cursor) =>
			cursorRemoveEvent = {
				'type' : App.Constants.CURSOR_REMOVE,
				'data' : cursor
			}
			@notifyObservers(cursorRemoveEvent)

	# ### Overridden subject methods

	registerObserver: (observer) ->
		@observers.push(observer)

	unregisterObserver: (observer) ->
		observerIndex = @observers.indexOf(observer)
		if observerIndex isnt -1
			@observers.splice(observerIndex, 1)

	notifyObservers: (event) ->
		observer.notify(event) for observer in @observers
