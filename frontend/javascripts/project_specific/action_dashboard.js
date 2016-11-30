let ActionDashboard = {
  disableButtonsOnClick() {
    return $('button').not('.close').not('.cancel').not('.navbar-toggle').click(() => $('button').not('.leave-btn').not('.close').not('.cancel').not('.navbar-toggle').attr("disabled", true));
  },
  enableButtons() {
    return $('button').not('.leave-btn').not('.close').not('.cancel').not('.navbar-toggle').removeAttr("disabled");
  },
  illogicalWagerSize(wager_to_amount_over_round){
    return !wager_to_amount_over_round || isNaN(wager_to_amount_over_round);
  },
  tooSmallOrIllogicalWager(wager_to_amount_over_round, minimum_wager_to){
    if (
      this.illogicalWagerSize(wager_to_amount_over_round) ||
      wager_to_amount_over_round < minimum_wager_to
    ) {
      if (this.illogicalWagerSize(wager_to_amount_over_round)) {
        alert(`Illegal wager of ${wager_to_amount_over_round}. Please submit a proper wager amount.`);
      } else {
        if (wager_to_amount_over_round < minimum_wager_to) {
          alert(`Wager of ${wager_to_amount_over_round} is too small. Consider making a minimum wager of ${minimum_wager_to} instead.`);
        }
      }
      wagerAmountField().val(minimum_wager_to.toString());
      return true;
    } else {
      return false;
    }
  },
  tooLargeWager(wager_to_amount_over_round, all_in_to){
    if (wager_to_amount_over_round > all_in_to) {
      alert(`Wager of ${wager_to_amount_over_round} is too large for your stack size. Please consider an all-in wager of ${all_in_to} instead.`);
      wagerAmountField().val(all_in_to.toString());
      return true;
    } else {
      return false;
    }
  },
  adjustWagerOnSubmission(minimum_wager_to, user_contributions_in_previous_rounds, all_in_to){
    return wagerSubmission().click(e=> {
      if (wagerAmountField().length === 0) {
        return;
      }
      let wager_to_amount_over_round = parseInt(wagerAmountField().val());

      if (this.tooLargeWager(wager_to_amount_over_round, all_in_to) || this.tooSmallOrIllogicalWager(wager_to_amount_over_round, minimum_wager_to)) {
        this.enableButtons();
        return e.stopImmediatePropagation();
      }
      let wager_to_amount_over_hand = wager_to_amount_over_round + user_contributions_in_previous_rounds;

      return wagerAmountField().val(wager_to_amount_over_hand.toString());
    }
    );
  },
  fixEnterWagerSubmission() {
    return wagerAmountField().keypress(function(evt){
      if (evt.keyCode === 13 && !$('.wager').attr('disabled')) {
        evt.preventDefault();
        return $('.wager').click();
      }
    });
  }
};
export default ActionDashboard;
