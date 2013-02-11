# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

root = exports ? window

# The `ObjectModel` encapsulates the state of an object on the multi-touch table.
class App.ObjectModel

	# ### Constructors

	# Constructs an `ObjectModel`.
	#
	# - **object:** The JSON object.
	# - **surface:** The surface &lt;div&gt; tag.
	# - **objWidth:** The object width.
	# - **objHeight:** The object height.
	constructor: (@object, surface, objWidth, objHeight) ->
		@unfolded = false
		@selected = false

		@div = $('<div class="model"/>')
		@div.width = objWidth
		@div.height = objHeight
		surface.append @div
		@moveToPosition @object.x, @object.y

		paper = Raphael(@div.get(0), @div.width, @div.height)
		@container = paper.rect(20, 20, @div.width, @div.height, 6)
		@container.attr('fill', 'rgb(214,135,45)')

	# Moves the `ObjectModel` to the specified set of coordinates.
	#
	# - **x:** The x-coordinate.
	# - **y:** The y-coordinate.
	moveToPosition: (x, y) ->

		position = @div.position
		width = @div.width
		height = @div.height

		parentWidth = @div.offsetParent().width()
		parentHeight = @div.offsetParent().height()

		halfWidth = ((width / parentWidth) * 100) / 2
		halfHeight = ((height / parentHeight) * 100) / 2

		@div.css('left', (String) ((x * 100) - halfWidth) + "%")
		@div.css('top', (String) ((y * 100) - halfHeight) + "%")

	# Removes the `ObjectModel`.
	remove: () ->
		@div.remove()
		@container.remove()

	# Rotates the `ObjectModel`.
	#
	# - **angle:** The angle to be rotated.
	rotate: (angle) -> @container.transform('r' + angle)

	# Changes the color of the `ObjectModel`.
	#
	# - **color:** The new color of the object.
	changeColor: (color) ->	@container.attr('fill', color)

	# Folds the `ObjectModel`.
	foldObject: () -> @unfolded = false

	# Unfolds the `ObjectModel`.
	unfoldObject: () -> @unfolded = true

	# Selects the `ObjectModel`.
	selectObject: () -> @selected = true

	# Deselects the `ObjectModel`.
	deselectObject: () -> @selected = false

# The `ObjectUpdate` encapsulates an update of an `ObjectModel` having a
# timestamp of the update along with a new position.
class App.ObjectUpdate
	constructor: (@timestamp, @position) ->
