try {
    var connect = require('connect');
    var port = process.argv[2];
    console.log("Server listening on port "+port+"...")
    connect.createServer(
        connect.static(__dirname)
    ).listen(port);
} catch(exception) {
    console.log(exception);
}

