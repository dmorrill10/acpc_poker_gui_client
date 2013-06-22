root = exports ? this

root.wagerAmountField = ->
  $('.wager_amount-num_field > input#modifier')

root.Hotkey =
  bind: (elementToClick, key) ->
    eventName = "keypress.action-#{elementToClick}"
    @bindToDocumentAndWagerAmountField(elementToClick, key, eventName)
  bindToDocumentAndWagerAmountField: (elementToClick, key, eventName)->
    @bindTo(elementToClick, key, eventName, document)
    @bindTo(elementToClick, key, eventName, wagerAmountField())
  bindTo: (elementToClick, key, eventName, elementToWhichToBind)->
    $(elementToWhichToBind).off("#{eventName}").on("#{eventName}", null, key, (evt)->
      $(elementToClick).click() unless $(elementToClick).is(':disabled')
    )