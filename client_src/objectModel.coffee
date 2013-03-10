# **Author:** Peter Urbak<br/>
# **Version:** 2013-03-10

root = exports ? window

# The `ObjectModel` encapsulates the state of an object on the multi-touch
# table.
class App.ObjectModel

	# ### Constructors

	# Constructs an `ObjectModel`.
	#
	# - **object:** The JSON object.
	# - **surface:** The surface &lt;div&gt; tag.
	# - **objWidth:** The object width.
	# - **objHeight:** The object height.
	constructor: (object, surface, width, height) ->
		@unfolded = false
		@selected = false

		@div = $('<div class="model"/>')
		surface.append @div

		@moveToPosition object.x, object.y

		@div.height(@div.height() + 100) # magic.

		paper = Raphael(@div.get(0), @div.width(), @div.height())
		@container = paper.rect(20, 20, width, height, 6)
		@container.attr('fill', 'rgb(214,135,45)')

	# Moves the `ObjectModel` to the specified set of coordinates.
	#
	# - **x:** The x-coordinate.
	# - **y:** The y-coordinate.
	moveToPosition: (x, y) ->
		position = @div.position()
		width = @div.width()
		height = @div.height()

		parentWidth = @div.offsetParent().width()
		parentHeight = @div.offsetParent().height()

		halfWidth = ((width / parentWidth) * 100) / 2
		halfHeight = ((height / parentHeight) * 100) / 2

		@div.css('left', (String) ((x * 100) - halfWidth) + "%")
		@div.css('top', (String) ((y * 100) - halfHeight) + "%")

	# Rotates the `ObjectModel`.
	#
	# - **angle:** The angle to be rotated.
	rotate: (angle) ->
		@container.transform('r' + angle)

	# Removes the `ObjectModel`.
	remove: () ->
		@div.remove()
		@container.remove()

	# Changes the color of the `ObjectModel`.
	#
	# - **color:** The new color of the object.
	changeColor: (color) ->
		newColor = 'rgb(' + color.red + ', ' + color.green + ', ' + color.blue + ')'
		@container.attr('fill', newColor)

	# Returns true if the object is unfolded, false otherwise.
	isUnfolded: () -> @unfolded

	# Folds/Unfolds the `ObjectModel`.
	setUnfolded: (unfolded) -> @unfolded = unfolded

	# Returns true if the object is selected, false otherwise.
	isSelected: () -> @selected

	# Selects/Deselects the `ObjectModel`.
	setSelected: (selected) -> @selected = selected

# The `ObjectUpdate` encapsulates an update of an `ObjectModel` having a
# timestamp of the update along with a new position.
class App.ObjectUpdate
	constructor: (@timestamp, @position) ->
