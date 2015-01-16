root = exports ? this

class WindowManager
  class Poller
    constructor: (pollFn, period)->
      @pollFn = pollFn
      @period = period
      @timer = Timer
    stop: -> @timer.clear()
    start: ->
      @timer.start(@pollFn, @period)

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
    close: ->
      @subWindow.close()

  class MatchStartWindow extends PollingWindow
    class MatchQueueUpdateWindow extends SubWindow
      class MatchQueueUpdatePoller extends Poller
        @PERIOD: 2000
        constructor: (pollFn)-> super(pollFn, @constructor.PERIOD)

      constructor: ->
        super(new MatchQueueUpdatePoller(=> AjaxCommunicator.get Routes.update_match_queue_path()))

    class WaitingForMatchWindow extends SubWindow
      class WaitingForMatchPoller extends Poller
        @PERIOD: 2000
        constructor: (pollFn)-> super(pollFn, @constructor.PERIOD)

      constructor: (matchId, matchSliceIndex)->
        super(
          new WaitingForMatchPoller(
            => AjaxCommunicator.post Routes.match_home_path(),
            {match_id: matchId, match_slice_index: matchSliceIndex, load_previous_messages: true}
          )
        )

    constructor: (alertMessage=null)->
      console.log 'MatchStartWindow#constructor'
      @showMatchEntryPage alertMessage
      super(new MatchQueueUpdateWindow)

    waitForMatchToStart: (@matchId, @matchSliceIndex)->
      replace(new WaitingForMatchWindow(@matchId, @matchSliceIndex))

    showMatchEntryPage: (alertMessage = null)->
      console.log "Realtime#showMatchEntryPage: alertMessage: #{alertMessage}"
      @resetState()
      if alertMessage?
        AjaxCommunicator.sendPost Routes.root_path(), {alert_message: alertMessage}
      else
        AjaxCommunicator.sendGet Routes.root_path()


  class PlayerActionsWindow extends PollingWindow
    class MatchSliceWindow extends SubWindow
      class SummaryInformationManager
        constructor: ()->
          @savedSummaryInfo = $('.summary_information').html()

        update: ()->
          $('.summary_information').prepend(@savedSummaryInfo)
          summaryInfo = document.getElementById('summary_information')
          summaryInfo.scrollTop = summaryInfo.scrollHeight

      class MatchSliceWindowPoller extends Poller
        @PERIOD: 500
        constructor: (pollFn)-> super(pollFn, @constructor.PERIOD)

      constructor: (@matchId, @matchSliceIndex, onActionTimeout)->
        @isSpectating = false
        @timer = new ActionTimer onActionTimeout
        super(new MatchSliceWindowPoller(=> @updateState()))

      close: ->
        @timer.clear()
        super()

      matchData: -> {match_id: @matchId, match_slice_index: @matchSliceIndex}

      updateState: ->
        console.log "MatchSliceWindowPoller#updateState"
        @matchWindow.timer.pause()
        @_reload(=> @_updateState())
      playAction: (actionArg)->
        params = @matchData()
        params.poker_action = actionArg
        AjaxCommunicator.sendPost(Routes.play_action_path(), params)
      nextHand: ->
        @_reload(=> AjaxCommunicator.sendPost(Routes.update_match_path(), @matchData()))
      finishUpdating: (matchSliceIndexString)->
        nextSliceIndex = parseInt(matchSliceIndexString, 10)
        if nextSliceIndex > @matchSliceIndex or not @timer.isCounting()
          @timer.start()
        else
          @timer.resume()
        @summaryInfoManager.update()
        @matchSliceIndex = nextSliceIndex

      _reload: (reloadMethod)->
        @summaryInfoManager = new SummaryInformationManager
        reloadMethod()

      _updateState: ()->
        console.log "MatchSliceWindowPoller#forceUpdateState"
        AjaxCommunicator.sendPost Routes.match_home_path(), @matchData

    constructor: (matchId, matchSliceIndex, onActionTimeout)->
      console.log "PlayerActionsWindow#constructor: matchId: #{matchId}, matchSliceIndex: #{matchSliceIndex}"
      super(new MatchSliceWindow(matchId, matchSliceIndex, onActionTimeout))

    nextHand: -> @subWindow.nextHand()
    playAction: (actionArg)-> @subWindow.playAction actionArg

    finishUpdating: (matchSliceIndexString)->
      @subWindow.finishUpdating matchSliceIndexString

    emitChatMessage: (user, msg)->
      console.log "Realtime#emitChatMessage"
        # @socket.emit(
        #   @constructor.constants.PLAYER_COMMENT,
        #   {
        #     matchId: @matchWindow.matchId,
        #     user: user,
        #     message: msg
        #   }
        # )

    onPlayerComment: (data='')->
      console.log "Realtime#onPlayerComment: data: #{data}"
      # Chat.chatBox.addMessage data.user, data.message

  constructor: ->
    @window = new MatchStartWindow

  waitForMatchToStart: (matchId, matchSliceIndex)->
    if 'waitForMatchToStart' of @window
      @window.waitForMatchToStart matchId, matchSliceIndex
    else
      console.log("WindowManager#waitForMatchToStart: WARNING: Called when @window is not a MatchStartWindow!")

  showMatchEntryPage: (alertMessage=null)->
    @window.close()
    @window = new MatchStartWindow(alertMessage)

  nextHand: ->
    console.log "WindowManager#nextHand"
    if 'nextHand' of @window
      @window.nextHand()
    else
      console.log("WindowManager#nextHand: WARNING: Called when @window is not a PlayerActionsWindow!")

  playAction: (actionArg)->
    console.log "WindowManager#playAction: actionArg: #{actionArg}"
    if 'playAction' of @window
      @window.playAction actionArg
    else
      console.log("WindowManager#playAction: WARNING: Called when @window is not a PlayerActionsWindow!")

  leaveMatch: (alertMessage=null)->
    @showMatchEntryPage alertMessage

  onMatchHasStarted: ->
    console.log "WindowManager#onMatchHasStarted"

    window.onunload = (event)=> @leaveMatch()

    # Chat.init(
    #   @userName,
    #   (id, user, msg)=>
    #     @emitChatMessage user, msg
    # )

    @_initPlayerActionsWindow @window.matchId, @window.matchSliceIndex

  finishUpdatingPlayerActionsWindow: (matchSliceIndex)->
    unless @window instanceof PlayerActionsWindow
      @_initPlayerActionsWindow @window.matchId, @window.matchSliceIndex
    @window.finishUpdating(matchSliceIndex)

  _initPlayerActionsWindow: (matchId, matchSliceIndex)->
    @window.close()
    onActionTimeout = =>
      # if @matchWindow.isSpectating
      #   alert('The match has timed out.')
      # else
      @leaveMatch('The match has timed out.')
    @window = new PlayerActionsWindow(matchId, matchSliceIndex, onActionTimeout)

root.WindowManager = WindowManager
