root = exports ? this

root.ActionDashboard =
  disableButtonsOnClick: ->
    $('button').click(->
      $('button').not('.leave-btn').not('.close').not('.cancel').attr("disabled", true)
    )
  illogicalWagerSize: (wager_to_amount_over_round)->
    !wager_to_amount_over_round or isNaN(wager_to_amount_over_round)
  adjustSmallOrIllogicalWager: (wager_to_amount_over_round, minimum_wager_to)->
    if (
      @illogicalWagerSize(wager_to_amount_over_round) or
      wager_to_amount_over_round < minimum_wager_to
    )
      if wager_to_amount_over_round < minimum_wager_to
        alert "Wager of #{wager_to_amount_over_round} is too small. Making a minimum wager of #{minimum_wager_to} instead."
      minimum_wager_to
    else
      wager_to_amount_over_round
  adjustLargeWager: (wager_to_amount_over_round, all_in_to)->
    if wager_to_amount_over_round > all_in_to
      alert "Wager of #{wager_to_amount_over_round} is too large for your stack size, going all-in instead."
      all_in_to
    else
      wager_to_amount_over_round
  adjustWagerOnSubmission: (minimum_wager_to, user_contributions_in_previous_rounds, all_in_to)->
    wagerSubmission().click((e)=>
      if wagerAmountField().length == 0
        return
      wager_to_amount_over_round = parseInt(wagerAmountField().val())
      wager_to_amount_over_round = @adjustSmallOrIllogicalWager(wager_to_amount_over_round, minimum_wager_to)
      wager_to_amount_over_round = @adjustLargeWager(wager_to_amount_over_round, all_in_to)
      wager_to_amount_over_hand = wager_to_amount_over_round + user_contributions_in_previous_rounds

      wagerAmountField().val(wager_to_amount_over_hand.toString())
    )
  fixEnterWagerSubmission: ->
    wagerAmountField().keypress((evt)->
      if evt.keyCode == 13 && !$('.wager').attr('disabled')
        evt.preventDefault()
        $('.wager').click()
    )