// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.slider
//= require bootstrap-sprockets
//= require rails.validations
//= require rails.validations.simple_form
//= require js-routes
//= require project_specific/ajax_communicator.js.coffee
//= require project_specific/counter_queue.js.coffee
//= require project_specific/match_window.js.coffee
//= require project_specific/realtime.js.coffee
//= require_tree .

function isBlank(str) {
  return (!str || /^[\"\'\s]*$/.test(str));
};
