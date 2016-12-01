let ChipStackMutator = {
  adjustAmountFontSizeOf(chipStack) {
    let innerRing = $(chipStack);
    let amountBox = $(chipStack).find('.amount');
    let textSpan = $("<span>").text(amountBox.text()).appendTo("body");
    let widthRatio = innerRing.width()/textSpan.width();
    let heightRatio = innerRing.height()/textSpan.height();
    let smallestRatio = Math.min(heightRatio, widthRatio);

    amountBox.css('font-size', `${(smallestRatio * 0.8 * parseInt(amountBox.css('font-size')))}px`);
    return textSpan.remove();
  },
  adjustAmountFontSizeOfAllStacks() {
    return $(".chip_stack").map((chipStack) => this.adjustAmountFontSizeOf(chipStack));
  }
};
export default ChipStackMutator;
