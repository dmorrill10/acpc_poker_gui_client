require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/hand'
require 'acpc_poker_types/suit'
require_relative 'application_helper'

# Define constants
module PlayerActionsHelper
  def self.read_constants
    File.read(
      Rails.root.join('app', 'constants', 'player_actions.json')
    )
  end

  JSON.parse(read_constants).each do |constant, val|
    PlayerActionsHelper.const_set(constant, val) unless const_defined? constant
  end
end

module HotkeysPresentation
  def hotkey_field_tag(name, initial_value='', options={})
    text_field_tag name, initial_value, options.merge(maxlength: 1, size: 1, name: "#{PlayerActionsHelper::CUSTOMIZE_HOTKEYS_ID}[#{name}]")
  end

  # Assumes that it will be called right after the corresponding custom_hotkey_amount_field_tag call
  def custom_hotkey_key_field_tag
    text_field_tag "custom_key", '', maxlength: 1, size: 1, name: "#{PlayerActionsHelper::CUSTOMIZE_HOTKEYS_KEYS_HASH_KEY}[]"
  end

  def custom_hotkey_amount_field_tag
    number_field_tag(
      "custom_amount",
      '',
      maxlength: 4,
      size: 4,
      name: "#{PlayerActionsHelper::CUSTOMIZE_HOTKEYS_AMOUNT_KEY}[]",
      min: 0,
      max: 9999,
      step: 0.01
    )
  end
end

module PlayerActionPartialPaths
  def player_actions_partial(relative_path)
    File.join('player_actions', relative_path)
  end
  def navbar_partial(relative_path)
    player_actions_partial(File.join('navbar', relative_path))
  end
  def hotkeys_partial(relative_path)
    navbar_partial(File.join('hotkeys', relative_path))
  end
  def game_interface_partial(relative_path)
    player_actions_partial(File.join('game_interface', relative_path))
  end
  def poker_table_partial(relative_path)
    game_interface_partial(File.join('table', relative_path))
  end
  def poker_controls_partial(relative_path)
    game_interface_partial(File.join('controls', relative_path))
  end
  def hud_partial(relative_path)
    player_actions_partial(File.join('hud', relative_path))
  end
end

module PlayerActionsHelper
  include AcpcPokerTypes
  include ApplicationHelper
  include HotkeysPresentation
  include PlayerActionPartialPaths

  def html_character(suit_symbol)
    Suit::DOMAIN[suit_symbol][:html_character]
  end

  def dealer_button
    haml_tag(:div, class: DEALER_BUTTON_HTML_CLASS) { haml_concat 'Dealer' }
  end
end