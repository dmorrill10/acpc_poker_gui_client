var path = require('path'),
    appDir = path.dirname(require.main.filename),
    config = require(appDir + '/../config/constants');

var io = require('socket.io')(config.REALTIME_SERVER_PORT);

io.on('connection', function(socket){
  var redis = require('redis').createClient();
  redis.subscribe(config.REALTIME_CHANNEL);

  redis.on('message', function(channel, message){
    var parsedMessage = JSON.parse(message);

    socket.emit(parsedMessage.channel, parsedMessage.channel);
  });
});
