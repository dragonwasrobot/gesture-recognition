# **Author:** Peter Urbak<br/>
# **Version:** 2013-03-10

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
		@models = {} # { sid , ObjectModel }

	# ### Methods

	# #### Model Manipulation - Position

	# Adds a new object on the screen.
	#
	# - **object:** The JSON object to be added to the model and screen.
	addObjectModel: (object) ->
		if not @models[object.sid]?
			objectModel = new App.ObjectModel(object, @surface, 90, 90)
			@models[object.sid] = objectModel

	# Updates an `ObjectModel` according to the changes in `object`.
	#
	# - **object:** The JSON object containing the updates of the `ObjectModel`.
	updateObjectModel: (object) ->
		objectModel = @models[object.sid]
		objectModel.rotate(App.radiansToDegrees(object.angle))
		objectModel.moveToPosition(object.x, object.y)

	# Removes an `ObjectModel` from the `TableModel`.
	#
	# - **object:** The object to be removed from the model and screen.
	removeObjectModel: (object) ->
		@models[object.sid].remove()
		delete @models[object.sid]

	# #### Model Manipulation - Color

	# Selects/Deselect an object.
	#
	# - **object:**
	selectDeselectObjectModel: (object) ->
		objectModel = @models[object.sid]
		if objectModel.isSelected()
			@deselectObjectModel(object)
		else
			@selectObjectModel(object)

	# Selects an object.
	#
	# - **object:**
	selectObjectModel: (object) ->
		objectModel = @models[object.sid]
		objectModel.setSelected true
		objectModel.changeColor @stylesheet['objectSelectedColor']

	# Deselects an object.
	#
	# - **object:**
	deselectObjectModel: (object) ->
		objectModel = @models[object.sid]
		objectModel.setSelected false
		if objectModel.isUnfolded()
			objectModel.changeColor @stylesheet.objectUnfoldedColor
		else
			objectModel.changeColor @stylesheet.objectFoldedColor

	# Fold/Unfold an object.
	#
	# - **object:**
	foldUnfoldObjectModel: (object) ->
		objectModel = @models[object.sid]
		if objectModel.isUnfolded()
			@foldObjectModel(object)
		else
			@unfoldObjectModel(object)

	# Unfolds an object.
	#
	# - **object:**
	unfoldObjectModel: (object) ->
		objectModel = @models[object.sid]
		objectModel.setUnfolded true
		objectModel.changeColor @stylesheet.objectUnfoldedColor

	# Folds/Deselect an object.
	#
	# - **object:**
	foldObjectModel: (object) ->
		objectModel = @models[object.sid]
		objectModel.setUnfolded false
		objectModel.changeColor @stylesheet.objectFoldedColor
