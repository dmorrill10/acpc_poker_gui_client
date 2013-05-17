root = exports ? this

root.BotSelection =
  makeDynamicAccordingToGameDef: ->
    $('.match_player_names').each((index)->
      bots = $(this).html()
      # console.log(bots)
      $('#match_game_definition_key').change ->
        game_def = $('#match_game_definition_key :selected').text()
        # console.log("#{game_def}")
        filtered = $(bots).filter("optgroup[label='#{game_def}']")
        # console.log("#{filtered.html()}")
        options = filtered.html()
        # console.log(options)
        if options
          $('.match_player_names').html(options).parent().show()
        else
          $('.match_player_names').empty().parent().hide()
    )
  selectDefaultGameDef: ->
    $('#match_game_definition_key').trigger('change')
