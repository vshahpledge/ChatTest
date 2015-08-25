var app = require('express')();
var http = require('http').Server(app);
var io = require('socket.io')(http);

app.get('/', function(req, res){
	res.sendFile(__dirname + '/index.html');
});

io.on('connection', function(socket){
	console.log('a user connected');

	socket.on('disconnect', function(){
		console.log('user disconnected');
	});

	socket.on('typing', function(){
		io.emit('typing');
	})

	socket.on('chat', function(userId, username, msg){
		io.emit('chat', userId, username, (new Date).getTime(), msg);
	});

	socket.on('image', function(userId, username, img) {
		io.emit('image', userId, username, (new Date).getTime(), img);
	});
});

http.listen(3000, function(){
	console.log('listening on *:3000');
})