# models.coffee
#
# @author Peter Urbak
# @version 2012-10-28

root = window ? exports

class root.CommonObjectModel
	constructor: (@div, surface) ->
		# console.log "root.CommonObjectModel constructor"
		surface.append @div
		@moveToTUIOCord @object.x, @object.y
		@createSVGContainer()

	moveToTUIOCord: (x,y) ->
		position = @div.position()
		width = @div.width()
		height = @div.height()

		parentWidth = @div.offsetParent().width()
		parentHeight = @div.offsetParent().height()

		halfWidth = ((width / parentWidth) * 100) / 2
		halfHeight = ((height / parentHeight) * 100) / 2

		@div.css('left', (String) ((x * 100) - halfWidth) + "%")
		@div.css('top', (String) ((y * 100) - halfHeight) + "%")

	createSVGContainer : () ->

		@div.height(@div.height() + 100) # magic number.

		#used to make room for the glow in the parent div
		rectangleHeight = "" + @div.height()
		rectangleWidth = "" + @div.width()

		paper = Raphael(@div.get(0), @div.width(), @div.height())
		@container = paper.rect(20, 20, 90, 90, 6) # more magic numbers.
		@container.attr("fill", "rgb(214,135,45)")

	remove: () ->
		@div.remove()
		@container.remove()

	rotate: (angle) ->
		# doesn't seem to work in Firefox v.12
		# @div.css('-webkit-transform', 'rotate('+ angle + 'deg)')
		@container.transform('r' + angle)

	changeColor: (color) ->
		@container.attr("fill", color)

class root.Model extends CommonObjectModel

	unfolded: false
	selected: false

	constructor: (@object, surface=false) ->
		# console.log "root.Model constructor"
		super($('<div class="model"/>'), surface)

# end-of-models.coffee