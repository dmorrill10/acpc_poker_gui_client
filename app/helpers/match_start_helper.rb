module MatchStartHelper
  def hidden_match_name() 'hidden_name' end
  def hidden_game_def_file_name() 'hidden_game_def_file_name' end
  def hidden_num_hands() 'hidden_num_hands' end
  def hidden_seat() 'hidden_seat' end
  def hidden_rand_seed() 'hidden_rand_seed' end
  def hidden_submit() 'hidden_submit' end
  def hidden_start_opponents() 'hidden_start_opponents' end
  def hidden_start_match() 'hidden-start_match' end

  # Renders a +JavaScript+ template that sends parameters to
  # +PlayerActionsController+ so that it can connect to an
  # ACPC dealer instance.
  def send_parameters_to_connect_to_dealer
    render 'match_start/send_parameters_to_connect_to_dealer'
  end

  # Hidden form, within which game parameters may be placed that can be
  # submitted to the +PlayerActionsController+.
  def hidden_begin_match_form
    form_tag match_home_url, :remote => true do
      form = submit_tag(
        '',
        class: ApplicationDefs::HIDDEN_UPDATE_MATCH_HTML_CLASS,
        style: 'visibility: hidden'
      )
    end
  end

  # @todo Make this pure JS form?
  def hidden_start_match_form
    form_tag start_match_url, :remote => true do
      form = submit_tag(
        '',
        id: hidden_start_match,
        style: 'visibility: hidden'
      )
    end
  end

  def label_for_required(label)
    "<abbr title='required'>*</abbr> #{label}".html_safe
  end

  def num_players(game_def_key)
    ApplicationDefs.game_definitions[game_def_key][:num_players]
  end

  def truncate_opponent_names_if_necessary(match_params)
    while (
      match_params[:opponent_names].length >
      num_players(match_params[:game_definition_key].to_sym) - 1
    )
      match_params[:opponent_names].pop
    end
    match_params[:opponent_names]
  end

  def wait_for_match_to_start
    respond_to do |format|
      format.js do
        replace_page_contents ApplicationDefs::WAIT_FOR_MATCH_TO_START_PARTIAL
      end
    end
  end

  def matches_to_join
    @matches_to_join ||= Match.asc(:name).all.select do |m|
      !m.name_from_user.match(/^_+$/) &&
      m.slices.empty? &&
      !m.human_opponent_seats(user.name).empty?
    end
  end
  def seats_to_join
    matches_to_join.inject({}) do |hash, lcl_match|
      hash[lcl_match.name] = lcl_match.rejoinable_seats(user.name).sort
      hash
    end
  end

  def matches_to_rejoin
    @matches_to_rejoin ||= Match.asc(:name).all.select do |m|
      m.user_name == user_name &&
      !m.name_from_user.match(/^_+$/) &&
      !m.finished? &&
      !m.slices.empty?
    end
  end
  def seats_to_rejoin
    matches_to_rejoin.sort_by{ |m| m.name }.inject({}) do |hash, lcl_match|
      hash[lcl_match.name] = lcl_match.human_opponent_seats
      hash[lcl_match.name] << lcl_match.seat unless hash[lcl_match.name].include?(lcl_match.seat)
      hash[lcl_match.name].sort!
      hash
    end
  end
end