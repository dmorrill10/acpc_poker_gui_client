root = exports ? this

root.Realtime =
  playerActionChannel: ()-> "#{@playerActionChannelPrefix}#{@matchId}"
  playerCommentChannel: ()-> "#{@playerCommentChannelPrefix}#{@matchId}"
  spectateNextHandChannel: ()-> "#{@spectateNextHandChannelPrefix}#{@matchId}"


  alreadySubscribed: (e)->
    @socket._callbacks[e]? and @socket._callbacks[e].length > 0 and @socket._callbacks[e][0]?

  unsubscribe: (e)->
    console.log "Realtime#unsubscribe: e: #{e}"
    @socket.removeAllListeners e

  connect: (
    realtimeConstantsUrl,
    tableManagerConstantsUrl,
    updateMatchQueueUrl,
    landingUrl,
    matchHomeUrl,
    leaveMatchUrl,
    nextHandUrl
  )->
    console.log 'Realtime#connect'

    @numUpdatesInQueue = 0
    @updateMatchQueueUrl = updateMatchQueueUrl
    @matchHomeUrl = matchHomeUrl
    @leaveMatchUrl = leaveMatchUrl
    @nextHandUrl = nextHandUrl
    @matchId = ''

    @windowState = "opening"

    # Only start the app after a connection has been made
    onConnection = (socket)=>
      console.log "Realtime#connect: onConnection: windowState: #{@windowState}"
      if @windowState is "opening"
        @windowState = "open"
        @matchId = ""
        @listenToMatchQueueUpdates()
        @controllerAction landingUrl

    serverUrl = "http://#{document.location.hostname}"
    $.getJSON(realtimeConstantsUrl, (constants)=>
      console.log 'Realtime#connect: $.getJSON(realtimeConstantsUrl): success'
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
      @spectateNextHandChannelPrefix = constants.SPECTATE_NEXT_HAND_CHANNEL
      @nextHandCode = constants.NEXT_HAND
    ).fail(=> # Fallback to default
      console.log 'Realtime#connect: $.getJSON(tableManagerConstantsUrl): failure'
      @playerActionChannelPrefix = "player-action-in-"
      @playerCommentChannelPrefix = "player-comment-in-"
      @updateMatchQueueChannel = 'update_queue_count'
      @spectateNextHandChannelPrefix = 'spectate-next-hand-in-'
      @nextHandCode = 'next-hand'
    )

  # To Rails server
  #================
  controllerAction: (urlArg, dataArg = {})->
    $.ajax({type: "POST", url: urlArg, data: dataArg, dataType: 'script'})
  updateMatchQueue: (message='')->
    console.log "Realtime#updateMatchQueue: message: #{message}, @windowState: #{@windowState}"
    @controllerAction @updateMatchQueueUrl if @windowState is "open"
  forceUpdateState: ()->
    console.log "Realtime#forceUpdateState"
    @controllerAction @matchHomeUrl, {match_id: @matchId}
  updateState: ()->
    console.log "Realtime#updateState: numUpdatesInQueue: #{@numUpdatesInQueue}"
    return @numUpdatesInQueue += 1 if @numUpdatesInQueue > 0
    @forceUpdateState()
    @numUpdatesInQueue += 1
  finishedUpdating: (update = true)->
    console.log "Realtime#finishedUpdating: @numUpdatesInQueue: #{@numUpdatesInQueue}"
    return false unless @numUpdatesInQueue > 0
    @numUpdatesInQueue -= 1
    @forceUpdateState() if @numUpdatesInQueue > 0 && update
  startMatch: (url, optionArgs = '')-> @controllerAction url, {options: optionArgs}
  startProxy: (url)-> @controllerAction url
  playAction: (url, actionArg)-> @controllerAction url, {poker_action: actionArg}
  nextHand: ->
    console.log "Realtime#nextHand"
    @socket.send @nextHandCode, { matchId: @matchId }
    @controllerAction @nextHandUrl

  # From Node.js server
  #====================
  listenToMatchQueueUpdates: ()->
    console.log "Realtime#listenToMatchQueueUpdates: @updateMatchQueueChannel: #{@updateMatchQueueChannel}"
    @socket.on @updateMatchQueueChannel, (msg)=> @updateMatchQueue(msg)

  onPlayerAction: (message='')->
    console.log "Realtime#onPlayerAction: message: #{message}"
    Realtime.updateState()

  onMatchHasStarted: (message='')->
    console.log "Realtime#onMatchHasStarted: message: #{message}"
    return if @windowState is "match"

    @unsubscribe @playerActionChannel()
    @socket.on(@playerActionChannel(), (msg)=> @onPlayerAction(msg)) unless @alreadySubscribed(@playerActionChannel())
    @windowState = "match"
    @updateState()

  listenForMatchToStart: (matchId)->
    console.log "Realtime#listenForMatchToStart: matchId: #{matchId}, @windowState: #{@windowState}"
    return if @windowState is "waiting"
    @matchId = matchId
    window.onunload = (event)=> @controllerAction @leaveMatchUrl

    @unsubscribe @updateMatchQueueChannel
    @unsubscribe @playerActionChannel()
    @socket.on @playerActionChannel(), (msg)=> @onMatchHasStarted(msg)
    @windowState = "waiting"

  # From Rails server
  #==================
  leaveMatch: ->
    console.log "Realtime#leaveMatch: @windowState: #{@windowState}"
    return if @windowState isnt "match"

    @unsubscribe @playerActionChannel()
    @windowState = "open"
    @matchId = ""
    @listenToMatchQueueUpdates()
    @stopSpectating()

  stopSpectating: ->
    console.log "Realtime#stopSpectating"
    @unsubscribe @spectateNextHandChannel()

  spectate: ->
    console.log "Realtime#spectate: #{@spectateNextHandChannel()}"
    @socket.on @spectateNextHandChannel(), (msg)=> @nextHand()