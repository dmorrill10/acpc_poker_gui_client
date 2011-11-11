require File.expand_path('../../../lib/application_defs', __FILE__)

# General controller/view helpers for this application.
module ApplicationHelper   
   NO_RANDOM = false

   # @param [String] button_string
   # @param [String] url
   # @param [String] class_div
   # @param [Hash] options = Hash.new
   def button(button_string, url, class_div, options = Hash.new)
      form_tag url, :id => class_div, :remote => true do
         if !options[:confirm].nil?
            s = submit_tag button_string, :class => class_div, :confirm => options[:confirm]
         else
            s = submit_tag button_string, :class => class_div
         end
         # TODO Fix the naming here
         s << number_field_tag(:port_number) if options[:amount_field]
         s << hidden_field_tag(:match_id, options[:match_id], :id => 'match_id_hidden_field') if options[:match_id]
         s
      end
   end
   
   # Renders a shared +Javascript+ template that replaces the old contents
   # of the current page with new contents.  In essence, it acts like a
   # page refresh.
   # @param [String] replacement_partial The partial with which the page should be replaced.
   def replace_page_contents(replacement_partial)
      @replacement_partial = replacement_partial
      render 'shared_javascripts/replace_contents.js.haml'
   end
   
   # Renders a shared +Javascript+ template that sends parameters to
   # +PlayerActionsController+ so that it can connect to an
   # ACPC dealer instance.
   def send_parameters_to_connect_to_dealer
      render 'shared_javascripts/send_parameters_to_connect_to_dealer.js.haml'
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
         form << hidden_field_tag(:random_seed, nil, :id => 'random_seed_hidden_field')
         form << hidden_field_tag(:player_names, nil, :id => 'player_names_hidden_field')
         
         form << submit_tag('Hidden', :class => 'game_home_hidden_button', :style => 'visibility: hidden')
      end
   end
   
   # @param [Hash] params Parameters from the view.
   # @return [Hash] A hash containing the game parameters.
   def two_player_limit_params(params)
      port_number = params[:port_number] || '18791'
      match_name = params[:match_name] || 'default'
      game_definition_file_name = ApplicationDefs::GAME_DEFINITION_FILE_NAMES[:two_player_limit_texas_holdem_poker]
      number_of_hands = params[:number_of_hands] || '1'
      random_seed = if params[:random_seed] then
         params[:random_seed]
      else
         # @todo not sure what the maximum random seed should be
         if NO_RANDOM then '1' else (rand 100).to_s end
      end
      
      player_names = params[:player_names] || 'user, p2'
      
      {port_number: port_number, match_name: match_name, game_definition_file_name: game_definition_file_name, number_of_hands: number_of_hands, random_seed: random_seed, player_names: player_names}
   end
   
end
