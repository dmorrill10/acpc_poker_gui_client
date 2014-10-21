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
    var msg = ("message" in parsedMessage) ? parsedMessage.message : parsedMessage.channel
    socket.emit(parsedMessage.channel, msg);
  });

  // @todo This doesn't seem to catch browser closes but I haven't tested
  // enough to be sure. Need to catch browser close, then kill and delete
  // any matches associated with the user. Probably need to send user's
  // name upon connecting so that this server can pass that name to
  // TableManager to kill and delete the match.
  io.on('disconnect', function() {
    console.log("realtime-server: Client disconnection");
  });
});
