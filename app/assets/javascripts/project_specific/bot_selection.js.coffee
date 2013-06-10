root = exports ? this

root.BotSelection =
  GAME_DEF_SELECTOR: '#match_game_definition_key'
  OPPONENT_SELECTOR: '.match_opponent_names'
  OPPONENT_SELECTOR_OBJ: -> $(@OPPONENT_SELECTOR).not('.copy')
  selectedGameDef: -> DynamicSelector.selected(@GAME_DEF_SELECTOR)
  filterOptions: (bots)->
    DynamicSelector.filterOptions(@GAME_DEF_SELECTOR, @OPPONENT_SELECTOR, bots)
  fillSeatSelector: (numPlayers, seatSelector)->
    # @todo This feels a little hacky; I don't like manipulating
    #   the DOM like this, but it should be all right for now.
    options = '<option value="">Random</option>'
    for i in [1..numPlayers] by 1
      options += "<option value='#{i}'>#{i}</option>"
    seatSelector.html(options).parent().show()
  copyOpponentSelectors: (numPlayers)->
    numExtraOpponents = numPlayers - 2
    copiedSelectors = ''
    copyOpponentSelector = @OPPONENT_SELECTOR_OBJ().clone().addClass('copy')[0].outerHTML
    for i in [1..numExtraOpponents] by 1
      copiedSelectors += copyOpponentSelector
    @OPPONENT_SELECTOR_OBJ().after(copiedSelectors) unless copiedSelectors == ''
  showProperNumOfOpponents: (seatSelector)->
    numPlayers = parseInt(@selectedGameDef().data('num_players'))
    @fillSeatSelector(numPlayers, seatSelector)
    @copyOpponentSelectors(numPlayers)
  makeDynamicAccordingToGameDef: ->
    bots = @OPPONENT_SELECTOR_OBJ().html()
    seatSelector = $('select#match_seat')
    $(@GAME_DEF_SELECTOR).change =>
      # Clear old selectors
      $("#{@OPPONENT_SELECTOR}.copy").remove()
      # Filter the options of the original selector
      @filterOptions(bots)
      # Copy the filtered original selector the proper number of times
      @showProperNumOfOpponents(seatSelector)
  selectDefaultGameDef: ->
    DynamicSelector.selectDefault(@GAME_DEF_SELECTOR)