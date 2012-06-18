root = exports ? this

root.WagerAmountSlider =
   
   initialize: (slider_value_map) ->
      $('.ui_slider').slider({
         range: 'min',
         min: 1,
         max: Object.keys(slider_value_map).length,
         value: 1,
         step: 1,
         slide: ((event, ui) ->
            $('input#user_poker_action_modifier').val(slider_value_map[ui.value])
         )
      })
