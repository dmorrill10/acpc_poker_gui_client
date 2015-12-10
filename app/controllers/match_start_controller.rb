require 'application_helper'
require 'acpc_table_manager'

# Controller for the 'start a new game' view.
class MatchStartController < ApplicationController
  include ApplicationHelper
  include MatchStartHelper

  def sign_in
    if params[:user_name] && !params[:user_name].empty?
      AcpcTableManager.exhibition_config.games.map do |key, info|
        info['opponents'].keys
      end.flatten.uniq.each do |bot_name|
        if bot_name == params[:user_name]
          @alert_message = "Sorry, \"#{bot_name}\" is a reserved name. Please choose another user name."
          begin
            User.find_by(name: bot_name).delete
          rescue Mongoid::Errors::DocumentNotFound
          end
          return respond_to do |format|
            format.js do
              render ApplicationHelper::RENDER_NOTHING_JS, formats: [:js]
            end
          end
        end
      end

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
      clear_nonessential_session
    rescue # Quiet any errors
    end

    AcpcTableManager.exhibition_config.games.map do |key, info|
      info['opponents'].keys
    end.flatten.uniq.each do |bot_name|
      if bot_name == user_name
        @alert_message = "Sorry, \"#{bot_name}\" is a reserved name. Please choose another user name."
        session[ApplicationHelper::USER_NAME_KEY] = User::DEFAULT_NAME
        begin
          User.find_by(name: bot_name).delete
        rescue Mongoid::Errors::DocumentNotFound
        end
      end
    end

    unless user_initialized?
      @alert_message = "Unable to set default hotkeys for #{user.name}, #{self.class.report_error_request_message}"
    end

    @alert_message = params['alert_message'] if params['alert_message'] && !params['alert_message'].empty?

    if user_already_in_match?
      match_ = matches_including_user.first
      if !match_.running? && match_.started?
        begin
          match_.delete
        rescue => e
          Rails.logger.ap(
            action: __method__,
            match_id: match_.id,
            exception_trying_to_delete_dead_match: e.message
          )
          clear_match_session!
        end
      end
    end

    respond_to do |format|
      format.html {} # Render the default partial
      format.js do
        replace_page_contents replacement_partial: ApplicationHelper::NEW_MATCH_PARTIAL
      end
    end
  end

  def new
    return render_js(RENDER_NOTHING_JS) if user.name == User::DEFAULT_NAME

    exhibition_game_def_key = params['game_definition_key']
    return render_js(RENDER_NOTHING_JS) unless exhibition_game_def_key && ApplicationHelper::GAMES[exhibition_game_def_key]

    seed = AcpcTableManager::Match.new_random_seed
    seat = AcpcTableManager::Match.new_random_seat(ApplicationHelper::GAMES[exhibition_game_def_key]['opponents'].length)
    match_name = AcpcTableManager::Match.new_name user_name

    params[:match] = {
      opponent_names: ApplicationHelper::GAMES[exhibition_game_def_key]['opponents'].keys,
      name_from_user: match_name,
      game_definition_key: exhibition_game_def_key.to_sym,
      number_of_hands: ApplicationHelper::GAMES[exhibition_game_def_key]['num_hands_per_match'],
      seat: seat,
      random_seed: seed,
      user_name: user_name
    }

    return reset_to_match_entry_view(
      'Sorry, unable to finish creating a match instance, please try again.'
    ) if (
      error? do
        @match = AcpcTableManager::Match.new(params[:match]).finish_starting!

        Rails.logger.ap(
          action: __method__,
          user: user_name,
          match_id: @match.id,
          match_user_name: @match.user_name
        )

        match_id(@match.id)

        return enqueue_exhibition_match
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
        opponent_users_match = AcpcTableManager::Match.where(name_from_user: match_name).first
        raise unless opponent_users_match

        @match = opponent_users_match.copy_for_next_human_player user.name, seat

        match_id(@match.id)

        wait_for_match_to_start AcpcTableManager.config.start_proxy_request_code
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
        @match = AcpcTableManager::Match.where(name: match_name, seat: seat).first
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
        $redis.rpush(
          'table-manager',
          {
            'request' => AcpcTableManager.config.start_proxy_request_code,
            'params' => {
              AcpcTableManager.config.match_id_key => match_id
            }
          }.to_json
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
    AcpcTableManager.exhibition_config.games[game_def_key.to_s]['num_players']
  end

  def self.start_dealer_and_players_on_server(match_id_)
    Rails.logger.ap(
      action: __method__,
      match_id: match_id_
    )
    $redis.rpush(
      'table-manager',
      {
        'request' => AcpcTableManager.config.start_match_request_code,
        'params' => {
          AcpcTableManager.config.match_id_key => match_id_,
          AcpcTableManager.config.options_key => [
            '-a', # Append logs with the same name rather than overwrite
            "--t_response #{MatchStartHelper::DEALER_MILLISECOND_TIMEOUT}",
            '--t_hand -1',
            '--t_per_hand -1'
          ].join(' ')
        }
      }.to_json
    )
  end
end
