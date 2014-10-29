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
  console.log("realtime-server: New connection");

  messageSubscriptionClients[socket] = Redis.createClient();
  messageSubscriptionClients[socket].subscribe(config.REALTIME_CHANNEL);

  // From background processor
  messageSubscriptionClients[socket].on('message', function(channel, message){
    console.log("realtime-server: Alerting view: " + message);

    var parsedMessage = JSON.parse(message);
    var msg = ("message" in parsedMessage) ? parsedMessage.message : parsedMessage.channel
    socket.emit(parsedMessage.channel, msg);
  });

  // For logging
  socket.on('disconnect', function(e){
    console.log('realtime-server: User disconnected: ' + e.toString());

    messageSubscriptionClients[socket].quit();
    delete messageSubscriptionClients[socket];
  });
});
