root = exports ? this

class Realtime
  playerActionChannel: ()-> "#{@playerActionChannelPrefix}#{@matchId}"
  playerCommentChannel: ()-> "#{@playerCommentChannelPrefix}#{@matchId}"
  spectateNextHandChannel: ()-> "#{@spectateNextHandChannelPrefix}#{@matchId}"

  alreadySubscribed: (e)->
    @socket._callbacks[e]? and @socket._callbacks[e].length > 0 and @socket._callbacks[e][0]?

  unsubscribe: (e)->
    console.log "Realtime#unsubscribe: e: #{e}"
    @socket.removeAllListeners e

  showMatchEntryPage: ->
    console.log "Realtime#showMatchEntryPage"

    @unsubscribe @playerActionChannel()
    @stopSpectating()
    @windowState = "open"
    @matchId = ""
    @listenToMatchQueueUpdates()
    AjaxCommunicator.sendGet Routes.root_path()

  @connect: ()->
    console.log 'Realtime::connect'
    new Realtime

  constructor: ()->
    console.log 'Realtime#connect'

    @updateQueue = new CounterQueue

    console.log "Realtime#connect: @updateQueue: #{@updateQueue}"

    @inProcessOfUpdating = false
    @matchId = ''
    @windowState = "opening"

    # Only start the app after a connection has been made
    onConnection = (socket)=>
      console.log "Realtime#connect: onConnection: windowState: #{@windowState}"
      @showMatchEntryPage() if @windowState is "opening"

    serverUrl = "http://#{document.location.hostname}"
    $.getJSON(Routes.realtime_constants_path(), (constants)=>
      console.log 'Realtime#connect: $.getJSON(Routes.realtime_constants_path()): success'
      @nextHandCode = constants.NEXT_HAND
      @spectateNextHandChannelPrefix = constants.SPECTATE_NEXT_HAND_CHANNEL
      @socket = io.connect("#{serverUrl}:#{constants.REALTIME_SERVER_PORT}")
      @socket.on 'connect', onConnection
    ).fail(=> # Fallback to default
      console.log 'Realtime#connect: $.getJSON(Routes.realtime_constants_path()): failure'
      @nextHandCode = constants.NEXT_HAND
      @spectateNextHandChannelPrefix = 'spectate-next-hand-in-'
      @socket = io.connect("#{serverUrl}:5001")
      @socket.on 'connect', onConnection
    )
    $.getJSON(Routes.table_manager_constants_path(), (constants)=>
      console.log 'Realtime#connect: $.getJSON(Routes.table_manager_constants_path()): success'
      @playerActionChannelPrefix = constants.PLAYER_ACTION_CHANNEL_PREFIX
      @playerCommentChannelPrefix = constants.PLAYER_COMMENT_CHANNEL_PREFIX
      @updateMatchQueueChannel = constants.UPDATE_MATCH_QUEUE_CHANNEL
    ).fail(=> # Fallback to default
      console.log 'Realtime#connect: $.getJSON(Routes.table_manager_constants_path()): failure'
      @playerActionChannelPrefix = "player-action-in-"
      @playerCommentChannelPrefix = "player-comment-in-"
      @updateMatchQueueChannel = 'update_queue_count'
    )

  # To Rails server
  #================
  updateMatchQueue: (message='')->
    console.log "Realtime#updateMatchQueue: message: #{message}, @windowState: #{@windowState}"
    AjaxCommunicator.sendGet Routes.update_match_queue_path() if @windowState is "open" or 'waiting'
  playAction: (actionArg)->
    console.log "GameplayManager#updateMatchQueue: actionArg: #{actionArg}, @windowState: #{@windowState}"
    if @windowState is 'match'
      AjaxCommunicator.sendPost Routes.play_action_path(), {poker_action: actionArg}
  nextHand: ->
    console.log "Realtime#nextHand"
    if @windowState is 'match'
      @socket.emit @nextHandCode, { matchId: @matchId }
      AjaxCommunicator.sendGet Routes.update_match_path()

  forceUpdateState: ()->
    console.log "Realtime#forceUpdateState"
    if @windowState is 'match'
      AjaxCommunicator.sendPost Routes.match_home_path(), {match_id: @matchId}
  updateState: ->
    console.log "Realtime#updateState: @inProcessOfUpdating: #{@inProcessOfUpdating}"
    if @windowState is 'match' and not @inProcessOfUpdating
      @forceUpdateState()
      @inProcessOfUpdating = true
  finishedUpdating: ->
    console.log "Realtime#finishedUpdating: @inProcessOfUpdating: #{@inProcessOfUpdating}"
    if @windowState is 'match'
      @inProcessOfUpdating = false
      @updateQueue.pop()
  enqueueUpdate: ->
    if @windowState is 'match'
      @updateQueue.push()
      @updateState() unless @inProcessOfUpdating

  # From Node.js server
  #====================
  listenToMatchQueueUpdates: ()->
    console.log "Realtime#listenToMatchQueueUpdates: @updateMatchQueueChannel: #{@updateMatchQueueChannel}"
    @socket.on @updateMatchQueueChannel, (msg)=> @updateMatchQueue(msg)

  onPlayerAction: (message='')->
    console.log "Realtime#onPlayerAction: message: #{message}"
    @enqueueUpdate()

  onMatchHasStarted: (message='')->
    console.log "Realtime#onMatchHasStarted: message: #{message}"
    return if @windowState is "match"

    @unsubscribe @updateMatchQueueChannel
    @unsubscribe @playerActionChannel()
    window.onunload = (event)=> @leaveMatch()
    @socket.on(@playerActionChannel(), (msg)=> @onPlayerAction(msg)) unless @alreadySubscribed(@playerActionChannel())
    @windowState = "match"
    @updateState()

  listenForMatchToStart: (matchId)->
    console.log "Realtime#listenForMatchToStart: matchId: #{matchId}, @windowState: #{@windowState}"
    return if @windowState is "waiting"
    @matchId = matchId

    @unsubscribe @playerActionChannel()
    @socket.on @playerActionChannel(), (msg)=> @onMatchHasStarted(msg)
    @windowState = "waiting"

  leaveMatch: ->
    if @windowState is "match"
      AjaxCommunicator.sendPost Routes.leave_match_path()

  # From Rails server
  #==================
  stopSpectating: ->
    console.log "Realtime#stopSpectating"
    @unsubscribe @spectateNextHandChannel()

  spectate: ->
    console.log "Realtime#spectate: #{@spectateNextHandChannel()}"
    @socket.on @spectateNextHandChannel(), (msg)=> AjaxCommunicator.sendGet(Routes.update_match_path())

root.Realtime = Realtime
