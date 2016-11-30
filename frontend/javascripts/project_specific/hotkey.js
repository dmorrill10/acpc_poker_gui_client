let Hotkey = {
  bind(elementToClick, key) {
    console.log(`Hotkey::bind: elementToClick: ${elementToClick}, key: ${key}`);
    let eventName = `keypress.action-${elementToClick}`;
    return this.bindToDocumentAndWagerAmountField(
      key,
      eventName,
      evt=> {
        if ($(elementToClick).is(':disabled')) { return; }
        return $(elementToClick).click();
      }
    );
  },
  bindToDocumentAndWagerAmountField(key, eventName, callback){
    this.bindTo(key, eventName, document, callback);
    return this.bindTo(key, eventName, wagerAmountField(), callback);
  },
  bindTo(key, eventName, elementToWhichToBind, callback){
    if (
      WindowManager.isBlank(key) ||
      WindowManager.isBlank(eventName) ||
      WindowManager.isBlank(elementToWhichToBind)
    ) { return; }
    return $(elementToWhichToBind).off(`${eventName}`).on(`${eventName}`, null, key, callback);
  },
  bindWager(fraction, amountToWager, key){
    return this.bindToDocumentAndWagerAmountField(
      key,
      `keypress.action-${fraction}`,
      evt=> {
        wagerAmountField().val(amountToWager);
        if (!wagerSubmission().is(':disabled')) {
          return wagerSubmission().click();
        }
      }
    );
  }
};
export default Hotkey;
