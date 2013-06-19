root = exports ? this

root.Hotkey =
  bind: (element, key) ->
    eventName = "keypress.action-#{element}"
    $(document).off("#{eventName}").on("#{eventName}", null, key, (evt)->
      $(element).click() unless $(element).is(':disabled')
    )