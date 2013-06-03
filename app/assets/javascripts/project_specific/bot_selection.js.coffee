root = exports ? this

root.BotSelection =
  selectedGameDef: ->
    $('#match_game_definition_key :selected')
  filterOptions: (gameDefSelector, opponentSelector, bots)->
    gameDef = @selectedGameDef().text()
    # console.log("#{gameDef}")
    filtered = $(bots).filter("optgroup[label='#{gameDef}']")
    # console.log("#{filtered.html()}")
    options = filtered.html()
    # console.log(options)
    if options
      opponentSelector.html(options).parent().show()
    else
      opponentSelector.empty().parent().hide()
  fillSeatSelector: (numPlayers, seatSelector)->
    # @todo This feels a little hacky; I don't like manipulating
    #   the DOM like this, but it should be all right for now.
    options = '<option value="">Random</option>'
    for i in [1..numPlayers] by 1
      options += "<option value='#{i}'>#{i}</option>"
    seatSelector.html(options).parent().show()
  copyOpponentSelectors: (numPlayers, opponentSelector)->
    numExtraOpponents = numPlayers - 2
    copiedSelectors = ''
    copyOpponentSelector = opponentSelector.clone().addClass('copy')[0].outerHTML
    for i in [1..numExtraOpponents] by 1
      copiedSelectors += copyOpponentSelector
    opponentSelector.after(copiedSelectors) unless copiedSelectors == ''
  showProperNumOfOpponents: (gameDefSelector, opponentSelector, seatSelector)->
    numPlayers = parseInt(@selectedGameDef().data('num_players'))
    @fillSeatSelector(numPlayers, seatSelector)
    @copyOpponentSelectors(numPlayers, opponentSelector)
  makeDynamicAccordingToGameDef: ->
    opponentSelector = $('.match_opponent_names').not('.copy')
    bots = opponentSelector.html()
    seatSelector = $('select#match_seat')
    $('#match_game_definition_key').change =>
      # Clear old selectors
      $('.match_opponent_names.copy').remove()
      # Filter the options of the original selector
      @filterOptions(this, opponentSelector, bots)
      # Copy the filtered original selector the proper number of times
      @showProperNumOfOpponents(this, opponentSelector, seatSelector)
  selectDefaultGameDef: ->
    $('#match_game_definition_key').trigger('change')