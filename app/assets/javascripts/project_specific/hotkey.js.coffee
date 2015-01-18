root = exports ? this

root.wagerAmountField = ->
  $('.wager_amount-num_field > input#modifier')
root.wagerSubmission = ->
  $('.wager')

root.Hotkey =
  bind: (elementToClick, key) ->
    console.log "Hotkey::bind: elementToClick: #{elementToClick}, key: #{key}"
    eventName = "keypress.action-#{elementToClick}"
    @bindToDocumentAndWagerAmountField(
      key,
      eventName,
      (evt)=>
        return if $(elementToClick).is(':disabled')
        $(elementToClick).click()
    )
  bindToDocumentAndWagerAmountField: (key, eventName, callback)->
    @bindTo(key, eventName, document, callback)
    @bindTo(key, eventName, wagerAmountField(), callback)
  bindTo: (key, eventName, elementToWhichToBind, callback)->
    return if (
      WindowManager.isBlank(key) or
      WindowManager.isBlank(eventName) or
      WindowManager.isBlank(elementToWhichToBind)
    )
    $(elementToWhichToBind).off("#{eventName}").on("#{eventName}", null, key, callback)
  bindWager: (fraction, amountToWager, key)->
    @bindToDocumentAndWagerAmountField(
      key,
      "keypress.action-#{fraction}",
      (evt)=>
        wagerAmountField().val(amountToWager)
        unless wagerSubmission().is(':disabled')
          wagerSubmission().click()
    )
