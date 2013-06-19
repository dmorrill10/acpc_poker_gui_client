root = exports ? this

root.GameInterface =
  adjustPositionAfterScaling: (scaledElement, scaling, topOffset, containingElement)->
    scaledHeight = scaledElement.height() * scaling
    scaledElement.css({top: -(Math.floor((scaledElement.height() - scaledHeight) / 2.0) - topOffset), left: Math.floor((containingElement.width() - scaledElement.width()) / 2.0)})
  adjustScaleOnce: ->
    elementToScale = $('.game_interface')
    windowBuffer = 1
    widthRatio = ($(window).width() - windowBuffer) / elementToScale.width()
    heightRatio = ($(window).height() - windowBuffer - $('.navbar').height()) / elementToScale.height()

    smallestRatio = Math.min(heightRatio, widthRatio)

    elementToScale.css('transform', 'scale(' + smallestRatio.toString() + ')')

    @adjustPositionAfterScaling(elementToScale, smallestRatio, $('.navbar').height(), $(window))

    # Inversely scale slider and adjust width manually
    slider = $('.slider')
    inverseScaling = 1 / smallestRatio
    slider.css('transform', 'scaleX(' + inverseScaling.toString() + ')')

    originalSliderWidth = 604 # Hardcoded slider width separate from that set in CSS, not sure how to get around this
    slider.width(originalSliderWidth * smallestRatio)
    slider.css({left: -(Math.floor((slider.width() - originalSliderWidth) / 2.0))})
  adjustScale: ->
    $(window).resize(=> @adjustScaleOnce())
    @adjustScaleOnce()
    @adjustScaleOnce() # Ensures that the table fits properly into the window