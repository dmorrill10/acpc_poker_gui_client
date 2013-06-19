root = exports ? this

root.GameInterface =
  adjustScaleOnce: ->
    elementToScale = $('.game_interface')
    widthRatio = $(window).width() / elementToScale.width()
    heightRatio = ($(window).height() - $('.navbar').height()) / elementToScale.height()

    smallestRatio = Math.min(heightRatio, widthRatio)

    elementToScale.css('transform', 'scale(' + smallestRatio.toString() + ')')

    scaledHeight = elementToScale.height() * smallestRatio

    elementToScale.css({top: -(Math.ceil((elementToScale.height() - scaledHeight) / 2.0) - $('.navbar').height()), left: Math.ceil(($(window).width() - elementToScale.width()) / 2.0)})

    # Inversely scale slider and adjust width manually
    slider = $('.slider')
    inverseScaling = 1 / smallestRatio
    slider.css('transform', 'scaleX(' + inverseScaling.toString() + ')')

    originalSliderWidth = 604 # Hardcoded slider width separate from that set in CSS, not sure how to get around this
    slider.width(originalSliderWidth * smallestRatio)
    slider.css({left: -(Math.ceil((slider.width() - originalSliderWidth) / 2.0))})
  adjustScale: ->
    jQuery(window).resize(->
      GameInterface.adjustScaleOnce()
    )
    @adjustScaleOnce()