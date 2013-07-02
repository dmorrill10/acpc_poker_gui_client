root = exports ? this

root.wagerAmountField = ->
  $('.wager_amount-num_field > input#modifier')
root.wagerSubmission = ->
  $('.wager')

root.Hotkey =
  bind: (elementToClick, key) ->
    eventName = "keypress.action-#{elementToClick}"
    @bindToDocumentAndWagerAmountField(key, eventName, (evt)->
      $(elementToClick).click() unless $(elementToClick).is(':disabled')
    )
  bindToDocumentAndWagerAmountField: (key, eventName, callback)->
    @bindTo(key, eventName, document, callback)
    @bindTo(key, eventName, wagerAmountField(), callback)
  bindTo: (key, eventName, elementToWhichToBind, callback)->
    return if isBlank(key) or isBlank(eventName) or isBlank(elementToWhichToBind)
    $(elementToWhichToBind).off("#{eventName}").on("#{eventName}", null, key, callback)
  bindWager: (fraction, amountToWager, key) ->
    @bindToDocumentAndWagerAmountField(key, "keypress.action-#{fraction}", (evt)->
      wagerAmountField().val(amountToWager)
      wagerSubmission().click() unless wagerSubmission().is(':disabled')
    )