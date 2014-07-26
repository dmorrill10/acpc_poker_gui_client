require_relative '../../lib/application_defs'

class ApplicationController < ActionController::Base
  protect_from_forgery
  helper :layout

  before_filter :log_session

  def self.report_error_request_message
    "please report this incident on the issue tracker, #{ApplicationDefs::ISSUE_TRACKER}"
  end

  def log_session
    Rails.logger.ap session: session
  end
end
