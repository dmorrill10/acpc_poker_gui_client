root = exports ? this

class MatchWindow
  @mw: null
  @init: (matchId)->
    unless @mw?
      @mw = new MatchWindow(matchId)
    @mw
  @close: -> @mw = null
  constructor: (matchId)->
    console.log "MatchWindow#constructor: matchId: #{matchId}"
    @matchId = matchId
  playerActionChannel: ()-> "#{TableManager.constants.PLAYER_ACTION_CHANNEL_PREFIX}#{@matchId}"
  playerCommentChannel: ()-> "#{Realtime.constants.PLAYER_COMMENT_CHANNEL_PREFIX}#{@matchId}"
  spectateNextHandChannel: ()-> "#{Realtime.constants.SPECTATE_NEXT_HAND_CHANNEL}#{@matchId}"

root.MatchWindow = MatchWindow
