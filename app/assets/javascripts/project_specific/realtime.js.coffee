root = exports ? this

class SummaryInformationManager
  constructor: ()->
    @savedSummaryInfo = $('.summary_information').html()

  update: ()->
    $('.summary_information').prepend(@savedSummaryInfo)
    summaryInfo = document.getElementById('summary_information')
    summaryInfo.scrollTop = summaryInfo.scrollHeight

class SubWindow
  constructor: (poller)->
    @poller = poller
    @poller.start()
  close: ->
    @poller.stop()
    null

class PollingWindow
  constructor: (pollingSubWindow)->
    @subWindow = pollingSubWindow
  replace: (newPollingSubWindow)->
    @subWindow.close()
    @subWindow = newPollingSubWindow

class MatchStartWindow extends PollingWindow
  class MatchQueueUpdateWindow extends SubWindow
    class MatchQueueUpdatePoller extends Poller
      constructor: ->
        pollTo = =>
          AjaxCommunicator.get Routes.update_match_queue_path()
        @poller = new Poller(pollTo, 2000)
    constructor: -> super(new MatchQueueUpdatePoller)

  class WaitingForMatchWindow extends SubWindow
    class WaitingForMatchPoller extends Poller
      constructor: (matchId, sliceIndex)->
        pollTo = =>
          AjaxCommunicator.post Routes.match_home_path(), {match_id: matchId, slice_index: sliceIndex}
        @poller = new Poller(pollTo, 2000)
    constructor: -> super(new WaitingForMatchPoller)

  constructor: (matchId, sliceIndex)->
    console.log 'MatchStartWindow#constructor'
    @userName = null
    super(new MatchQueueUpdateWindow(matchId, sliceIndex))

  waitForMatchToStart: (matchId, sliceIndex)->
    replace(new WaitingForMatchWindow(matchId, sliceIndex))

class PlayerActionsWindow
  constructor: ()->
    console.log 'PlayerActionsWindow#constructor'

    @inProcessOfUpdating = false
    @matchWindow = null
    @windowState = "opening"
    @summaryInfoManager = null
    @loadPreviousMessages = false
    @userName = null
    @pollTimer = Timer.new

class Realtime
  @connection: null

  @connect: ()->
    console.log 'Realtime::connect'
    unless @connection?
      @connection = new Realtime
    @connection

  constructor: ()->
    console.log 'Realtime#constructor'

    @inProcessOfUpdating = false
    @matchWindow = null
    @windowState = "opening"
    @summaryInfoManager = null
    @loadPreviousMessages = false
    @userName = null
    @pollTimer = Timer.new

  setTimeout: (fn, period)->
    @pollTimer.clear()
    @pollTimer.start(fn, period)

  inMatchHeartbeat: (period)->
    onTimeout = => @checkForNextSlice()
    @setTimeout(onTimeout, period)

  beforeMatchHeartbeat: (period, match_id, user_name)->
    onTimeout = => @checkForEnquedMatch(match_id, user_name)
    @setTimeout(onTimeout, period)

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
    if @windowState is "match" and not @inProcessOfUpdating
      @updateState()

  checkForNextSliceAtEndOfHand: ->
    console.log "Realtime#checkForNextSliceAtEndOfHand: @windowState: #{@windowState}"
    if @windowState is "match"
      unless @inProcessOfUpdating
        @reloadNextHand()

  updateMatchQueue: (message='')->
    console.log "Realtime#updateMatchQueue: message: #{message}, @windowState: #{@windowState}"
    AjaxCommunicator.sendGet Routes.update_match_queue_path() if @windowState is "open" or @windowState is 'waiting'

  nextHand: ->
    console.log "Realtime#nextHand"
    if @matchWindow?
      @socket.emit @constructor.constants.NEXT_HAND, { matchId: @matchWindow.matchId }
      @reloadNextHand()

  emitChatMessage: (user, msg)->
    console.log "Realtime#emitChatMessage"
    if @matchWindow?
      # @socket.emit(
      #   @constructor.constants.PLAYER_COMMENT,
      #   {
      #     matchId: @matchWindow.matchId,
      #     user: user,
      #     message: msg
      #   }
      # )

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
  startActionTimer: ->
    console.log "Realtime#startActionTimer: @matchWindow?: #{@matchWindow?}"
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
      @startActionTimer()
    else
      @matchWindow.timer.resume()
    @loadPreviousMessages = false
    @inProcessOfUpdating = false
    if @summaryInfoManager?
      @summaryInfoManager.update()
    @matchWindow.matchSliceIndex = nextSliceIndex

  reloadNextHand: ->
    if @matchWindow?
      params = { match_slice_index: @matchWindow.matchSliceIndex }
      @reloadPlayerActionView(=> AjaxCommunicator.sendPost(Routes.update_match_path(), params))

  listenToMatchQueueUpdates: ()->
    console.log "Realtime#listenToMatchQueueUpdates: TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL: #{TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL}"
    unless @alreadySubscribed(TableManager.constants.UPDATE_MATCH_QUEUE_CHANNEL)
      checkForMatchQueueUpdates = => AjaxCommunicator.sendGet Routes.root_path()
      @timer.start(checkForMatchQueueUpdates, 2000)

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

    @startActionTimer() if @matchWindow.isSpectating

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
