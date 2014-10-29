root = exports ? this

root.Realtime =
  playerActionChannel: ()-> "#{@playerActionChannelPrefix}#{@matchId}"
  playerCommentChannel: ()-> "#{@playerCommentChannelPrefix}#{@matchId}"

  connect: (
    realtimeConstantsUrl,
    tableManagerConstantsUrl,
    updateMatchQueueUrl,
    landingUrl,
    matchHomeUrl,
    leaveMatchUrl
  )->
    console.log 'Realtime#connect'

    @numUpdatesInQueue = 0
    @updateMatchQueueUrl = updateMatchQueueUrl
    @matchHomeUrl = matchHomeUrl
    @leaveMatchUrl = leaveMatchUrl
    @matchId = ''

    @windowState = "opening"

    # Only start the app after a connection has been made
    onConnection = (socket)=>
      console.log "Realtime#connect: onConnection: windowState: #{@windowState}"
      if @windowState is "opening"
        @leaveMatch()
        @listenToMatchQueueUpdates()
        @controllerAction landingUrl

    serverUrl = "http://#{document.location.hostname}"
    $.getJSON(realtimeConstantsUrl, (constants)=>
      console.log 'Realtime#connect: $.getJSON(realtimeConstantsUrl): success'
      # @todo This can maybe be @socket = io();
      @socket = io.connect("#{serverUrl}:#{constants.REALTIME_SERVER_PORT}")
      @socket.on 'connect', onConnection
    ).fail(=> # Fallback to default
      console.log 'Realtime#connect: $.getJSON(realtimeConstantsUrl): failure'
      @socket = io.connect("#{serverUrl}:5001")
      @socket.on 'connect', onConnection
    )
    $.getJSON(tableManagerConstantsUrl, (constants)=>
      console.log 'Realtime#connect: $.getJSON(tableManagerConstantsUrl): success'
      @playerActionChannelPrefix = constants.PLAYER_ACTION_CHANNEL_PREFIX
      @playerCommentChannelPrefix = constants.PLAYER_COMMENT_CHANNEL_PREFIX
      @updateMatchQueueChannel = constants.UPDATE_MATCH_QUEUE_CHANNEL
    ).fail(=> # Fallback to default
      console.log 'Realtime#connect: $.getJSON(tableManagerConstantsUrl): failure'
      @playerActionChannelPrefix = "player-action-in-"
      @playerCommentChannelPrefix = "player-comment-in-"
      @updateMatchQueueChannel = 'update_queue_count'
    )

  # To Rails server
  #================
  controllerAction: (urlArg, dataArg = {})->
    $.ajax({type: "POST", url: urlArg, data: dataArg, dataType: 'script'})
  updateMatchQueue: (message='')->
    console.log "Realtime#updateMatchQueue: message: #{message}, @windowState: #{@windowState}"
    @controllerAction @updateMatchQueueUrl if @windowState is "open"
  forceUpdateState: ()-> @controllerAction @matchHomeUrl
  updateState: ()->
    return @numUpdatesInQueue += 1 if @numUpdatesInQueue > 0
    @forceUpdateState()
    @numUpdatesInQueue += 1
  finishedUpdating: (update = true)->
    return false unless @numUpdatesInQueue > 0
    @numUpdatesInQueue -= 1
    @forceUpdateState() if @numUpdatesInQueue > 0 && update
  startMatch: (url, optionArgs = '')-> @controllerAction url, {options: optionArgs}
  startProxy: (url)-> @controllerAction url
  playAction: (url, actionArg)-> @controllerAction url, {poker_action: actionArg}

  # From Node.js server
  #====================
  listenToMatchQueueUpdates: ()->
    console.log "Realtime#listenToMatchQueueUpdates: @updateMatchQueueChannel: #{@updateMatchQueueChannel}"
    @socket.on @updateMatchQueueChannel, => @updateMatchQueue()

  onPlayerAction: (message='')->
    console.log "Realtime#onPlayerAction: message: #{message}"
    Realtime.updateState()

  onMatchHasStarted: (message='')->
    console.log "Realtime#onMatchHasStarted: message: #{message}"
    @socket.removeAllListeners @playerActionChannel()
    @socket.on @playerActionChannel(), => @onPlayerAction()
    @windowState = "match"
    @updateState()

  listenForMatchToStart: (matchId)->
    console.log "Realtime#listenForMatchToStart: matchId: #{matchId}, @windowState: #{@windowState}"
    return if @windowState is "waiting"
    @matchId = matchId
    window.onunload = (event)=> @controllerAction @leaveMatchUrl
    @socket.once @playerActionChannel(), => @onMatchHasStarted()
    @windowState = "waiting"

  # From Rails server
  #==================
  leaveMatch: ->
    @windowState = "open"
    @matchId = ""