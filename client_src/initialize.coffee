# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-29

# ### Initialization
#
# Initializes the gesture recognition project.
root = exports ? window

$(document).ready () ->

	root.surface = $('#surface')

	# Wait a bit and load stuff
	setTimeout () =>

		stylesheet = {
			objectSelectedColor : {
				red : 100,
				green : 45,
				blue : 214
			},
			objectFoldedColor : {
				red : 214,
				green : 135,
				blue : 45
			},
			objectUnfoldedColor : {
				red : 45,
				green : 214,
				blue : 24
			}
		}

		# The `table` is our main data model while the `tuioInterpreter` is in
		# charge of inferring gestures from low-level sensor data and update the
		# data model according to object and cursor movement. Lastly, the
		# `gestureInterpreter` dispatches on gesture updates received from the
		# `tuioInterpreter` and manipulates the state of objects found in the data
		# model.
		table = new App.TableModel(root.surface, stylesheet)
		tuioSubject = new App.TUIOSubject()
		singleTapObserver = new App.SingleTapObserver(null)
		doubleTapObserver = new App.DoubleTapObserver(null)

		tuioSubject.registerObserver(singleTapObserver)
		singleTapObserver.registerObserver(doubleTapObserver)

		# tuioInterpreter = new App.TUIOInterpreter(table)
		# gestureInterpreter = new App.GestureInterpreter(table, tuioInterpreter)
		2000
