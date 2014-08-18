root = exports ? this

root.Realtime =
  playerActionChannel: ()-> "#{@playerActionChannelPrefix}#{@user}"
  playerCommentChannel: ()-> "#{@playerCommentChannelPrefix}#{@user}"
  startExhibitionMatchChannel: ()-> "#{@startExhibitionMatchChannelPrefix}#{@user}"

  connect: (realtimeConstantsUrl, tableManagerConstantsUrl, updateMatchQueueUrl, user, startExhibitionMatchUrl, matchHomeUrl)->
    @numUpdatesInQueue = 0
    @updateMatchQueueUrl = '/'
    @matchHomeUrl = '/'
    @user = ''
    $.getJSON(realtimeConstantsUrl, (constants)=>
      @socket = io.connect("http://0.0.0.0:#{constants.REALTIME_SERVER_PORT}")
      @listenToMatchQueueUpdates updateMatchQueueUrl
      @listenToStartExhibitionMatch user, startExhibitionMatchUrl
      @listenToPlayerAction user, matchHomeUrl
    ).fail(=> # Fallback to default
      console.log 'Unable to retrieve Realtime constants, falling back to default'
      @socket = io.connect("http://0.0.0.0:5001")
    )
    $.getJSON(tableManagerConstantsUrl, (constants)=>
      @playerActionChannelPrefix = constants.PLAYER_ACTION_CHANNEL_PREFIX
      @playerCommentChannelPrefix = constants.PLAYER_COMMENT_CHANNEL_PREFIX
      @updateMatchQueueChannel = constants.UPDATE_MATCH_QUEUE_CHANNEL
      @startExhibitionMatchChannelPrefix = constants.START_EXHIBITION_MATCH_CHANNEL_PREFIX
    ).fail(=> # Fallback to default
      console.log 'Unable to retrieve TableManager constants, falling back to default'
      @playerActionChannelPrefix = "player-action-in-"
      @playerCommentChannelPrefix = "player-comment-in-"
      @updateMatchQueueChannel = 'update_queue_count'
      @startExhibitionMatchChannelPrefix = 'start_exhibition_match-'
    )

  # To Rails server
  #================
  controllerAction: (urlArg, dataArg = {})->
    $.ajax({type: "POST", url: urlArg, data: dataArg})
  updateMatchQueue: (message='')-> @controllerAction @updateMatchQueueUrl
  forceUpdateState: ()-> @controllerAction @matchHomeUrl
  updateState: ()->
    if @numUpdatesInQueue > 0
      return @numUpdatesInQueue += 1
    @forceUpdateState()
    @numUpdatesInQueue += 1
  finishedUpdating: (update = true)->
    return false unless @numUpdatesInQueue > 0
    @numUpdatesInQueue -= 1
    if @numUpdatesInQueue > 0
      @forceUpdateState() if update
  startMatch: (url, optionArgs = '')->
    @controllerAction url, {options: optionArgs}
  startProxy: (url)-> @controllerAction url
  playAction: (url, actionArg)-> @controllerAction url, {poker_action: actionArg}
  startExhibitionMatch: (msg='')-> @controllerAction @startExhibitionMatchUrl

  # From Node.js server
  #====================
  listenToMatchQueueUpdates: (updateMatchQueueUrl)->
    @updateMatchQueueUrl = updateMatchQueueUrl
    @socket.on @updateMatchQueueChannel, @updateMatchQueue

  listenToPlayerAction: (user, matchHomeUrl)->
    @user = user
    @matchHomeUrl = matchHomeUrl
    @onPlayerAction = (message)-> Realtime.updateState()
    @socket.on @playerActionChannel(), @onPlayerAction
    @socket.removeListener @updateMatchQueueChannel, @updateMatchQueue
    @socket.removeListener @startExhibitionMatchChannel(), @startExhibitionMatch

  listenToStartExhibitionMatch: (user, startExhibitionMatchUrl)->
    @startExhibitionMatchUrl = startExhibitionMatchUrl
    @user = user
    @socket.on @startExhibitionMatchChannel(), @startExhibitionMatch