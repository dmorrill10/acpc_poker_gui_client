root = exports ? this

class WindowManager
  class Poller
    constructor: (@pollFn, @period)->
      @_timer = new Timer
    stop: -> @_timer.clear()
    start: ->
      @stop() if @_timer.isCounting()
      @_timer.start(@pollFn, @period)

  class PollingSubWindow
    constructor: (@poller)->
      @poller.start()
    stop: -> @poller.stop()
    close: ->
      @stop()
      null

  class PollingWindow
    constructor: (@subWindow)->
    replace: (newPollingSubWindow)->
      @subWindow.close()
      @subWindow = newPollingSubWindow
    close: ->
      @subWindow.close()

  @packageMatchData: (matchId, sliceIndexString)->
    {
      match_id: matchId,
      match_slice_index: parseInt(sliceIndexString, 10)
    }


  class MatchStartWindow extends PollingWindow
    class MatchQueueUpdateWindow extends PollingSubWindow
      class MatchQueueUpdatePoller extends Poller
        @PERIOD: 2000
        constructor: (pollFn)->
          console.log "MatchQueueUpdatePoller#constructor"
          super(pollFn, @constructor.PERIOD)

      constructor: ->
        console.log "MatchQueueUpdateWindow#constructor"
        super(new MatchQueueUpdatePoller(=> AjaxCommunicator.get Routes.update_match_queue_path()))

    class WaitingForMatchWindow extends PollingSubWindow
      class WaitingForMatchPoller extends Poller
        @PERIOD: 2000
        constructor: (pollFn)->
          console.log "WaitingForMatchPoller#constructor"
          super(pollFn, @constructor.PERIOD)

      constructor: (matchData)->
        console.log "WaitingForMatchWindow#constructor: matchData: #{JSON.stringify(matchData)}"
        matchData.load_previous_messages = true
        super(
          new WaitingForMatchPoller(
            => AjaxCommunicator.post(
              Routes.match_home_path(),
              matchData
            )
          )
        )

    constructor: (alertMessage=null)->
      console.log "MatchStartWindow#constructor: alertMessage: #{alertMessage}"
      @showMatchEntryPage alertMessage
      super(new MatchQueueUpdateWindow)

    waitForMatchToStart: (@matchData)->
      console.log "MatchStartWindow#waitForMatchToStart: matchData: #{JSON.stringify(matchData)}"
      if !@isWaitingForMatchToStart()
        @subWindow.close()
        @replace(new WaitingForMatchWindow(@matchData))

    isWaitingForMatchToStart: ->
      console.log "MatchStartWindow#isWaitingForMatchToStart"
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
        @timer = new ActionTimer(onActionTimeout)
        super(new MatchSliceWindowPoller(=> @updateState()))

      close: ->
        @timer.clear()
        super()

      updateState: ->
        console.log "MatchSliceWindow#updateState"
        @timer.pause()
        @_reload(=> @_updateState())
      playAction: (actionArg)->
        console.log "MatchSliceWindow#playAction: actionArg: #{actionArg}"
        @timer.stop()
        params = @matchData
        params.poker_action = actionArg
        AjaxCommunicator.post(Routes.play_action_path(), params)
      nextHand: ->
        @timer.stop()
        @_reload(=> AjaxCommunicator.post(Routes.update_match_path(), @matchData))
      finishUpdating: (newMatchData, sliceData)->
        console.log "MatchSliceWindow#finishUpdating: newMatchData: #{JSON.stringify(newMatchData)}, sliceData: #{JSON.stringify(sliceData)}"
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

      leaveMatch: (alertMessage=null)->
        @timer.stop()
        params = @matchData
        params.alert_message = alertMessage
        AjaxCommunicator.post(Routes.leave_match_path(), params)

      _reload: (reloadMethod)->
        @summaryInfoManager = new SummaryInformationManager
        @stop()
        reloadMethod()

      _updateState: ()->
        console.log "MatchSliceWindow#forceUpdateState"
        AjaxCommunicator.post Routes.match_home_path(), @matchData

    constructor: (matchData, onActionTimeout)->
      console.log "PlayerActionsWindow#constructor: matchData: #{JSON.stringify(matchData)}"
      super(new MatchSliceWindow(matchData, onActionTimeout))

    nextHand: -> @subWindow.nextHand()
    playAction: (actionArg)-> @subWindow.playAction actionArg

    finishUpdating: (matchData, sliceData)->
      console.log "PlayerActionsWindow#finishUpdating"
      @subWindow.finishUpdating matchData, sliceData

    leaveMatch: (alertMessage=null)->
      @subWindow.leaveMatch alertMessage

    emitChatMessage: (user, msg)->
      console.log "PlayerActionsWindow#emitChatMessage"
        # @socket.emit(
        #   @constructor.constants.PLAYER_COMMENT,
        #   {
        #     matchId: @matchId,
        #     user: user,
        #     message: msg
        #   }
        # )

    onPlayerComment: (data='')->
      console.log "PlayerActionsWindow#onPlayerComment: data: #{data}"
      # Chat.chatBox.addMessage data.user, data.message

  constructor: ->
    @window = new MatchStartWindow

  waitForMatchToStart: (matchData)->
    console.log "WindowManager#waitForMatchToStart: matchData: #{JSON.stringify(matchData)}"
    if 'waitForMatchToStart' of @window
      matchData.match_slice_index = 0 if matchData.match_slice_index < 0
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
    if 'leaveMatch' of @window
      @window.leaveMatch alertMessage
    else
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

  finishUpdating: ->
    console.log "WindowManager#finishedUpdating"
    @window.subWindow.poller.start()

  finishedUpdatingMatchStartWindow: ->
    console.log "WindowManager#finishedUpdatingMatchStartWindow"
    @finishUpdating()

  finishUpdatingPlayerActionsWindow: (matchData, sliceData)->
    matchData.match_slice_index += 1
    unless @window instanceof PlayerActionsWindow
      @_initPlayerActionsWindow matchData
    @window.finishUpdating(matchData, sliceData)

  _initPlayerActionsWindow: (matchData)->
    @window.close()
    onActionTimeout = =>
      # if @isSpectating
      #   alert('The match has timed out.')
      # else
      @leaveMatch('The match has timed out.')
    @window = new PlayerActionsWindow(matchData, onActionTimeout)

root.WindowManager = WindowManager
