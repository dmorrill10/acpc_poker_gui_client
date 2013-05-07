root = exports ? this

root.BotSelection =
  makeDynamicAccordingToGameDef: ->
    bots = $('#match_bot').html()
    console.log(bots)
    $('#match_game_definition_key').change ->
      game_def = $('#match_game_definition_key :selected').text()
      #console.log("#{escaped_game_def}")
      filtered = $(bots).filter("optgroup[label='#{game_def}']")
      #console.log("#{filtered.html()}")
      options = filtered.html()
      #console.log(options)
      if options
        $('#match_bot').html(options).parent().show()
      else
        $('#match_bot').empty().parent().hide()
  selectDefaultGameDef: ->
    $('#match_game_definition_key').trigger('change')
