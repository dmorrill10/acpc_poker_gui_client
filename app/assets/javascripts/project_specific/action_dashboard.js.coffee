root = exports ? this

root.ActionDashboard =
  disableButtonsOnClick: ->
    $('button').click(->
      return if this.id is 'leave'

      $('button').attr("disabled", true)
      $(this).attr("disabled", false)
    )
  adjustWagerOnSubmission: (minimum_wager_to, user_contributions_in_previous_rounds)->
    $('form.wager > button.wager').click((e)->
      if $('.wager_amount-num_field > input#modifier').length == 0
        return
      wager_to_amount_over_round = parseInt($('.wager_amount-num_field > input#modifier').val())
      if (
        !wager_to_amount_over_round or
        isNaN(wager_to_amount_over_round) or
        wager_to_amount_over_round < minimum_wager_to
      )
        if wager_to_amount_over_round < minimum_wager_to
          alert "Wager of #{wager_to_amount_over_round} is too small. Making a minimum wager of #{minimum_wager_to} instead."
        wager_to_amount_over_round = minimum_wager_to
      wager_to_amount_over_hand = wager_to_amount_over_round + user_contributions_in_previous_rounds

      $('form.wager > input#modifier').val(wager_to_amount_over_hand.toString())
    )
  fixEnterWagerSubmission: ->
    $('.wager_amount-num_field > input#modifier').keypress((evt)->
      if evt.keyCode == 13
        evt.preventDefault()
        $('form.wager > button.wager').click()
    )
