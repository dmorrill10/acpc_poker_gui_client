root = exports ? this

class WindowManager
  class Poller
    constructor: (@pollFn, @period)->
      @timer = new Timer
    stop: -> @timer.clear()
    start: ->
      @stop() if @timer.isCounting()
      @timer.start(@pollFn, @period)

  class PollingSubWindow
    constructor: (@poller)->
      @poller.start()
    close: ->
      @poller.stop()
      null

  class PollingWindow
    constructor: (@subWindow)->
    replace: (newPollingSubWindow)->
      @subWindow.close()
      @subWindow = newPollingSubWindow
    close: ->
      @subWindow.close()

  class MatchStartWindow extends PollingWindow
    class MatchQueueUpdateWindow extends PollingSubWindow
      class MatchQueueUpdatePoller extends Poller
        @PERIOD: 2000
        constructor: (pollFn)-> super(pollFn, @constructor.PERIOD)

      constructor: ->
        super(new MatchQueueUpdatePoller(=> AjaxCommunicator.get Routes.update_match_queue_path()))

    class WaitingForMatchWindow extends PollingSubWindow
      class WaitingForMatchPoller extends Poller
        @PERIOD: 2000
        constructor: (pollFn)-> super(pollFn, @constructor.PERIOD)

      constructor: (matchData)->
        console.log "WaitingForMatchWindow#constructor: matchData: #{matchData}"
        matchData.load_previous_messages = true
        super(
          new WaitingForMatchPoller(
            => AjaxCommunicator.post Routes.match_home_path(),
            matchData
          )
        )

    constructor: (alertMessage=null)->
      console.log 'MatchStartWindow#constructor'
      @showMatchEntryPage alertMessage
      super(new MatchQueueUpdateWindow)

    waitForMatchToStart: (@matchData)->
      console.log "MatchStartWindow#waitForMatchToStart: matchData: #{matchData}"
      if !@isWaitingForMatchToStart()
        @subWindow.close()
        @replace(new WaitingForMatchWindow(@matchData))

    isWaitingForMatchToStart: ->
      @subWindow instanceof WaitingForMatchWindow

    showMatchEntryPage: (alertMessage = null)->
      console.log "MatchStartWindow#showMatchEntryPage: alertMessage: #{alertMessage}"
      if alertMessage?
        AjaxCommunicator.get Routes.root_path(), {alert_message: alertMessage}
      else
        AjaxCommunicator.get Routes.root_path()


  class PlayerActionsWindow extends PollingWindow
    class MatchSliceWindow extends PollingSubWindow
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

      constructor: (@matchData, onActionTimeout)->
        @isSpectating = false
        @timer = new ActionTimer onActionTimeout
        super(new MatchSliceWindowPoller(=> @updateState()))

      close: ->
        @timer.clear()
        super()

      updateState: ->
        console.log "MatchSliceWindowPoller#updateState"
        @matchWindow.timer.pause()
        @_reload(=> @_updateState())
      playAction: (actionArg)->
        params = @matchData
        params.poker_action = actionArg
        AjaxCommunicator.post(Routes.play_action_path(), params)
      nextHand: ->
        @_reload(=> AjaxCommunicator.post(Routes.update_match_path(), @matchData))
      finishUpdating: (newMatchData, sliceData)->
        if newMatchData.match_slice_index >= @matchData.match_slice_index or not @timer.isCounting()
          @timer.start()
        else
          @timer.resume()
        @summaryInfoManager.update()
        @matchData = newMatchData
        if sliceData.is_users_turn_to_act or sliceData.next_hand_button_is_visible
          @stop()
        else
          @start()

      _reload: (reloadMethod)->
        @summaryInfoManager = new SummaryInformationManager
        @stop()
        reloadMethod()

      _updateState: ()->
        console.log "MatchSliceWindowPoller#forceUpdateState"
        AjaxCommunicator.post Routes.match_home_path(), @matchData

    constructor: (matchId, matchSliceIndex, onActionTimeout)->
      console.log "PlayerActionsWindow#constructor: matchId: #{matchId}, matchSliceIndex: #{matchSliceIndex}"
      super(new MatchSliceWindow(matchId, matchSliceIndex, onActionTimeout))

    nextHand: -> @subWindow.nextHand()
    playAction: (actionArg)-> @subWindow.playAction actionArg

    finishUpdating: (matchData, sliceData)->
      @subWindow.finishUpdating matchData, sliceData

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

  waitForMatchToStart: (matchData)->
    console.log "WindowManager#waitForMatchToStart: matchData: #{matchData}"
    if 'waitForMatchToStart' of @window
      matchData.match_slice_index += 1
      @window.waitForMatchToStart matchData
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

    @_initPlayerActionsWindow @window.matchData

  finishedUpdatingMatchStartWindow: ->
    console.log "WindowManager#finishedUpdatingMatchStartWindow"
    @window.subWindow.poller.start()

  finishUpdatingPlayerActionsWindow: (matchData, sliceData)->
    matchData.match_slice_index += 1
    unless @window instanceof PlayerActionsWindow
      @_initPlayerActionsWindow matchData
    @window.finishUpdating(matchData, sliceData)

  _initPlayerActionsWindow: (matchData)->
    @window.close()
    onActionTimeout = =>
      # if @matchWindow.isSpectating
      #   alert('The match has timed out.')
      # else
      @leaveMatch('The match has timed out.')
    @window = new PlayerActionsWindow(matchData, onActionTimeout)

root.WindowManager = WindowManager
