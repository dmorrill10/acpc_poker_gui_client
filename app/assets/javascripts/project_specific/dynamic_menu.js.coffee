
root = exports ? this

root.DynamicMenu =
   
   initialize: ->
      jQuery(document).ready(->
         $(".dynamic_menu .title").click(->
            $(this).next().toggle('fast')
            return false;
         ).next().hide()
      )
