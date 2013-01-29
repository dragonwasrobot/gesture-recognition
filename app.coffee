# **Author:** Peter Urbak<br/>
# **Version:** 2013-01-28

express = require 'express'

# The `Server` has the single purpose of starting a `node.js` web server which
# listens on port 8000.
class Server

	# Constructs a `Server`.
	constructor: (port) ->
		@app = express()
		@app.use(express.static(__dirname + '/html'))
		@app.listen port
		console.log "Server listening on port " + port

server = new Server(8000)