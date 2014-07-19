require 'acpc_poker_types'

# General controller/view helpers for this application.
module ApplicationHelper

  # Renders a shared +JavaScript+ template that replaces the old contents
  # of the current page with new contents. In essence, it acts like a
  # page refresh.
  # @param [String] replacement_partial The partial with which the page should be replaced.
  # @param [String] alert_message An alert message to be displayed.
  def replace_page_contents(
    replacement_partial,
    alert_message=@alert_message,
    html_element="#{ApplicationDefs::HTML_CLASS_PREFIX}#{ApplicationDefs::APP_VIEW_HTML_CLASS}"
  )
    @alert_message = alert_message
    @html_element = html_element

    Rails.logger.fatal({
      method: __method__,
      alert_message: @alert_message,
      html_element: @html_element
    }.awesome_inspect)

    @replacement_partial = replacement_partial
    if (
      error? do
        respond_to do |format|
          format.js do
            render ApplicationDefs::REPLACE_CONTENTS_JS, formats: [:js]
          end
        end
      end
    )
      @alert_message ||= "Unable to update the page, #{self.class.report_error_request_message}"
      if replacement_partial == ApplicationDefs::NEW_MATCH_PARTIAL
        return(redirect_to(root_path, remote: true))
      else
        return reset_to_match_entry_view
      end
    end
  end

  def reset_to_match_entry_view(error_message=@alert_message)
    replace_page_contents ApplicationDefs::NEW_MATCH_PARTIAL, error_message
  end

  def link_with_glyph(link_text, link_target, glyph, options={})
    link_to link_target, options do
      inserted_html = "#{content_tag(:i, nil, class: 'icon-' << glyph)} #{link_text}".html_safe
      inserted_html << yield if block_given?
      inserted_html
    end
  end

  def log_error(e)
    Rails.logger.fatal({exception: {message: e.message, backtrace: e.backtrace}}.awesome_inspect)
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

  def user_initialized?
    begin
      user
      true
    rescue Mongoid::Errors
      false
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
      users.shift
    end
  end
  # @return [String] The currently signed in user name. Defaults to +User.default_user_name+
  def user_name
    name = begin
      ActionController::HttpAuthentication::Basic::user_name_and_password(request).first
    rescue NoMethodError # Occurs when no authentication has been done
      User::DEFAULT_NAME
    end
  end
  def help_link
    link_with_glyph(
      '',
      ApplicationDefs::HELP_LINK,
      'question-sign',
      {
        class: ApplicationDefs::HELP_LINK_HTML_CLASS,
        # `target: blank` option ensures that this link will be opened in a new tab
        target: 'blank',
        title: 'Help',
        data: { toggle: 'tooltip' }
      }
    )
  end
  def match
    if @match_view
      @match_view.match
    else
      @match ||= Match.new
    end
  end
end