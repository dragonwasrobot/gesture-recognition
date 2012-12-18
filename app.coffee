# app.coffee
#
# @author Peter Urbak
# @version 2012-12-18

express = require 'express'

class Server
	###
	The gesture recognition server.
	###

	constructor: (port) ->
		###
		Constructs a Server.
		###
		@app = express()
		@app.use(express.static(__dirname + '/html'))
		@app.listen port
		console.log "Server listening on port " + port

server = new Server(8000)

# end-of-app.coffee