# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

root = exports ? window

# The `CursorModel` encapsulates the state and session of a cursor on the
# multi-touch table.
class App.CursorModel

	# ### Constructors

	# Constructs a `CursorModel`.
	#
	# - **sid:** The Session ID of the cursor.
	# - **timestampStart:** The time when the cursor is placed on the table.
	# - **timestampStop:** The time when the cursor is released from the table.
	# - **positionStart:** The position of the cursor when placed on the table.
	# - **positionStop:** The position of the cursor when released from the
	#		table.
	constructor: (@sid, @timestampStart, @timestampStop,
		@positionStart, @positionStop) ->
