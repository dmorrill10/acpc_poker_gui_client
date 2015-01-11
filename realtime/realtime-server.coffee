Winston = require 'winston'

Path = require('path')
Path.APP_Dir = Path.dirname(require.main.filename)

TableManager = require(Path.APP_Dir + '/../app/workers/table_manager/table_manager.json')

Redis = require('redis')
Redis.MESSAGE_CHANNEL = 'message'

Realtime = require(Path.APP_Dir + '/realtime')
SocketIo = require('socket.io')

startRealtimeServer = ->
  updateMatchQueueClient = Redis.createClient()
  updateMatchQueueClient.subscribe TableManager.UPDATE_MATCH_QUEUE_CHANNEL

  updateFromPlayerActionClient = Redis.createClient()
  updateFromPlayerActionClient.subscribe TableManager.REALTIME_CHANNEL

  socketIoServer = SocketIo(Realtime.REALTIME_SERVER_PORT)
  Winston.info "startRealtimeServer: Listening on port #{Realtime.REALTIME_SERVER_PORT}"

  onRedisMessage = (channel, message)->
    Winston.log('info', "onRedisMessage: Message \"#{message}\" on #{channel}. Alerting all sockets")
    data = JSON.parse(message)
    socketIoServer.sockets.in(data.room).emit data.channel
  updateMatchQueueClient.on(Redis.MESSAGE_CHANNEL, onRedisMessage)
  updateFromPlayerActionClient.on(Redis.MESSAGE_CHANNEL, onRedisMessage)

  onConnection = (socket)->
    Winston.log 'info', "onConnection: New connection: #{socket.id}"

    socket.on Realtime.NEXT_HAND, (data)->
      Winston.log('info', 'realtime-server: Alert from ' + socket.id + ': ' + Realtime.SPECTATE_NEXT_HAND_CHANNEL + data.matchId)
      socket.broadcast.to(data.matchId).emit Realtime.SPECTATE_NEXT_HAND_CHANNEL + data.matchId
    socket.on Realtime.PLAYER_COMMENT, (data)->
      Winston.log 'info', "SocketIo.on::#{Realtime.PLAYER_COMMENT}: Alert from " + socket.id + ': {' + data.matchId + ", " + data.user + ", " + data.message + "}. Emitting on " + Realtime.PLAYER_COMMENT_CHANNEL_PREFIX + data.matchId
      # To spectators
      socket.broadcast.to(data.matchId).emit Realtime.PLAYER_COMMENT_CHANNEL_PREFIX + data.matchId, {user: data.user, message: data.message}
    socket.on 'join', (data)-> socket.join(data.room)
    socket.on 'leave', (data)-> socket.leave(data.room)


  socketIoServer.on 'connection', onConnection

startRealtimeServer()


# debug = ->
#   LoadContext =
#     name: "myplugin"
#     description: "Some description here"
#     setup: (context)->
#       Winston.log 'info', 'LoadContext::setup'
#     preStart: (context)->
#       Winston.log 'info', 'LoadContext::preStart'
#       global.Path = Path
#       global.Util = Util
#       global.TableManager = TableManager
#       global.Redis = Redis
#       global.Realtime = Realtime
#       global.SocketIo = SocketIo
#     postStart: (context)->
#       Winston.log 'info', 'LoadContext::postStart'

#   class Debugger
#     constructor: ->
#       @nesh = require('nesh')

#       @opts = {
#         welcome: '',
#         prompt: 'debug> ',
#         useColors: true,
#         useGlobal: true
#       }

#       # Load user configuration
#       @nesh.config.load()

#       # Load CoffeeScript
#       @nesh.loadLanguage('coffee')

#       @nesh.loadPlugin LoadContext, (err) =>
#         # Start the REPL
#         @nesh.start @opts, (err)=>
#           @nesh.log.error(err) if err
#   new Debugger
