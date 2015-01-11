require 'application_helper'
require 'match'

# Controller for the 'start a new game' view.
class MatchStartController < ApplicationController
  include ApplicationDefs
  include ApplicationHelper
  include MatchStartHelper

  def sign_in
    if params[:user_name] && !params[:user_name].empty?
      u = user(params[:user_name])

      is_authentic = u.authentic?(params[:password])

      Rails.logger.ap(
        action: __method__,
        user: u.name,
        password: params[:password],
        authentic?: is_authentic
      )

      if !is_authentic
        reset_user
        @alert_message = "Incorrect password for #{params[:user_name]}!"
        return respond_to do |format|
          format.js do
            render ApplicationHelper::RENDER_NOTHING_JS, formats: [:js]
          end
        end
      elsif u.password_hash.nil? && params[:password] && !params[:password].empty?
        # Add password if given
        u.encrypt_password! params[:password]
      end
      u.save
      session[ApplicationHelper::USER_NAME_KEY] = u.name
      return redirect_to root_path
    end
    return reset_to_match_entry_view
  end

  # Presents the main 'start a new game' view.
  def index
    begin
      TableManager::Worker.perform_async(
        TableManager::DELETE_IRRELEVANT_MATCHES_REQUEST_CODE
      )
      clear_nonessential_session
    rescue # Quiet any errors
    end

    unless user_initialized?
      @alert_message = "Unable to set default hotkeys for #{user.name}, #{self.class.report_error_request_message}"
    end

    @alert_message = params['alert_message'] if params['alert_message'] && !params['alert_message'].empty?

    Rails.logger.ap(
      action: __method__,
      alert_message: @alert_message
    )

    respond_to do |format|
      format.html {} # Render the default partial
      format.js do
        replace_page_contents replacement_partial: ApplicationHelper::NEW_MATCH_PARTIAL
      end
    end
  end

  def new
    return render_js(RENDER_NOTHING_JS) if user.name == User::DEFAULT_NAME

    seed = Match.new_random_seed
    seat = Match.new_random_seat(2)
    match_name = Match.new_name user_name

    params[:match] = {
      opponent_names: [ApplicationHelper::EXHIBITION_BOT_NAME],
      name_from_user: match_name,
      game_definition_key: :two_player_limit,
      number_of_hands: ApplicationHelper::NUM_HANDS_PER_MATCH,
      seat: seat,
      random_seed: seed,
      user_name: user_name
    }

    return reset_to_match_entry_view(
      'Sorry, unable to finish creating a match instance, please try again.'
    ) if (
      error? do
        @match = Match.new(params[:match]).finish_starting!

        Rails.logger.ap(
          action: __method__,
          user: user_name,
          match_id: @match.id,
          match_user_name: @match.user_name
        )

        match_id(@match.id)

        @enque_match = true

        return update_match_queue
      end
    )
    return update_match_queue
  end

  def join
    match_name = params[:match_name].strip
    seat = params[:seat].to_i

    return reset_to_match_entry_view(
      "Sorry, unable to join match \"#{match_name}\" in seat #{seat}."
    ) if (
      error? do
        opponent_users_match = Match.where(name_from_user: match_name).first
        raise unless opponent_users_match

        @match = opponent_users_match.copy_for_next_human_player user.name, seat

        match_id(@match.id)

        wait_for_match_to_start TableManager::START_PROXY_REQUEST_CODE
      end
    )
  end

  def rejoin
    match_name = params[:match_name].strip
    seat = params[:seat].to_i

    return reset_to_match_entry_view(
      "Sorry, unable to find match \"#{match_name}\" in seat #{seat}."
    ) if (
      error? do
        @match = Match.where(name: match_name, seat: seat).first
        raise unless @match

        match_id(@match.id)

        wait_for_match_to_start
      end
    )
  end

  def start_dealer_and_players
    return reset_to_match_entry_view(
      'Sorry, unable to start the dealer and players, please try again or join a match already in progress.'
    ) if (
      error? do
        self.class().start_dealer_and_players_on_server match_id
      end
    )
    render nothing: true
  end

  def start_proxy_only
    return reset_to_match_entry_view(
      'Sorry, unable to start the dealer and players, please try again or join a match already in progress.'
    ) if (
      error? do
        TableManager::Worker.perform_async(
          TableManager::START_PROXY_REQUEST_CODE,
          TableManager::MATCH_ID_KEY => match_id
        )
      end
    )
    render nothing: true
  end

  def update_match_queue
    replace_page_contents(
      html_element: '.match_start',
      replacement_partial: 'new_exhibition_match'
    )
  end

  def enqueue_exhibition_match
    return render_js(RENDER_NOTHING_JS) if user.name == User::DEFAULT_NAME
    return reset_to_match_entry_view(
      'Sorry, unable to enqueue match, please try again.'
    ) if (
      error? do
        Rails.logger.ap(
          action: __method__,
          session: session
        )
        clear_nonexistant_match
        self.class().start_dealer_and_players_on_server match_id
        return update_match_queue
      end
    )
    return update_match_queue
  end

  protected

  def my_helper() MatchStartHelper end

  def wait_for_match_to_start(request_code=@request_code)
    @request_code = request_code
    respond_to do |format|
      format.js do
        replace_page_contents(
          replacement_partial: my_helper::WAIT_FOR_MATCH_TO_START_PARTIAL
        )
      end
    end
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

  def num_players(game_def_key)
    ApplicationDefs.game_definitions[game_def_key][:num_players]
  end

  def self.start_dealer_and_players_on_server(match_id_)
    Rails.logger.ap(
      action: __method__,
      match_id: match_id_
    )
    TableManager::Worker.perform_async(
      TableManager::START_MATCH_REQUEST_CODE,
      {
        TableManager::MATCH_ID_KEY => match_id_,
        TableManager::OPTIONS_KEY => [
          '-a', # Append logs with the same name rather than overwrite
          "--t_response #{MatchStartHelper::DEALER_MILLISECOND_TIMEOUT}",
          '--t_hand -1',
          '--t_per_hand -1'
        ].join(' ')
      }
    )
  end
end
