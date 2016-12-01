let BotSelection = {
  GAME_DEF_SELECTOR: '#match_game_definition_key',
  OPPONENT_SELECTOR: '.match_opponent_names',
  OPPONENT_SELECTOR_OBJ() { return $(this.OPPONENT_SELECTOR).not('.copy'); },
  selectedGameDef() { return DynamicSelector.selected(this.GAME_DEF_SELECTOR); },
  filterOptions(bots){
    return DynamicSelector.filterOptions(this.GAME_DEF_SELECTOR, this.OPPONENT_SELECTOR, bots);
  },
  fillSeatSelector(numPlayers, seatSelector){
    // @todo This feels a little hacky; I don't like manipulating
    //   the DOM like this, but it should be all right for now.
    let options = '<option value="">Random</option>';
    for (let i = 1; i <= numPlayers; i++) {
      options += `<option value='${i}'>${i}</option>`;
    }
    return seatSelector.html(options).parent().show();
  },
  copyOpponentSelectors(numPlayers){
    let numExtraOpponents = numPlayers - 2;
    let copiedSelectors = '';
    let copyOpponentSelector = this.OPPONENT_SELECTOR_OBJ().clone().addClass('copy')[0].outerHTML;
    for (let i = 1; i <= numExtraOpponents; i++) {
      copiedSelectors += copyOpponentSelector;
    }
    if (copiedSelectors !== '') { return this.OPPONENT_SELECTOR_OBJ().after(copiedSelectors); }
  },
  showProperNumOfOpponents(seatSelector){
    let numPlayers = parseInt(this.selectedGameDef().data('num_players'));
    this.fillSeatSelector(numPlayers, seatSelector);
    return this.copyOpponentSelectors(numPlayers);
  },
  makeDynamicAccordingToGameDef() {
    let bots = this.OPPONENT_SELECTOR_OBJ().html();
    let seatSelector = $('select#match_seat');
    return $(this.GAME_DEF_SELECTOR).change(() => {
      // Clear old selectors
      $(`${this.OPPONENT_SELECTOR}.copy`).remove();
      // Filter the options of the original selector
      this.filterOptions(bots);
      // Copy the filtered original selector the proper number of times
      return this.showProperNumOfOpponents(seatSelector);
    }
    );
  },
  selectDefaultGameDef() {
    return DynamicSelector.selectDefault(this.GAME_DEF_SELECTOR);
  }
};
export default BotSelection;
