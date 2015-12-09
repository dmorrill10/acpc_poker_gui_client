#= require jquery
#= require jquery_ujs
#= require handlebars
#= require ember
#= require ember-data
#= require active-model-adapter
#= require_self
#= require jquery.ui.core
#= require jquery.ui.slider
#= require jquery.ui.widget
#= require jquery.ui.effect
#= require bootstrap-sprockets
#= require js-routes
#= require vendor/jquery.ui.chatbox/jquery.ui.chatbox
#= require vendor/jquery.hotkeys/jquery.hotkeys
#= require vendor/jquery-titlealert/jquery.titlealert
#= require project_specific/timer.js.coffee
#= require project_specific/ajax_communicator.js.coffee
#= require project_specific/counter_queue.js.coffee
#= require project_specific/realtime.js.coffee
#= require project_specific/chat.js.coffee
#= require_tree ./project_specific
#= require acpc_poker_gui_client

# for more details see: http://emberjs.com/guides/application/
window.AcpcPokerGuiClient = Ember.Application.create()

