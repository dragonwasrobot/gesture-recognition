# **Author:** Peter Urbak<br/>
# **Version:** 2013-02-12

root = exports ? window

# `Observer` specifies the interface of the observer role in Observer pattern.
# This class should never be instantiated.
class App.Observer

	# ## Constructors

	constructor: () -> # So this is a hack
		throw new Error("App.Observer should not be instantiated");

	# ## Methods

	notify: (event) -> # stub

# `Subject` specifies the interface of the subject role in Observer pattern.
# This class should never be instantiated.
class App.Subject

	# ## Constructors

	constructor: () -> # So this is a hack
		throw new Error("App.Subject should not be instantiated");

	# ## Methods

	registerObserver: (priority, observer) -> # stub

	unregisterObserver: (observer) -> # stub

	notifyObservers: (event) -> # stub
