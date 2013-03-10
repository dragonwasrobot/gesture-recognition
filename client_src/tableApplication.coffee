# **Author:** Peter Urbak<br/>
# **Version:** 2013-03-10

root = exports ? window

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
