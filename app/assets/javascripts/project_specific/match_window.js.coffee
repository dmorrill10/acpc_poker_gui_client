root = exports ? this

class MatchWindow
  constructor: (matchId)->
    console.log "MatchWindow#constructor: matchId: #{matchId}"
    @matchId = matchId
    @matchSliceIndex = -1
    @isSpectating = false
    @timer = new Timer
  close: ->
    @timer.clear()
    null
  playerActionChannel: ()-> "#{TableManager.constants.PLAYER_ACTION_CHANNEL_PREFIX}#{@matchId}"
  playerCommentChannel: ()-> "#{Realtime.constants.PLAYER_COMMENT_CHANNEL_PREFIX}#{@matchId}"
  spectateNextHandChannel: ()-> "#{Realtime.constants.SPECTATE_NEXT_HAND_CHANNEL}#{@matchId}"

root.MatchWindow = MatchWindow
