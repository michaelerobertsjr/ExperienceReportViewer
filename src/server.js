/**
 * Creates a simple web server for static content.
 *
 * Launch from command line:
 * $ node server.js <port>
 *
 * The default value for port is 8080.
 */
(function() {
    try {
        var connect = require('connect');
        var port = process.argv[2];
        if (port == null) port = 8080;
        console.log("Server listening on port "+port+"...")
        connect.createServer(
            connect.static(__dirname)
        ).listen(port);
    } catch(exception) {
        console.log(exception);
    }
})();

