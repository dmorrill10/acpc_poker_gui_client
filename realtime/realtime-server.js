var path = require('path');
var appDir = path.dirname(require.main.filename);
var config = require('util')._extend(
  require(appDir + '/realtime'),
  require(appDir + '/../app/workers/table_manager')
);

var io = require('socket.io')(config.REALTIME_SERVER_PORT);

var Redis = require('redis');

return io.on('connection', function(socket){
  var messageSubscriptionClient = Redis.createClient();
  messageSubscriptionClient.subscribe(config.REALTIME_CHANNEL);

  // From background processor
  messageSubscriptionClient.on('message', function(channel, message){
    console.log("realtime-server: Alerting view: " + message);

    var parsedMessage = JSON.parse(message);
    socket.emit(parsedMessage.channel, parsedMessage.channel);
  });
});
