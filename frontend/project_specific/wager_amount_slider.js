export const WagerAmountSlider = {
   initialize(sliderValues) {
      return $('.ui_slider').slider({
         range: 'min',
         min: 0,
         max: sliderValues.length - 1,
         value: 0,
         step: 1,
         slide(event, ui) {
            return $('.wager_amount-num_field > input#modifier').val(sliderValues[ui.value]);}
      });
    }
 };
