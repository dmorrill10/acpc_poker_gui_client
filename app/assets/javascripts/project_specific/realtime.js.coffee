root = exports ? this

root.Realtime =
  # @todo These constant prefixes are duplicated in constants.json
  # because I'm not sure where or how constants.json should be parsed on
  # the JS side of the app
  playerActionChannel: ()-> "player-action-in-#{@matchId}"
  playerCommentChannel: ()-> "player-comment-in-#{@matchId}"

  connect: ()->
    @numUpdatesInQueue = 0
    @matchHomeUrl = '/'
    @matchId = ''
    # @todo Port number is defined in constants.json
    @socket = io.connect('http://0.0.0.0:5001')

  # To Rails server
  #================
  controllerAction: (urlArg, dataArg = {})->
    $.ajax({type: "POST", url: urlArg, data: dataArg})
  forceUpdateState: ()->
    @numUpdatesInQueue -= 1 if @numUpdatesInQueue > 0
    @controllerAction @matchHomeUrl
  updateState: ()->
    return @numUpdatesInQueue += 1 if @numUpdatesInQueue > 0
    @forceUpdateState()
    @numUpdatesInQueue += 1
  finishedUpdating: ()->
    return false unless @numUpdatesInQueue > 0
    @numUpdatesInQueue -= 1
    if @numUpdatesInQueue > 0
      @forceUpdateState()
      true
    else
      false
  # send: (channel, args)->
  #   args["match_id"] = @matchId
  #   @socket.emit channel, args
  startMatch: (url, optionArgs)->
    @controllerAction url, {options: optionArgs}
  startProxy: (url)-> @controllerAction url
  playAction: (url, actionArg)-> @controllerAction url, {poker_action: actionArg}
  deleteIrrelevantMatches: ()-> return false
  # deleteIrrelevantMatches: (url)-> @controllerAction url

  # From Node.js server
  #====================
  listenToPlayerAction: (matchId, matchHomeUrl)->
    @matchId = matchId
    @matchHomeUrl = matchHomeUrl
    @onPlayerAction = (message)-> Realtime.updateState()
    @socket.on @playerActionChannel(), @onPlayerAction

Realtime.connect()