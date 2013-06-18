Hotkey =
  bind: (element, key) ->
    $(document).bind('keypress', key, (evt)->
      elementOnPage = $(element)
      elementOnPage.click() unless elementOnPage.is(':disabled')
    )

# @todo Make these proper constants
Hotkey.bind('.fold', 'a')
Hotkey.bind('.pass', 's')
Hotkey.bind('.wager', 'd')
Hotkey.bind('#leave', 'q')
Hotkey.bind('.next_state', 'f')