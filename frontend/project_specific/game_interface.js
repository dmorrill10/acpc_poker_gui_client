let GameInterface = {
  aboveTableHeight() { return $('nav').height() + $('.banner-container').height(); },
  adjustPositionAfterScaling(scaledElement, scaling, topOffset, containingElement){
    let scaledHeight = scaledElement.height() * scaling;
    return scaledElement.css({top: -(Math.floor((scaledElement.height() - scaledHeight) / 2.0) - topOffset), left: Math.floor((containingElement.width() - scaledElement.width()) / 2.0)});
  },
  adjustScaleOnceOfGameInterface() {
    let smallestRatio = this.adjustScaleOnceOfElement($('.game_interface'));

    // Inversely scale slider and adjust width manually
    let slider = $('.slider');
    let inverseScaling = 1 / smallestRatio;
    slider.css('transform', `scaleX(${inverseScaling.toString()})`);

    let originalSliderWidth = 604; // Hardcoded slider width separate from that set in CSS, not sure how to get around this
    slider.width(originalSliderWidth * smallestRatio);
    return slider.css({left: -(Math.floor((slider.width() - originalSliderWidth) / 2.0))});
  },
  adjustScaleOnce() {
    return this.adjustScaleOnceOfGameInterface();
  },
  adjustScaleOnceOfElement(elementToScale){
    let windowBuffer = 1;
    let widthRatio = ($(window).width() - windowBuffer) / elementToScale.width();
    let heightRatio = ($(window).height() - windowBuffer - this.aboveTableHeight()) / elementToScale.height();

    let smallestRatio = Math.min(heightRatio, widthRatio);

    elementToScale.css('transform', `scale(${smallestRatio.toString()})`);

    this.adjustPositionAfterScaling(elementToScale, smallestRatio, this.aboveTableHeight(), $(window));
    return smallestRatio;
  },
  adjustScale() {
    $(window).resize(() => this.adjustScaleOnce());
    this.adjustScaleOnce();
    return this.adjustScaleOnce(); // Ensures that the table fits properly into the window
  }
};
export default GameInterface;
