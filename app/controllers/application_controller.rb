require_relative '../../lib/application_defs'

class ApplicationController < ActionController::Base
  protect_from_forgery
  helper :layout

  def self.issue_tracker
    'https://github.com/dmorrill10/acpc_poker_gui_client/issues?state=open'
  end
  def self.report_error_request_message
    "please report this incident on the issue tracker, #{issue_tracker}"
  end
  def self.help_link_html_class() 'help_link' end
end
