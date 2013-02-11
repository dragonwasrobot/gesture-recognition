# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

root = exports ? window

# The `TableModel` encapsulates the state of the multi-touch table and the
# objects on it.

class App.TableModel

	# ### Constructors

	# Constructs a `TableModel`.
	#
	# - **surface:** The &lt;div&gt; tag on which to append new object.
	# - **stylesheet:** A JSON object containing the styling properties of the
	#		model.
	constructor: (@surface, @stylesheet) ->
		@models = {} # { sid , CommonObjectModel }
		@objectsOnScreen = {} # { sid, CommonObjectModel }

	# ### Methods

	# Adds a new object on the screen.
	#
	# - **object:** The JSON object to be added to the model and screen.
	addObjectModel: (object) ->
		if not @objectsOnScreen[object.sid]?
			objectModel = new App.ObjectModel(object, @surface, 90, 90)
			@models[object.sid] = objectModel
			@objectsOnScreen[object.sid] = objectModel

	# Check if an `ObjectModel` with the specified `sid` exists.
	#
	# - **sid:** The ID of the `ObjectModel` to checked for.
	isObjectModelOnScreen: (sid) -> @objectsOnScreen[sid]?

	# Returns the `objectModel` of the specified `sid`.
	#
	# - **sid:** The ID of the `ObjectModel` to return.
	getObjectModel: (sid) -> @objectsOnScreen[sid]

	# Updates an `ObjectModel` according to the changes in `object`.
	#
	# - **object:** The JSON object containing the updates of the `ObjectModel`.
	updateObjectModel: (object) ->

	# Removes an `ObjectModel` from the `TableModel`.
	#
	# - **object:** The object to be removed from the model and screen.
	removeObjectModel: (object) ->
		@models[object.sid].remove()
		delete @objectsOnScreen[object.sid]
		delete @models[object.sid]