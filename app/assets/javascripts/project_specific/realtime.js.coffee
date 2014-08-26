root = exports ? this

root.Realtime =
  playerActionChannel: ()-> "#{@playerActionChannelPrefix}#{@matchId}"
  playerCommentChannel: ()-> "#{@playerCommentChannelPrefix}#{@matchId}"

  connect: (
    realtimeConstantsUrl,
    tableManagerConstantsUrl,
    updateMatchQueueUrl,
    landingUrl
  )->
    @numUpdatesInQueue = 0
    @updateMatchQueueUrl = '/'
    @matchHomeUrl = '/'
    @matchId = ''

    # Only start the app after a connection has been made
    onConnection = (socket)=>
      @listenToMatchQueueUpdates updateMatchQueueUrl
      @controllerAction landingUrl

    serverUrl = "http://#{document.location.hostname}"
    $.getJSON(realtimeConstantsUrl, (constants)=>
      @socket = io.connect("#{serverUrl}:#{constants.REALTIME_SERVER_PORT}")
      @socket.on 'connect', onConnection
    ).fail(=> # Fallback to default
      console.log 'Unable to retrieve Realtime constants, falling back to default'
      @socket = io.connect("#{serverUrl}:5001")
      @socket.on 'connect', onConnection
    )
    $.getJSON(tableManagerConstantsUrl, (constants)=>
      @playerActionChannelPrefix = constants.PLAYER_ACTION_CHANNEL_PREFIX
      @playerCommentChannelPrefix = constants.PLAYER_COMMENT_CHANNEL_PREFIX
      @updateMatchQueueChannel = constants.UPDATE_MATCH_QUEUE_CHANNEL
    ).fail(=> # Fallback to default
      console.log 'Unable to retrieve TableManager constants, falling back to default'
      @playerActionChannelPrefix = "player-action-in-"
      @playerCommentChannelPrefix = "player-comment-in-"
      @updateMatchQueueChannel = 'update_queue_count'
    )

  # To Rails server
  #================
  controllerAction: (urlArg, dataArg = {})->
    $.ajax({type: "POST", url: urlArg, data: dataArg, dataType: 'script'})
  updateMatchQueue: (message='')-> @controllerAction @updateMatchQueueUrl
  forceUpdateState: ()-> @controllerAction @matchHomeUrl
  updateState: ()->
    if @numUpdatesInQueue > 0
      return @numUpdatesInQueue += 1
    @forceUpdateState()
    @numUpdatesInQueue += 1
  finishedUpdating: (update = true)->
    return false unless @numUpdatesInQueue > 0
    @numUpdatesInQueue -= 1
    if @numUpdatesInQueue > 0
      @forceUpdateState() if update
  startMatch: (url, optionArgs = '')->
    @controllerAction url, {options: optionArgs}
  startProxy: (url)-> @controllerAction url
  playAction: (url, actionArg)-> @controllerAction url, {poker_action: actionArg}

  # From Node.js server
  #====================
  listenToMatchQueueUpdates: (updateMatchQueueUrl)->
    @updateMatchQueueUrl = updateMatchQueueUrl
    @socket.on @updateMatchQueueChannel, @updateMatchQueue

  onPlayerAction: (message='')-> Realtime.updateState()

  onMatchHasStarted: (message='')->
    # Disconnect this method from its channel
    @socket.removeListener @playerActionChannel(), @onMatchHasStarted
    # Stop listening to queue updates
    @socket.removeListener @updateMatchQueueChannel, @updateMatchQueue
    # Connect new method to this channel
    @socket.on @playerActionChannel(), @onPlayerAction

  listenForMatchToStart: (matchId, matchHomeUrl)->
    @matchId = matchId
    @matchHomeUrl = matchHomeUrl
    @socket.on @playerActionChannel(), @onMatchHasStarted
