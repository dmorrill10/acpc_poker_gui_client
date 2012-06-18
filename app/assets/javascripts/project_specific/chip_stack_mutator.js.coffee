root = exports ? this

root.ChipStackMutator =
   
   adjustAmountFontSizeOf: (chipStack) ->
      
      innerRing = jQuery(chipStack).find('.inner_ring')
      
      amountBox = jQuery(chipStack).find('.amount')
      amountBoxWidth = amountBox.width()
      amountText = jQuery(amountBox).text()
      
      # Find out the best font size to comfortably fit the number of
      #  characters in the amount text inside the innerRing
      
      numberOfPixelsForEachCharacter = innerRing.width()/amountText.length
      
      # This assumes that the font being used in +amountBox+ is taller
      #  than it is wide, and font width increases slower than font
      #  height as font size increases.The magic constants were found through
      #  trial and error.
      underestimateOfIdealFontSize = Math.floor(2 * Math.ceil(Math.pow(numberOfPixelsForEachCharacter, 1/1.35)))
      
      # @todo The text will still overflow if the number of
      #  characters to display is greater than the number of pixels in the
      #  amount box. This should be handled somewhat in CSS, but there might
      #  be something more elegant that could be done here. This should also
      #  never happen during usual operation.
      
      amountBox.css 'font-size', underestimateOfIdealFontSize.toString() + 'px'
      
   adjustAmountFontSizeOfAllStacks: ->      
      chipStacks = jQuery ".chip_stack"
      @adjustAmountFontSizeOf chipStack for chipStack in chipStacks
