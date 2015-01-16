root = exports ? this

class MatchWindow
  constructor: -> @timer = Timer.new
  start: ->
  constructor: (matchId)->
    console.log "MatchWindow#constructor: matchId: #{matchId}"
    @matchId = matchId
    @matchSliceIndex = -1
    @isSpectating = false
    @tookAction = false
    @timer = new ActionTimer
  close: ->
    @timer.clear()
    null
  playAction: (actionArg)->
    @tookAction = true
    AjaxCommunicator.sendPost Routes.play_action_path(), {poker_action: actionArg}
  finishedUpdating: ->
    @tookAction = false


root.MatchWindow = MatchWindow
