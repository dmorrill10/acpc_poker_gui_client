root = exports ? this

root.ActionDashboard =
  disableButtonsOnClick: ->
    $('button').click(->
      $('button').not('.leave-btn').not('.close').not('.cancel').attr("disabled", true)
    )
  illogicalWagerSize: (wager_to_amount_over_round)->
    !wager_to_amount_over_round or isNaN(wager_to_amount_over_round)
  tooSmallOrIllogicalWager: (wager_to_amount_over_round, minimum_wager_to)->
    if (
      @illogicalWagerSize(wager_to_amount_over_round) or
      wager_to_amount_over_round < minimum_wager_to
    )
      if @illogicalWagerSize(wager_to_amount_over_round)
        alert "Illegal wager of #{wager_to_amount_over_round}. Please submit a proper wager amount."
      else
        if wager_to_amount_over_round < minimum_wager_to
          alert "Wager of #{wager_to_amount_over_round} is too small. Consider making a minimum wager of #{minimum_wager_to} instead."
      wagerAmountField().val(minimum_wager_to.toString())
      true
    else
      false
  tooLargeWager: (wager_to_amount_over_round, all_in_to)->
    if wager_to_amount_over_round > all_in_to
      alert "Wager of #{wager_to_amount_over_round} is too large for your stack size. Please consider an all-in wager of #{all_in_to} instead."
      wagerAmountField().val(all_in_to.toString())
      true
    else
      false
  adjustWagerOnSubmission: (minimum_wager_to, user_contributions_in_previous_rounds, all_in_to, allowed_wagers = [])->
    wagerSubmission().click((e)=>
      if wagerAmountField().length == 0
        return
      wager_to_amount_over_round = parseInt(wagerAmountField().val())

      if @tooLargeWager(wager_to_amount_over_round, all_in_to) or @tooSmallOrIllogicalWager(wager_to_amount_over_round, minimum_wager_to) or (allowed_wagers.length > 0 and wager_to_amount_over_round != all_in_to and wager_to_amount_over_round not in allowed_wagers)
        return e.stopImmediatePropagation()
      wager_to_amount_over_hand = wager_to_amount_over_round + user_contributions_in_previous_rounds

      wagerAmountField().val(wager_to_amount_over_hand.toString())
    )
  fixEnterWagerSubmission: ->
    wagerAmountField().keypress((evt)->
      if evt.keyCode == 13 && !$('.wager').attr('disabled')
        evt.preventDefault()
        $('.wager').click()
    )