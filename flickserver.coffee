# flickserver.coffee
#
# @author Peter Urbak
# @version 2012-10-22

express = require 'express'

class Server
	###
	The server sets up the webservice.
	###

	constructor: () ->
		@setupWebService()
		port = 8000
		@app.listen port
		console.log "Server listening on port " + port

	setupWebService: () ->
		###
		Perform initial setup of the webservice.
		###
		@app = express()
		dir = __dirname + '/html'
		@app.use(express.static(dir))

server = new Server()

# end-of-flickserver.coffee