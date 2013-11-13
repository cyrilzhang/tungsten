
/**
 * Module dependencies.
 */

 var express = require('express');
 var routes = require('./routes');
 var user = require('./routes/user');
 var http = require('http');
 var path = require('path');

 var app = express();

 var mathKernelPath = "/Applications/Mathematica.app/Contents/MacOS/MathKernel";
 var port = 8000;

// all environments
app.set('port', process.env.PORT || 8000);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));

// development only
if ('development' == app.get('env')) {
	app.use(express.errorHandler());
}

app.use(express.bodyParser());

app.post('/', function(request, response){
	response.set({
		'Content-Type': 'text/plain',
		'Access-Control-Allow-Origin': '*'	
	});

	var exec = require('child_process').exec, child;
    var delim = "%%%";

	child = exec(mathKernelPath + ' -noprompt | sed 1d | sed s/InputForm//g',
		function (error, stdout, stderr) {
            chopped = stdout.split(delim)
			response.send([chopped[1], chopped[2]].join(delim + "\n"));
		});

    child.stdin.write(request.body.data + "\n" +
                      "Print[OutputForm[\"" + delim + "\"]]\n" +
    				  "TeXForm[OutputData]\n" +
    				  "Print[OutputForm[\"" + delim + "\"]]\n" +
    				  "OutputForm[InputForm[OutputData]]");
    child.stdin.end();

});

app.listen(port);