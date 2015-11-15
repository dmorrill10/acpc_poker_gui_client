require 'acpc_poker_types'
require 'json'

# General controller/view helpers for this application.
module ApplicationHelper
  def self.read_constants
    File.read(
      Rails.root.join('app', 'constants', 'application.json')
    )
  end

  JSON.parse(read_constants).each do |constant, val|
    ApplicationHelper.const_set(constant.upcase, val) unless const_defined? constant.upcase
  end

  JSON.parse(
    File.read(
      Rails.root.join('app', 'constants', 'exhibition.json')
    )
  ).each do |constant, val|
    ApplicationHelper.const_set(constant.upcase, val) unless const_defined? constant.upcase
  end

  def html_element_name_to_class(element)
    "#{HTML_CLASS_PREFIX}#{element}"
  end

  def app_html_element
    html_element_name_to_class(APP_VIEW_HTML_CLASS)
  end

  def link_with_glyph(link_text, link_target, glyph, options={})
    link_to link_target, options do
      inserted_html = "#{content_tag(:i, nil, class: ['glyphicon', 'glyphicon-' << glyph])} #{link_text}".html_safe
      inserted_html << yield if block_given?
      inserted_html
    end
  end

  def help_link
    link_with_glyph(
      '',
      HELP_LINK,
      'question-sign',
      {
        class: HELP_LINK_HTML_CLASS,
        # `target: blank` option ensures that this link will be opened in a new tab
        target: 'blank',
        title: 'Help',
        data: { toggle: 'tooltip' }
      }
    )
  end

  # @input [String] dismiss_element Element type to dismiss, such as "alert" or "modal"
  def self.close_button(dismiss_element)
    "<button type='button' class='close' data-dismiss='#{dismiss_element}'><span aria-hidden='true'>&times;</span><span class='sr-only'>Close</span></button>"
  end
  def self.label_for_required(label)
    "<abbr title='required'>*</abbr> #{label}".html_safe
  end

  def action_timeout_enabled?
    ApplicationHelper::ACTION_TIMEOUT > 0
  end

  def hand_number(match_)
    if match_.hand_number then match_.hand_number else 0 end
  end

  def hands_completed(match_)
    "#{hand_number(match_)} / #{match_.number_of_hands} hands completed"
  end
end
