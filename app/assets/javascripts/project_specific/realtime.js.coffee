root = exports ? this

# TODO this is a bit of a hack
CONFIG = {
  "ON_TIMEOUT": "leave"
}

class ConsoleLogManager
  @CONSOLE_LOG: console.log
  @consoleIsEnabled: false
  @enableLogger: ->
    console.log = @CONSOLE_LOG
  @disableLogger: ->
    console.log = -> return

root.ConsoleLogManager = ConsoleLogManager

class WindowManager
  @isBlank: (str)-> (!str || /^[\"\'\s]*$/.test(str))
  @isEmpty: (el)-> !$.trim(el.html())

  @onLoadCallbacks: []
  @loadComplete: ->
    console.log "WindowManager::loadComplete: @onLoadCallbacks.length: #{@onLoadCallbacks.length}"
    @onLoadCallbacks.shift()() while @onLoadCallbacks.length > 0
    console.log "WindowManager::loadComplete: Finished all callbacks"

  @packageMatchData: (matchId, sliceIndexString)->
    {
      match_id: matchId,
      match_slice_index: parseInt(sliceIndexString, 10)
    }

  class Poller
    constructor: (@pollFn, @period)->
      @_timer = new Timer
    stop: -> @_timer.clear()
    start: -> @_timer.start(@pollFn, @period)

  class PollingSubWindow
    constructor: (@poller)->
    poll: -> WindowManager.onLoadCallbacks.push => @poller.start()
    stop: -> @poller.stop()
    close: ->
      @stop()
      null
    matchData: -> null
    showMatchEntryPage: (alertMessage = null)->
      console.log "PollingSubWindow#showMatchEntryPage: alertMessage: #{alertMessage}"
      if alertMessage?
        AjaxCommunicator.get Routes.root_path(), {alert_message: alertMessage}
      else
        AjaxCommunicator.get Routes.root_path()
    leaveMatch: (alertMessage=null)->
      if @matchData()?
        console.log "PollingSubWindow#leaveMatch: alertMessage: #{alertMessage}"
        params = @matchData()
        params.alert_message = alertMessage
        @_reload(=> AjaxCommunicator.post(Routes.leave_match_path(), params))
      else
        @_reload(=> @showMatchEntryPage(alertMessage))
    _reload: (reloadMethod)->
      @stop()
      reloadMethod()

  class PollingWindow
    constructor: (@subWindow)->
    replace: (newPollingSubWindow)->
      @subWindow.close()
      @subWindow = newPollingSubWindow
    close: ->
      @subWindow.close()
    leaveMatch: (alertMessage=null)-> @subWindow.leaveMatch alertMessage
    showMatchEntryPage: (alertMessage = null)-> @subWindow.showMatchEntryPage alertMessage

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

      constructor: (@matchData_)->
        console.log "WaitingForMatchWindow#constructor: matchData: #{JSON.stringify(@matchData_)}"
        params = @matchData_
        params.load_previous_messages = true
        super(
          new WaitingForMatchPoller(
            => AjaxCommunicator.post(
              Routes.check_for_match_started_path(),
              params
            )
          )
        )
      matchData: -> @matchData_

    constructor: (alertMessage=null)->
      console.log "MatchStartWindow#constructor: alertMessage: #{alertMessage}"
      super(new MatchQueueUpdateWindow)
      @matchData_ = null
      @showMatchEntryPage alertMessage
    matchData: -> @matchData_
    waitForMatchToStart: (@matchData_)->
      console.log "MatchStartWindow#waitForMatchToStart: matchData: #{JSON.stringify(@matchData_)}"
      unless @isWaitingForMatchToStart()
        console.log "MatchStartWindow#waitForMatchToStart: Not waiting yet"
        @replace(new WaitingForMatchWindow(@matchData_))
        console.log "MatchStartWindow#waitForMatchToStart: Not waiting yet 3"
        @subWindow.poll()
    isWaitingForMatchToStart: ->
      console.log "MatchStartWindow#isWaitingForMatchToStart"
      @subWindow instanceof WaitingForMatchWindow
  class PlayerActionsWindow extends PollingWindow
    class MatchSliceWindow extends PollingSubWindow
      class SummaryInformationManager
        constructor: ()->
          @savedSummaryInfo = $('.summary_information').html()

        update: ()->
          console.log 'SummaryInformationManager#update'
          $('.summary_information').prepend(@savedSummaryInfo)
          summaryInfo = document.getElementById('summary_information')
          summaryInfo.scrollTop = summaryInfo.scrollHeight
          console.log 'SummaryInformationManager#update: Returning'
      class MatchSliceWindowPoller extends Poller
        @PERIOD: 1000
        constructor: (pollFn)-> super(pollFn, @constructor.PERIOD)
      constructor: (@matchData_, onActionTimeout)->
        @isSpectating = false
        @timer = new ActionTimer(onActionTimeout)
        super(new MatchSliceWindowPoller(=> @updateState()))
      matchData: -> @matchData_
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
        params = @matchData_
        params.poker_action = actionArg
        @_reload(=> AjaxCommunicator.post(Routes.play_action_path(), params))
      nextHand: -> @updateState()
      finishUpdating: (newMatchData, sliceData)->
        console.log "MatchSliceWindow#finishUpdating: newMatchData: #{JSON.stringify(newMatchData)}, sliceData: #{JSON.stringify(sliceData)}"
        @_updateActionTimer newMatchData
        @summaryInfoManager.update() if @summaryInfoManager?
        @matchData_ = newMatchData
        GameInterface.adjustScale()
        @_wireActions sliceData
        @_checkToStartPolling sliceData
      leaveMatch: (alertMessage=null)->
        console.log "MatchSliceWindow#leaveMatch: alertMessage: #{alertMessage}"
        @timer.stop()
        super alertMessage

      _wireActions: (sliceData)->
        console.log "MatchSliceWindow#_wireActions: sliceData: #{JSON.stringify(sliceData)}"
        if sliceData.match_has_ended
          $(".leave-btn").click => @leaveMatch()
        else if sliceData.next_hand_button_is_visible
          $(".next_hand_id").click => @nextHand()
        else
          $(".fold").click => @playAction "f"
          $(".pass").click => @playAction "c"
          $(".wager").click =>
            wagerAmount = wagerAmountField().val();
            action = 'r'
            if !WindowManager.isBlank(wagerAmount)
              action += wagerAmount
            @playAction action

      _setInitialFocus: (sliceData)->
        if sliceData.match_has_ended
          $(".leave-btn").focus()
        else if sliceData.next_hand_button_is_visible
          $(".next_hand_id").focus()
        else
          wagerAmountField().focus()

      _updateActionTimer: (newMatchData)->
        console.log "MatchSliceWindow#_updateActionTimer: newMatchData: #{JSON.stringify(newMatchData)}"
        if newMatchData.match_slice_index >= @matchData_.match_slice_index or not @timer.isCounting()
          console.log "MatchSliceWindow#_updateActionTimer: Starting action timer"
          @timer.start()
        else if @matchData_.match_has_ended
          @timer.clear()
        else
          console.log "MatchSliceWindow#_updateActionTimer: Resuming action timer"
          @timer.resume()

      _checkToStartPolling: (sliceData)->
        console.log "MatchSliceWindow#_checkToStartPolling: sliceData: #{JSON.stringify(sliceData)}"
        if sliceData.is_users_turn_to_act or sliceData.next_hand_button_is_visible or sliceData.match_has_ended
          console.log "MatchSliceWindow#finishUpdatingPlayerActionsWindow: No polling"
          @stop()
        else
          console.log "MatchSliceWindow#finishUpdatingPlayerActionsWindow: Started polling"
          @poll()

      _reload: (reloadMethod)->
        @summaryInfoManager = new SummaryInformationManager
        super reloadMethod

      _updateState: ()->
        console.log "MatchSliceWindow#forceUpdateState"
        AjaxCommunicator.post Routes.match_home_path(), @matchData_

    constructor: (matchData, onActionTimeout)->
      console.log "PlayerActionsWindow#constructor: matchData: #{JSON.stringify(matchData)}"
      super(new MatchSliceWindow(matchData, onActionTimeout))

    finishUpdating: (matchData, sliceData)->
      console.log "PlayerActionsWindow#finishUpdating"
      @subWindow.finishUpdating matchData, sliceData

    matchData: -> @subWindow.matchData()

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
    $(window).unload(=> @leaveMatch())
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

  leaveMatch: (alertMessage=null)-> @window.leaveMatch alertMessage

  # onMatchHasStarted: ->
    # console.log "WindowManager#onMatchHasStarted"
    # Chat.init(
    #   @userName,
    #   (id, user, msg)=>
    #     @emitChatMessage user, msg
    # )
    # @_initPlayerActionsWindow @window.matchData

  finishUpdating: ->
    console.log "WindowManager#finishUpdating"
    @window.subWindow.poll()

  finishUpdatingMatchStartWindow: ->
    console.log "WindowManager#finishUpdatingMatchStartWindow"
    @finishUpdating()

  finishUpdatingPlayerActionsWindow: (matchData, sliceData)->
    console.log(
      "WindowManager#finishUpdatingPlayerActionsWindow: matchData:" +
      " #{JSON.stringify(matchData)}, sliceData: #{JSON.stringify(sliceData)}"
    )
    matchData.match_slice_index += 1
    unless @window instanceof PlayerActionsWindow
      $.titleAlert(
        'Match Started!',
        {
          requireBlur: true,
          stopOnFocus: true,
          duration: 55000,
          interval: 700
        }
      )
      @_initPlayerActionsWindow matchData
    @window.finishUpdating(matchData, sliceData)
    console.log "WindowManager#finishUpdatingPlayerActionsWindow: Returning"

  _initPlayerActionsWindow: (matchData)->
    @window.close()
    onActionTimeout = if CONFIG.ON_TIMEOUT == 'fold'
      =>
        if $(".next_hand_id").length != 0
          console.log "WindowManager#_initPlayerActionsWindow: onActionTimeout: Pressing next hand button."
          $(".next_hand_id").click()
        else if $(".fold").attr('disabled') != 'disabled'
          console.log "WindowManager#_initPlayerActionsWindow: onActionTimeout: Pressing fold button."
          $(".fold").click()
        else
          console.log "WindowManager#_initPlayerActionsWindow: onActionTimeout: Pressing pass button."
          $(".pass").click()
    else
      =>
        # if @isSpectating
        #   alert('The match has timed out.')
        # else
        @leaveMatch('The match has timed out.')
    @window = new PlayerActionsWindow(matchData, onActionTimeout)

root.WindowManager = WindowManager
