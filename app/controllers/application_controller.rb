require 'acpc_backend'

class ErrorManagerController < ActionController::Base
  protect_from_forgery
  before_filter :log_session

  def self.report_error_request_message
    "please report this incident on the issue tracker, #{ApplicationHelper::ISSUE_TRACKER}"
  end

  def log_session
    Rails.logger.ap session: session, params: params
  end

  protected

  def log_error(e)
    Rails.logger.fatal(
      {
        exception: {
          message: e.message, backtrace: e.backtrace
        }
      }.awesome_inspect
    )
  end

  def error?
    begin
      yield if block_given?
      false
    rescue => e
      log_error e
      true
    end
  end
end

class UserManagerController < ErrorManagerController
  helper_method :user_name, :user, :user_initialized

  protected

  # @return [String] The currently signed in user name. Defaults to +User::DEFAULT_NAME+
  def user_name
    return @user.name if @user
    session[ApplicationHelper::USER_NAME_KEY] || User::DEFAULT_NAME
  end

  def user_name_from_htaccess
    begin
      ActionController::HttpAuthentication::Basic::user_name_and_password(
        request
      ).first
    rescue NoMethodError # Occurs when no authentication has been done
      nil
    end
  end

  def user(user_name_=nil)
    return @user if user_name_.nil? && @user
    @user = User.find_or_create_by name: (user_name_ || user_name)
    session[ApplicationHelper::USER_NAME_KEY] = @user.name
    @user
  end

  def user_initialized?
    begin
      user
      true
    rescue Mongoid::Errors
      false
    end
  end

  def reset_user
    user User::DEFAULT_NAME
  end
end

class MatchManagerController < UserManagerController
  helper_method(
    :match,
    :match_id,
    :user_started_match?,
    :spectating?,
    :matches_to_join,
    :seats_to_join,
    :matches_to_rejoin,
    :seats_to_rejoin,
    :matches_including_user,
    :user_already_in_match?
  )

  protected

  def clear_match_session!
    session.delete AcpcBackend.config.match_id_key
    session['num_requests'] = 0
  end

  def clear_match_information!
    @match = nil
    @match_view = nil
    clear_match_session!
  end

  def match
    @match = if @match_view
      @match_view.match
    elsif @match
      @match
    elsif match_id
      begin
        AcpcBackend::Match.find match_id
      rescue Mongoid::Errors::DocumentNotFound
        clear_match_information!
        AcpcBackend::Match.new
      end
    else
      AcpcBackend::Match.new
    end
  end

  def match_id(new_id=nil)
    if new_id
      session[AcpcBackend.config.match_id_key] = new_id.to_s
    else
      session[AcpcBackend.config.match_id_key]
    end
  end

  def user_started_match?(m)
    user.name == m.user_name
  end

  def spectating?
    !user_started_match?(match)
  end

  def matches_to_join
    AcpcBackend::Match.asc(:name).not_started.select do |m|
      !m.copy? &&
      !m.opponent_seats(user.name).empty?
    end
  end
  def seats_to_join
    matches_to_join.inject({}) do |hash, lcl_match|
      hash[lcl_match.name] = lcl_match.rejoinable_seats(user.name).sort
      hash
    end
  end

  def matches_to_rejoin
    AcpcBackend::Match.asc(:name).started.select do |m|
      m.user_name == user_name &&
      !m.copy? &&
      !m.finished?
    end
  end
  def seats_to_rejoin
    matches_to_rejoin.sort_by{ |m| m.name }.inject({}) do |hash, m|
      hash[m.name] = m.opponent_seats_with_condition { |player| User.where(user_name: player).exists? }
      hash[m.name] << m.seat unless hash[m.name].include?(m.seat)
      hash[m.name].sort!
      hash
    end
  end

  def matches_including_user
    return @matches_including_user_ if @matches_including_user_
    begin
      @matches_including_user_ = AcpcBackend::Match.where(user_name: user_name).reject { |m| m.copy? || m.finished? }
    rescue
      []
    end
  end

  def user_already_in_match?
    !matches_including_user.empty?
  end
end

class ApplicationController < MatchManagerController
  def constants() render(json: my_helper.read_constants) end

  def table_manager_constants
    render(
      json: File.read(AcpcBackend.config.file)
    )
  end

  protected

  def my_helper() ApplicationHelper end

  # Renders a shared +JavaScript+ template that replaces the old contents
  # of the current page with new contents. In essence, it acts like a
  # page refresh.
  # @param [String] replacement_partial The partial with which the page should be replaced.
  # @param [String] alert_message An alert message to be displayed.
  def replace_page_contents(
    replacement_partial: @replacement_partial,
    alert_message: @alert_message,
    html_element: @html_element
  )
    @replacement_partial = replacement_partial || ApplicationHelper::NEW_MATCH_PARTIAL
    @alert_message = alert_message
    @html_element = html_element || app_html_element

    Rails.logger.ap({
      method: __method__,
      replacement_partial: @replacement_partial,
      alert_message: @alert_message,
      html_element: @html_element
    })

    render_js ApplicationHelper::REPLACE_CONTENTS_JS
  end

  def render_js(js_partial)
    if (
      error? do
        respond_to do |format|
          format.js do
            render js_partial, formats: [:js]
          end
        end
      end
    )
      @alert_message ||= "Unable to update the page, #{self.class.report_error_request_message}"
      return replace_page_contents(
        replacement_partial: (
          if @replacement_partial == ApplicationHelper::NEW_MATCH_PARTIAL
            ApplicationHelper::ERROR_PARTIAL
          else
            ApplicationHelper::NEW_MATCH_PARTIAL
          end
        )
      )
    end
  end

  def reset_to_match_entry_view(alert_message=@alert_message)
    render_js ApplicationHelper::RENDER_MATCH_ENTRY_JS
  end

  def clear_nonexistant_match
    if match_id && !AcpcBackend::Match.id_exists?(match_id)
      clear_match_information!
      Rails.logger.ap({method: __method__})
      raise
    end
  end

  def clear_nonessential_session
    clear_match_information!
    session.delete 'match_slice_index'
  end
end
