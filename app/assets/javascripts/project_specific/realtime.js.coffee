root = exports ? this

root.Realtime =
  # From server
  #============

  # @todo These constant prefixes are duplicated in constants.json
  # because I'm not sure where or how constants.json should be parsed on
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

  # To server
  #==========
  send: (channel, args)->
    args["match_id"] = @matchId
    @socket.emit channel, args
  startMatch: (optionArgs, logDirectory)->
    @send "dealer", {options: optionArgs, log_directory: logDirectory}
  startProxy: ()-> @send "proxy", {}
  playAction: (actionArg)-> @send "play", {action: actionArg}

  deleteIrrelevantMatches: ()-> @socket.emit 'delete_irrelevant_matches'

Realtime.connect()