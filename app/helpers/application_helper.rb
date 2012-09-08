
require 'stalker'
require 'acpc_poker_types'

# General controller/view helpers for this application.
module ApplicationHelper

  MATCH_STATE_TIMEOUT = 10 unless const_defined? :MATCH_STATE_TIMEOUT

  NEW_MATCH_PARTIAL = 'new_game/new' unless const_defined? :NEW_MATCH_PARTIAL
  REPLACE_CONTENTS_JS = 'shared_javascripts/replace_contents.js.haml' unless const_defined? :REPLACE_CONTENTS_JS
  SEND_PARAMETERS_TO_CONNECT_TO_DEALER_JS = 'shared_javascripts/send_parameters_to_connect_to_dealer.js.haml' unless const_defined? :SEND_PARAMETERS_TO_CONNECT_TO_DEALER_JS

  # @todo Is this still used?

  # @param [String] button_string
  # @param [String] url
  # @param [String] class_div
  # @param [Hash] options = Hash.new
  def button(button_string, url, options = Hash.new)
    form_tag url, :remote => true do
      options[:class] = 'button'
      s = if options[:confirm]
        submit_tag button_string, options
      else
        submit_tag button_string, options
      end
      # @todo Use centralized string names rather than local ones
      s << number_field_tag(:amount_field, 1) if options[:amount_field]
      s << hidden_field_tag(:match_id, options[:match_id], :id => 'match_id_hidden_field') if options[:match_id]
      s << hidden_field_tag(:match_slice_index, options[:match_slice_index], id: 'match_slice_index_hidden_field') if options[:match_slice_index]
      s
    end
  end

  # Renders a shared +JavaScript+ template that replaces the old contents
  # of the current page with new contents.  In essence, it acts like a
  # page refresh.
  # @param [String] replacement_partial The partial with which the page should be replaced.
  # @param [String] alert_message An alert message to be displayed.
  def replace_page_contents(replacement_partial, alert_message=nil)
    @alert_message = alert_message
    @replacement_partial = replacement_partial
    render REPLACE_CONTENTS_JS
  end

  # Renders a shared +JavaScript+ template that sends parameters to
  # +PlayerActionsController+ so that it can connect to an
  # ACPC dealer instance.
  def send_parameters_to_connect_to_dealer
    render SEND_PARAMETERS_TO_CONNECT_TO_DEALER_JS
  end

  # Places a hidden form in a view, within which game parameters may be placed that can be
  # submitted to the +PlayerActionsController+.
  def hidden_game_parameter_form
    form_tag game_home_url, :remote => true do
      form = hidden_field_tag(:match_id, nil, :id => 'match_id_hidden_field')
      form << hidden_field_tag(:port_number, nil, :id => 'port_number_hidden_field')
      form << hidden_field_tag(:match_name, nil, :id => 'match_name_hidden_field')
      form << hidden_field_tag(:game_definition_file_name, nil, :id => 'game_definition_file_name_hidden_field')
      form << hidden_field_tag(:number_of_hands, nil, :id => 'number_of_hands_hidden_field')
      form << hidden_field_tag(:seat, nil, id: 'seat_hidden_field')
      form << hidden_field_tag(:random_seed, nil, :id => 'random_seed_hidden_field')
      form << hidden_field_tag(:player_names, nil, :id => 'player_names_hidden_field')
      form << hidden_field_tag(:millisecond_response_timeout, nil, :id => 'millisecond_response_timeout_hidden_field')

      form << submit_tag('Hidden', :id => 'game_home_hidden_button', style: 'visibility: hidden')
    end
  end

  def reset_to_match_entry_view(error_message=nil)
    @match = Match.new
    replace_page_contents NEW_MATCH_PARTIAL, error_message
  end

  # @todo Move to match retrieval module

  def current_match(match_id)
    Match.find match_id
  end

  def time_limit_reached?(start_time)
    Time.now > start_time + MATCH_STATE_TIMEOUT
  end

  def failsafe_while_for_match(match_id, method_for_condition)
    match = current_match match_id
    failsafe_while lambda{ method_for_condition.call(match) } do
      match = current_match match_id
    end
    match
  end

  def failsafe_while(method_for_condition)
    time_beginning_to_wait = Time.now
    while method_for_condition.call
      yield
      raise if time_limit_reached?(time_beginning_to_wait)
    end
  end

  def start_background_job(job_name, arguments, options={ttr: MATCH_STATE_TIMEOUT})
    Stalker.enqueue job_name, arguments, options
  end
end
