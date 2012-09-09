Hotkey =
  bind: (element, key) ->
    $(document).bind('keypress', key, (evt)->
      elementOnPage = $(element)
      elementOnPage.click() unless elementOnPage.is(':disabled')
    )

Hotkey.bind('#fold.button', 'a')
Hotkey.bind('#pass.button', 's')
Hotkey.bind('#wager.button', 'd')
Hotkey.bind('#leave.button', 'q')
Hotkey.bind('#next.button', 'f')