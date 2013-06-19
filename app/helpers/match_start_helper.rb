module MatchStartHelper
  def hidden_match_id() 'hidden_id' end
  def hidden_match_name() 'hidden_name' end
  def hidden_game_def_file_name() 'hidden_game_def_file_name' end
  def hidden_num_hands() 'hidden_num_hands' end
  def hidden_seat() 'hidden_seat' end
  def hidden_rand_seed() 'hidden_rand_seed' end
  def hidden_submit() 'hidden_submit' end
  def hidden_start_opponents() 'hidden_start_opponents' end
  def hidden_begin_match() 'hidden-begin_match' end

  # Renders a +JavaScript+ template that sends parameters to
  # +PlayerActionsController+ so that it can connect to an
  # ACPC dealer instance.
  def send_parameters_to_connect_to_dealer
    render 'match_start/send_parameters_to_connect_to_dealer'
  end

  # Hidden form, within which game parameters may be placed that can be
  # submitted to the +PlayerActionsController+.
  def hidden_begin_match_form(match_id)
    form_tag match_home_url, :remote => true do
      form = hidden_field_tag(:match_id, match_id, :id => hidden_match_id)

      form << submit_tag('', :id => hidden_begin_match, style: 'visibility: hidden')
    end
  end

  def label_for_required(label)
    "<abbr title='required'>*</abbr> #{label}".html_safe
  end
end