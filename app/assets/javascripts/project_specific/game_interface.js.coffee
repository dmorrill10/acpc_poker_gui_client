root = exports ? this

root.GameInterface =
  # @todo Adding an optional extra left offset is a complete hack but I can't figure out
  #   why it's too far to the left when initially being adjusted.
  adjustScaleOnce: (extraLeftOffset = 0)->
    elementToScale = $('.game_interface')
    widthRatio = $(window).width() / elementToScale.width()
    heightRatio = ($(window).height() - $('.navbar').height()) / elementToScale.height()

    smallestRatio = Math.min(heightRatio, widthRatio)

    elementToScale.css('-moz-transform', 'scale(' + smallestRatio.toString() + ')')
    elementToScale.css('-webkit-transform', 'scale(' + smallestRatio.toString() + ')')
    elementToScale.css('-ms-transform', 'scale(' + smallestRatio.toString() + ')')
    elementToScale.css('-o-transform', 'scale(' + smallestRatio.toString() + ')')

    scaledHeight = elementToScale.height() * smallestRatio

    elementToScale.css({top: -(Math.ceil((elementToScale.height() - scaledHeight) / 2.0) - $('.navbar').height()), left: Math.ceil(($(window).width() - elementToScale.width()) / 2.0) + extraLeftOffset})

    # Inversely scale slider and adjust width manually
    slider = $('.slider')
    inverseScaling = 1 / smallestRatio
    slider.css('-moz-transform', 'scaleX(' + inverseScaling.toString() + ')')
    slider.css('-webkit-transform', 'scaleX(' + inverseScaling.toString() + ')')
    slider.css('-ms-transform', 'scaleX(' + inverseScaling.toString() + ')')
    slider.css('-o-transform', 'scaleX(' + inverseScaling.toString() + ')')

    originalSliderWidth = 604 # Hardcoded slider width separate from that set in CSS, not sure how to get around this
    slider.width(originalSliderWidth * smallestRatio)
    slider.css({left: -(Math.ceil((slider.width() - originalSliderWidth) / 2.0))})
  adjustScale: ->
    jQuery(window).resize(->
      GameInterface.adjustScaleOnce()
    )
    @adjustScaleOnce(7)