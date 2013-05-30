root = exports ? this

root.GameInterface =
  adjustScaleOnce: ->
    elementToScale = $('.game_interface')
    widthRatio = $(window).width() / elementToScale.width()
    heightRatio = ($(window).height() - $('.navbar').height()) / elementToScale.height()

    smallestRatio = Math.min(heightRatio, widthRatio)

    elementToScale.css('-moz-transform', 'scale(' + smallestRatio.toString() + ')')
    elementToScale.css('-webkit-transform', 'scale(' + smallestRatio.toString() + ')')
    elementToScale.css('-ms-transform', 'scale(' + smallestRatio.toString() + ')')
    elementToScale.css('-o-transform', 'scale(' + smallestRatio.toString() + ')')

    scaledHeight = elementToScale.height() * smallestRatio

    elementToScale.css({top: -(Math.ceil((elementToScale.height() - scaledHeight) / 2) - $('.navbar').height()), left: Math.floor(($(window).width() - elementToScale.width()) / 2)})

    # Inversely scale slider and adjust width manually
    slider = $('.slider')
    inverseScaling = 1 / smallestRatio
    slider.css('-moz-transform', 'scaleX(' + inverseScaling.toString() + ')')
    slider.css('-webkit-transform', 'scaleX(' + inverseScaling.toString() + ')')
    slider.css('-ms-transform', 'scaleX(' + inverseScaling.toString() + ')')
    slider.css('-o-transform', 'scaleX(' + inverseScaling.toString() + ')')

    originalSliderWidth = 604 # Hardcoded slider width separate from that set in CSS, not sure how to get around this
    slider.width(originalSliderWidth * smallestRatio)
    slider.css({left: -(Math.floor((slider.width() - originalSliderWidth) / 2))})
  adjustScale: ->
    @adjustScaleOnce()
    jQuery(window).resize(->
      GameInterface.adjustScaleOnce()
    )