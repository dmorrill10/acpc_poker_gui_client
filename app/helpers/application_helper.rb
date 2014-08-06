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
    ApplicationHelper.const_set(constant, val) unless const_defined? constant
  end

  def html_element_name_to_class(element)
    "#{HTML_CLASS_PREFIX}#{element}"
  end

  def app_html_element
    html_element_name_to_class(APP_VIEW_HTML_CLASS)
  end

  def link_with_glyph(link_text, link_target, glyph, options={})
    link_to link_target, options do
      inserted_html = "#{content_tag(:i, nil, class: 'icon-' << glyph)} #{link_text}".html_safe
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
end