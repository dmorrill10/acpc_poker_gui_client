root = exports ? this

root.ActionDashboard =
  takeAction: (idOfSubmissionElement)->
    submissionElement = $(idOfSubmissionElement)
    submissionElement.submit() unless submissionElement.is(':disabled')
  registerHiddenAction: (triggerId)->
    $("##{triggerId}").click(->
      ActionDashboard.takeAction("#hidden-#{triggerId}")
    )
  disableButtonsOnClick: ->
    $('.btn').click(->
      return if this.id is 'leave'

      $('.btn:not(.hidden)').attr("disabled", true)
      $(this).attr("disabled", false)
    )
  adjustWagerOnSubmission: (minimum_wager_to, user_contributions_in_previous_rounds)->
    $('#hidden-wager.with_modifier').submit((e)->
      wager_to_amount_over_round = parseInt($('input#user_poker_action_modifier').val())
      if (
        !wager_to_amount_over_round or
        isNaN(wager_to_amount_over_round) or
        wager_to_amount_over_round < minimum_wager_to
      )
        if wager_to_amount_over_round < minimum_wager_to
          alert "Wager of #{wager_to_amount_over_round} is too small. Making a minimum wager of #{minimum_wager_to} instead."
        wager_to_amount_over_round = minimum_wager_to
      wager_to_amount_over_hand = wager_to_amount_over_round + user_contributions_in_previous_rounds

      $('input#user_poker_action_modifier').val(wager_to_amount_over_hand.toString())
    )
  fixEnterWagerSubmission: ->
    $('input#user_poker_action_modifier').keypress((evt)->
      if evt.keyCode == 13
        evt.preventDefault()
        $('#hidden-wager.with_modifier').submit()
    )
