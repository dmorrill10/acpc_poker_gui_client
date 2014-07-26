root = exports ? this

root.Realtime =
  # @todo These constant prefixes are duplicated in constants.json
  # because I'm not sure where constants.json should be parsed on
  # the JS side of the app
  playerActionChannel: ()-> "player-action-in-#{@matchId}"
  playerCommentChannel: ()-> "player-comment-in-#{@matchId}"
  connect: ()->
    @numUpdatesInQueue = 0
    # @todo Port number is defined in constants.json
    @socket = io.connect('http://0.0.0.0:5001');
  forceUpdateState: ()-> $(".hidden-update_match").submit()
  updateState: ()->
    return @numUpdatesInQueue += 1 if @numUpdatesInQueue > 0
    @forceUpdateState()
    @numUpdatesInQueue += 1
  finishedUpdating: ()->
    @numUpdatesInQueue -= 1
    @forceUpdateState() if @numUpdatesInQueue > 0
  listenToPlayerAction: (matchId)->
    @matchId = matchId
    @onPlayerAction = (message)-> Realtime.updateState()
    @socket.on @playerActionChannel(), @onPlayerAction
  listenToPlayerComment: (doFn)->
    @onPlayerComment = doFn
    @socket.on @playerCommentChannel(), doFn

Realtime.connect()