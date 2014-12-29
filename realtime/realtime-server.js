var path = require('path');
var appDir = path.dirname(require.main.filename);
var config = require('util')._extend(
  require(appDir + '/realtime'),
  require(appDir + '/../app/workers/table_manager')
);

var io = require('socket.io')(config.REALTIME_SERVER_PORT);

var Redis = require('redis');

messageSubscriptionClients = {}

return io.on('connection', function(socket){
  console.log("realtime-server: New connection: " + socket.id);

  messageSubscriptionClients[socket.id] = Redis.createClient();
  messageSubscriptionClients[socket.id].subscribe(config.REALTIME_CHANNEL);

  // From background processor
  messageSubscriptionClients[socket.id].on('message', function(channel, message){
    console.log("realtime-server: Alerting " + socket.id + ": " + message);

    var parsedMessage = JSON.parse(message);
    var msg = ("message" in parsedMessage) ? parsedMessage.message : parsedMessage.channel
    socket.emit(parsedMessage.channel, msg);
  });

  socket.on(config.NEXT_HAND, function (message) {
    console.log('realtime-server: Alert from ' + socket.id + ': ' + config.SPECTATE_NEXT_HAND_CHANNEL + message.matchId);

    socket.broadcast.emit(config.SPECTATE_NEXT_HAND_CHANNEL + message.matchId);
  });

  socket.on(config.PLAYER_COMMENT, function (data) {
    console.log(
      'realtime-server: Alert from ' + socket.id + ': {' + data.matchId + ", " + data.user + ", " + data.message + "}. Emitting on " + config.PLAYER_COMMENT_CHANNEL_PREFIX + data.matchId);

    socket.broadcast.emit(config.PLAYER_COMMENT_CHANNEL_PREFIX + data.matchId, {user: data.user, message: data.message});
  });

  // For logging
  socket.on('disconnect', function(e){
    console.log('realtime-server: ' + socket.id + ' disconnected: ' + e.toString());

    messageSubscriptionClients[socket.id].quit();
    delete messageSubscriptionClients[socket.id];
  });
});
