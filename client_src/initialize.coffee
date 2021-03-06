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

		tableModel = new App.TableModel(root.surface, stylesheet)
		tableApplication = new App.TableApplication(tableModel)
		tuioSubject = new App.TUIOSubject()

		singleTapObserver = new App.SingleTapObserver(tableApplication)
		doubleTapObserver = new App.DoubleTapObserver(tableApplication)

		flickObserver = new App.FlickObserver(tableApplication)
		holdFlickObserver = new App.HoldFlickObserver(tableApplication)

		objectShakeObserver = new App.ObjectShakeObserver(tableApplication)

		# Registration of Observers.
		tuioSubject.registerObserver(singleTapObserver)
		singleTapObserver.registerObserver(doubleTapObserver)

		tuioSubject.registerObserver(flickObserver)
		tuioSubject.registerObserver(holdFlickObserver)
		flickObserver.registerObserver(holdFlickObserver)

		tuioSubject.registerObserver(objectShakeObserver)

		tuioSubject.registerObserver(tableApplication)

		2000
