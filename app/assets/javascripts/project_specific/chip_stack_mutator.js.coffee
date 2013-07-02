root = exports ? this

root.ChipStackMutator =
  adjustAmountFontSizeOf: (chipStack) ->
    innerRing = $(chipStack).find('.inner_ring')
    amountBox = $(chipStack).find('.amount')
    textSpan = $("<span>").text(amountBox.text()).appendTo("body")
    widthRatio = innerRing.width()/textSpan.width()
    heightRatio = innerRing.height()/textSpan.height()
    smallestRatio = Math.min(heightRatio, widthRatio)

    amountBox.css('font-size', "#{(smallestRatio * 0.8 * parseInt(amountBox.css('font-size')))}px")
    textSpan.remove()
  adjustAmountFontSizeOfAllStacks: ->
    @adjustAmountFontSizeOf chipStack for chipStack in $(".chip_stack")
