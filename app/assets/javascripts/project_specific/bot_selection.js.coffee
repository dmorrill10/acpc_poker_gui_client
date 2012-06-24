root = exports ? this

root.BotSelection =
  makeDynamicAccordingToGameDef: ->
    bots = $('#match_bot').html()
    console.log(bots)
    $('#match_game_definition_key').change ->
      game_def = $('#match_game_definition_key :selected').text()
      escaped_game_def = game_def.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/@])/g, '\\$1')
      options = $(bots).filter("optgroup[label=#{escaped_game_def}]").html()
      console.log(options)
      if options
        $('#match_bot').html(options)   
      else
        $('#match_bot').empty()
  selectDefaultGameDef: ->
    $('#match_game_definition_key').trigger('change')
