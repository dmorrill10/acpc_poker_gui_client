module MatchStartHelper
  def hidden_match_id() 'hidden_id' end
  def hidden_match_name() 'hidden_name' end
  def hidden_game_def_file_name() 'hidden_game_def_file_name' end
  def hidden_num_hands() 'hidden_num_hands' end
  def hidden_seat() 'hidden_seat' end
  def hidden_rand_seed() 'hidden_rand_seed' end
  def hidden_submit() 'hidden_submit' end
  def hidden_start_opponents() 'hidden_start_opponents' end
  def hidden_begin_match() 'hidden_begin_match' end

  # Renders a +JavaScript+ template that sends parameters to
  # +PlayerActionsController+ so that it can connect to an
  # ACPC dealer instance.
  def send_parameters_to_connect_to_dealer
    render 'match_start/send_parameters_to_connect_to_dealer'
  end

  # Places a hidden form in a view, within which game parameters may be placed that can be
  # submitted to the +PlayerActionsController+.
  def hidden_game_parameter_form
    form_tag match_home_url, :remote => true do
      form = hidden_field_tag(:match_id, nil, :id => hidden_match_id)
      form << hidden_field_tag(:match_name, nil, :id => hidden_match_name)
      form << hidden_field_tag(:game_definition_file_name, nil, :id => hidden_game_def_file_name)
      form << hidden_field_tag(:number_of_hands, nil, :id => hidden_num_hands)
      form << hidden_field_tag(:seat, nil, id: hidden_seat)
      form << hidden_field_tag(:random_seed, nil, :id => hidden_rand_seed)

      form << submit_tag('', :id => hidden_submit, style: 'visibility: hidden')
    end
  end

  def hidden_start_opponents_form(match_id)
    form_tag start_opponents_url, :remote => true do
      form = hidden_field_tag(:match_id, match_id, :id => hidden_match_id)

      form << submit_tag('', :id => hidden_start_opponents, style: 'visibility: hidden')
    end
  end

  def hidden_begin_match_form(match_id)
    form_tag begin_match_url, :remote => true do
      form = hidden_field_tag(:match_id, match_id, :id => hidden_match_id)

      form << submit_tag('', :id => hidden_begin_match, style: 'visibility: hidden')
    end
  end
end
