root = exports ? this

class TableManager
  @constants:
    {
      PLAYER_ACTION_CHANNEL_PREFIX: "player-action-in-",
      UPDATE_MATCH_QUEUE_CHANNEL: 'update_queue_count'
    }

root.TableManager = TableManager

class SummaryInformationManager
  constructor: ()->
    @savedSummaryInfo = $('.summary_information').html()

  update: ()->
    $('.summary_information').prepend(@savedSummaryInfo)
    summaryInfo = document.getElementById('summary_information')
    summaryInfo.scrollTop = summaryInfo.scrollHeight

class Realtime
  @connection: null
  @constants:
    {
      NEXT_HAND: 'next-hand',
      PLAYER_COMMENT: "player-comment",
      SPECTATE_NEXT_HAND_CHANNEL: 'spectate-next-hand-in-',
      PLAYER_COMMENT_CHANNEL_PREFIX: "player-comment-in-",
      REALTIME_SERVER_PORT: 4162
    }

  @connect: ()->
    console.log 'Realtime::connect'
    unless @connection?
      @connection = new Realtime
    @connection

  constructor: ()->
    console.log 'Realtime#constructor'

    @updateQueue = new CounterQueue

    console.log "Realtime#constructor: @updateQueue: #{@updateQueue}"

    @inProcessOfUpdating = false
    @matchWindow = null
    @windowState = "opening"
    @summaryInfoManager = null
    @loadPreviousMessages = false
    @userName = null
    @timeoutId = null

    # Only start the app after a connection has been made
    onConnection = (socket)=>
      console.log "Realtime#constructor: onConnection: windowState: #{@windowState}"
      @loadPreviousMessages = false
      if @windowState is "opening" or @windowState is 'waiting'
        @showMatchEntryPage()
      else if @windowState is "match"
        @updateQueue.push() if @updateQueue.isEmpty()
        @updateState()

    serverUrl = "http://#{document.location.hostname}"
    $.getJSON(Routes.realtime_constants_path(), (constants)=>
      console.log 'Realtime#constructor: $.getJSON(Routes.realtime_constants_path()): success'
      @constructor.constants = constants
      @socket = io.connect("#{serverUrl}:#{constants.REALTIME_SERVER_PORT}")
      @socket.on 'connect', onConnection
    ).fail(=> # Fallback to default
      console.log 'Realtime#constructor: $.getJSON(Routes.realtime_constants_path()): failure'
      @socket = io.connect("#{serverUrl}:#{@constructor.constants.REALTIME_SERVER_PORT}")
      @socket.on 'connect', onConnection
    )
    $.getJSON(Routes.table_manager_constants_path(), (constants)=>
      console.log 'Realtime#constructor: $.getJSON(Routes.table_manager_constants_path()): success'
      TableManager.constants = constants
    ).fail(=> # Fallback to default
      console.log 'Realtime#constructor: $.getJSON(Routes.table_manager_constants_path()): failure'
    )

  clearTimeout: ->
    if @timeoutId?
      clearTimeout @timeoutId
      @timeoutId = null

  setTimeout: (fn, period)->
    @clearTimeout()
    @timeoutId = setTimeout(fn, period)

  inMatchHeartbeat: (period)->
    onTimeout = => @checkForNextSlice()
    @setTimeout(onTimeout, period)

  beforeMatchHeartbeat: (period, match_id, user_name)->
    onTimeout = => @checkForEnquedMatch()
    @setTimeout(onTimeout, period)

  alreadySubscribed: (e)->
    @socket._callbacks[e]? and @socket._callbacks[e].length > 0 and @socket._callbacks[e][0]?

  unsubscribe: (e)->
    console.log "Realtime#unsubscribe: e: #{e}"
    @socket.removeAllListeners e

  showMatchEntryPage: (alertMessage = null)->
    console.log "Realtime#showMatchEntryPage: alertMessage: #{alertMessage}"
    @resetState()
    AjaxCommunicator.sendPost Routes.root_path(), {alert_message: alertMessage}

  checkForEnquedMatch: (matchId, userName)->
    console.log "Realtime#checkForEnquedMatch: @windowState: #{@windowState}"
    if @windowState isnt "match"
      @loadPreviousMessages = true
      @beforeMatch(matchId, userName)
      @onMatchHasStarted()

  checkForNextSlice: ->
    console.log "Realtime#checkForNextSlice: @windowState: #{@windowState}"
    if @windowState is "match"
      unless @inProcessOfUpdating
        if @updateQueue.isEmpty()
          @enqueueUpdate()
        else
          @updateState()

  checkForNextSliceAtEndOfHand: ->
    console.log "Realtime#checkForNextSliceAtEndOfHand: @windowState: #{@windowState}"
    if @windowState is "match"
      unless @inProcessOfUpdating
        if @updateQueue.isEmpty()
          @updateQueue.push
        @reloadNextHand()

  updateMatchQueue: (message='')->
    console.log "Realtime#updateMatchQueue: message: #{message}, @windowState: #{@windowState}"
    AjaxCommunicator.sendGet Routes.update_match_queue_path() if @windowState is "open" or @windowState is 'waiting'
  playAction: (actionArg)->
    console.log "GameplayManager#updateMatchQueue: actionArg: #{actionArg}, @windowState: #{@windowState}"
    if @windowState is 'match'
      AjaxCommunicator.sendPost Routes.play_action_path(), {poker_action: actionArg}
  nextHand: ->
    console.log "Realtime#nextHand"
    if @matchWindow?
      @socket.emit @constructor.constants.NEXT_HAND, { matchId: @matchWindow.matchId }
      @reloadNextHand()

  emitChatMessage: (user, msg)->
    console.log "Realtime#emitChatMessage"
    if @matchWindow?
      @socket.emit(
        @constructor.constants.PLAYER_COMMENT,
        {
          matchId: @matchWindow.matchId,
          user: user,
          message: msg
        }
      )

  forceUpdateState: ()->
    console.log "Realtime#forceUpdateState: @matchWindow?: #{@matchWindow}"
    if @matchWindow?
      params = {match_id: @matchWindow.matchId}
      if @loadPreviousMessages
        params['load_previous_messages'] = @loadPreviousMessages
        @loadPreviousMessages = false
      params['match_slice_index'] = @matchWindow.matchSliceIndex
      AjaxCommunicator.sendPost Routes.match_home_path(), params
  reloadPlayerActionView: (reloadMethod)->
    @summaryInfoManager = new SummaryInformationManager
    reloadMethod()
  updateState: ->
    console.log "Realtime#updateState: @inProcessOfUpdating: #{@inProcessOfUpdating}"
    unless @inProcessOfUpdating
      @inProcessOfUpdating = true
      @matchWindow.timer.pause() if @matchWindow?
      @reloadPlayerActionView(=> @forceUpdateState())
  startTimer: ->
    console.log "Realtime#startTimer: @matchWindow?: #{@matchWindow?}"
    if @matchWindow?
      onTimeout = =>
        if @matchWindow.isSpectating
          alert('The match has timed out.')
        else
          @leaveMatch('The match has timed out.')
      @matchWindow.timer.startForPlayer onTimeout
  finishedUpdating: (matchSliceIndex)->
    console.log "Realtime#finishedUpdating: matchSliceIndex: #{matchSliceIndex}, @matchWindow.matchSliceIndex: #{@matchWindow.matchSliceIndex}, @inProcessOfUpdating: #{@inProcessOfUpdating}"
    @clearTimeout()
    nextSliceIndex = parseInt(matchSliceIndex, 10)
    if nextSliceIndex > @matchWindow.matchSliceIndex or not @matchWindow.timer.isCounting()
      @startTimer()
    else
      @matchWindow.timer.resume()
    @loadPreviousMessages = false
    @inProcessOfUpdating = false
    @updateQueue.pop()
    if @summaryInfoManager?
      @summaryInfoManager.update()
    @matchWindow.matchSliceIndex = nextSliceIndex
  enqueueUpdate: ->
    console.log "Realtime#enqueueUpdate"
    @updateQueue.push()
    @updateState()
  reloadNextHand: ->
    if @matchWindow?
      params = { match_slice_index: @matchWindow.matchSliceIndex }
      @reloadPlayerActionView(=> AjaxCommunicator.sendPost(Routes.update_match_path(), params))

  listenToMatchQueueUpdates: ()->
    console.log "Realtime#listenToMatchQueueUpdates: TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL: #{TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL}"
    unless @alreadySubscribed(TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL)
      @socket.on TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL, (msg)=> @updateMatchQueue(msg)
      @socket.emit 'join', { room: TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL }

  onPlayerAction: (message='')->
    console.log "Realtime#onPlayerAction: message: #{message}"
    @enqueueUpdate()

  onPlayerComment: (data='')->
    console.log "Realtime#onPlayerComment: data: #{data}"
    Chat.chatBox.addMessage data.user, data.message

  onMatchHasStarted: (message='')->
    console.log "Realtime#onMatchHasStarted: message: #{message}"
    return if @windowState is "match"

    @unsubscribe TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL
    @socket.emit 'leave', { room: TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL }

    @unsubscribe @matchWindow.playerActionChannel()

    window.onunload = (event)=> @leaveMatch()

    @socket.on(@matchWindow.playerActionChannel(), (msg)=> @onPlayerAction(msg))
    @socket.on(@matchWindow.playerCommentChannel(), (msg)=> @onPlayerComment(msg))

    @windowState = "match"

    Chat.init(
      @userName,
      (id, user, msg)=>
        @emitChatMessage user, msg
    )

    @startTimer() if @matchWindow.isSpectating

    @enqueueUpdate()

  beforeMatch: (matchId, userName)->
    @matchWindow.close() if @matchWindow?
    @matchWindow = new MatchWindow(matchId)
    @userName = userName
    @windowState = "waiting"

  listenForMatchToStart: (matchId, userName)->
    console.log "Realtime#listenForMatchToStart: matchId: #{matchId}, userName: #{userName}, @windowState: #{@windowState}"
    return if @windowState is "waiting"

    @beforeMatch matchId, userName
    @unsubscribe @matchWindow.playerActionChannel()
    @socket.on @matchWindow.playerActionChannel(), (msg)=> @onMatchHasStarted(msg)
    @socket.emit 'join', { room: matchId }

  leaveMatch: (alertMessage = null)->
    if @windowState is "match"
      @resetState()
      AjaxCommunicator.sendPost Routes.leave_match_path(), {alert_message: alertMessage}

  resetState: ->
    if @matchWindow?
      @unsubscribe @matchWindow.playerActionChannel()
      @unsubscribe @matchWindow.playerCommentChannel()
      @socket.emit 'leave', { room: @matchWindow.matchId }
      @stopSpectating()
      @matchWindow = @matchWindow.close()
    @clearTimeout()
    Chat.close()
    @inProcessOfUpdating = false
    @userName = null
    @listenToMatchQueueUpdates()
    @windowState = 'open'

  stopSpectating: ->
    console.log "Realtime#stopSpectating"
    if @matchWindow?
      @unsubscribe @matchWindow.spectateNextHandChannel()

  spectate: ->
    console.log "Realtime#spectate"
    if @matchWindow?
      console.log "Realtime#spectate: channel: #{@matchWindow.spectateNextHandChannel()}"
      @matchWindow.isSpectating = true
      @socket.on @matchWindow.spectateNextHandChannel(), (msg)=> @reloadNextHand()

root.Realtime = Realtime
