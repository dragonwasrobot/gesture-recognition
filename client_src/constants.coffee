# **Author:** Peter Urbak<br/>
# **Version:** 2013-02-12

root = exports ? window

# `App.Constants` contains application-wide constants.
# This class should not be instantiated.
class App.Constants

	# ## Constants

	@OBJECT_ADD: "object:add"
	@OBJECT_UPDATE: "bject:update"
	@OBJECT_REMOVE: "object:remove"

	@CURSOR_ADD: "cursor:add"
	@CURSOR_UPDATE: "cursor:update"
	@CURSOR_REMOVE: "cursor:remove"

	@FINGER_SINGLE_TAP: "finger:single-tap"
	@FINGER_DOUBLE_TAP: "finger:double-tap"
	@FINGER_FLICK: "finger:flick"
	@FINGER_HOLD_FLICK: "finger:hold-flick"


	# ## Constructors

	constructor: () -> # So this is a hack
		throw new Error("App.Constants should not be instantiated");