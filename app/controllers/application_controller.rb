require_relative '../../lib/application_defs'
require_relative '../workers/table_manager'

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
    name = begin
      ActionController::HttpAuthentication::Basic::user_name_and_password(
        request
      ).first
    rescue NoMethodError # Occurs when no authentication has been done
      User::DEFAULT_NAME
    end
  end

  def user
    return @user if @user
    users = User.where name: user_name
    @user = if users.empty?
      u = User.new name: user_name
      u.save!
      u.reset_hotkeys!
      u
    else
      @user = users.shift
    end
  end

  def user_initialized?
    begin
      user
      true
    rescue Mongoid::Errors
      false
    end
  end
end

class MatchManagerController < UserManagerController
  helper_method :match, :match_id, :match_slice_index, :user_started_match?, :spectating?

  protected

  def match
    if @match_view
      @match_view.match
    else
      @match ||= Match.new
    end
  end

  def match_id(new_id=nil)
    if new_id
      session[TableManager::MATCH_ID_KEY] = new_id.to_s
    else
      session[TableManager::MATCH_ID_KEY]
    end
  end

  def match_slice_index(new_index=nil)
    if new_index
      session[ApplicationHelper::MATCH_SLICE_SESSION_KEY] = new_index.to_i
    else
      session[ApplicationHelper::MATCH_SLICE_SESSION_KEY]
    end
  end

  def user_started_match?(m)
    user.name == m.user_name
  end

  def spectating?
    !user_started_match?(match)
  end
end

class ApplicationController < MatchManagerController
  def constants() render(json: my_helper.read_constants) end

  def table_manager_constants
    render(
      json: File.read(TableManager::CONSTANTS_FILE)
    )
  end

  def realtime_constants
    render(
      json: File.read(Rails.root.join('realtime', 'realtime.json'))
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

    Rails.logger.fatal({
      method: __method__,
      replacement_partial: @replacement_partial,
      alert_message: @alert_message,
      html_element: @html_element
    }.awesome_inspect)

    if (
      error? do
        respond_to do |format|
          format.js do
            render ApplicationHelper::REPLACE_CONTENTS_JS, formats: [:js]
          end
        end
      end
    )
      @alert_message ||= "Unable to update the page, #{self.class.report_error_request_message}"
      if replacement_partial == ApplicationHelper::NEW_MATCH_PARTIAL
        return(redirect_to(root_path, remote: true))
      else
        return reset_to_match_entry_view
      end
    end
  end

  def reset_to_match_entry_view(alert_message=@alert_message)
    replace_page_contents(
      replacement_partial: ApplicationHelper::NEW_MATCH_PARTIAL,
      alert_message: alert_message,
      html_element: app_html_element
    )
  end
end
