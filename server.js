// Load the http module to create an http server.
var http = require('http');
var express = require('express');
var app = express();

app.post('/', function(request, response){

	console.log(request.body);

	response.set({
		'Content-Type': 'text/plain',
		'Access-Control-Allow-Origin': '*'	
	})

	response.send("Hello World\n");

});

app.listen(8000);

/* Configure our HTTP server to respond with Hello World to all requests.
var server = http.createServer(function (request, response) {
    var body = "";


    console.log(request.body);
    
    response.writeHead(200,
        {"Content-Type": "text/plain",
         "Access-Control-Allow-Origin": "*"});
    response.end("Hello World\n");
});

// Listen on port 8000, IP defaults to 127.0.0.1
server.listen(8000);

// Put a friendly message on the terminal
console.log("Server running at http://127.0.0.1:8000/"); */
app.use(express.bodyParser());
