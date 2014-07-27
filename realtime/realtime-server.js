var path = require('path'),
    appDir = path.dirname(require.main.filename),
    config = require(appDir + '/../config/constants');

var io = require('socket.io')(config.REALTIME_SERVER_PORT);

var Redis = require('redis');
var Sidekiq = require('sidekiq');

return io.on('connection', function(socket){
  var messageSubscriptionClient = Redis.createClient();
  messageSubscriptionClient.subscribe(config.REALTIME_CHANNEL);

  // From background processor
  messageSubscriptionClient.on('message', function(channel, message){
    var parsedMessage = JSON.parse(message);

    socket.emit(parsedMessage.channel, parsedMessage.channel);
  });

  // To background processing queue
  var messagePublishClient = Redis.createClient();
  var workQueue = new Sidekiq(messagePublishClient, process.env.Node_ENV);
  var enqueueForTableManager = function (requestCode, args) {
    console.log("realtime-server: Enqueueing job: " + requestCode + ", args: " + JSON.stringify(args));

    return workQueue.enqueue(
      config.POKER_MANAGER,
      [requestCode].concat(args),
      {
        retry: false,
        queue: "default"
      }
    );
  };
  socket.on(config.START_MATCH_REQUEST_CODE, function (msg) {
    return enqueueForTableManager(
      config.START_MATCH_REQUEST_CODE,
      msg
    );
  });
  socket.on(config.START_PROXY_REQUEST_CODE, function (msg) {
    return enqueueForTableManager(
      config.START_PROXY_REQUEST_CODE,
      msg
    );
  });
  socket.on(config.PLAY_ACTION_REQUEST_CODE, function (msg) {
    return enqueueForTableManager(
      config.PLAY_ACTION_REQUEST_CODE,
      msg
    );
  });
  return socket.on(config.DELETE_IRRELEVANT_MATCHES_REQUEST_CODE, function (msg) {
    return enqueueForTableManager(
      config.DELETE_IRRELEVANT_MATCHES_REQUEST_CODE,
      msg
    );
  });
});
