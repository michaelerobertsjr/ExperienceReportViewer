# Creates a simple static file server.
#
# Usage:
# $ node server.js <Port>
# (Default port is 8080)
try
  connect = require "connect"
  port = process.argv[2]
  port = 8080 if typeof port == "undefined"

  console.log "Server listening on port " + port + "..."
  server = connect.createServer connect.static(__dirname)
  server.listen port
catch e
  console.log e