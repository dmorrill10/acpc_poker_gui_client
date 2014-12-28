root = exports ? this

class MatchWindow
  constructor: (matchId)->
    console.log "MatchWindow#constructor: matchId: #{matchId}"
    @matchId = matchId
  playerActionChannel: ()-> "#{TableManager.constants.PLAYER_ACTION_CHANNEL_PREFIX}#{@matchId}"
  playerCommentChannel: ()-> "#{TableManager.constants.PLAYER_COMMENT_CHANNEL_PREFIX}#{@matchId}"
  spectateNextHandChannel: ()-> "#{Realtime.constants.SPECTATE_NEXT_HAND_CHANNEL}#{@matchId}"

root.MatchWindow = MatchWindow
