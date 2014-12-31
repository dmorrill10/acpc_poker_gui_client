require 'mongoid'

# @todo Loading these constants here and duplicating PlayerActionsHelper in part
# is like using a sledgehammer as a fly swatter but it's fine for now.
module PlayerActionsHelper
  def self.read_constants
    File.read(File.expand_path('../../constants/player_actions.json', __FILE__))
  end

  JSON.parse(read_constants).each do |constant, val|
    PlayerActionsHelper.const_set(constant, val) unless const_defined? constant
  end

  JSON.parse(File.read(File.expand_path('../../constants/application.json', __FILE__))).each do |constant, val|
    PlayerActionsHelper.const_set(constant, val) unless const_defined? constant
  end

  def self.html_element_name_to_class(element)
    "#{HTML_CLASS_PREFIX}#{element}"
  end
end

class Hotkey
  include Mongoid::Document

  embedded_in :user, inverse_of: :hotkeys

  def self.include_action
    field :action, type: String
    validates_presence_of :action
    validates_format_of :action, without: /^\s*$/
    validates_uniqueness_of :action
  end

  include_action

  def self.include_key
    field :key, type: String
    validates_presence_of :key
    validates_format_of :key, without: /^\s*$/
    validates_uniqueness_of :key
  end

  include_action
  include_key

  MIN_WAGER_LABEL = 'Min'
  ALL_IN_WAGER_LABEL = 'All-in'
  FOLD_LABEL = PlayerActionsHelper::FOLD_LABEL
  PASS_LABEL = "#{PlayerActionsHelper::CHECK_LABEL} / #{PlayerActionsHelper::CALL_LABEL}"
  WAGER_LABEL = "#{PlayerActionsHelper::BET_LABEL} / #{PlayerActionsHelper::RAISE_LABEL}"
  NEXT_HAND_LABEL = 'Next Hand'
  LEAVE_MATCH_LABEL = 'Leave Match'
  POT_LABEL = 'Pot'

  # Round to avoid unreasonably large strings
  MAX_POT_FRACTION_PRECISION = 4
  def self.wager_hotkey_label(pot_fraction)
    if pot_fraction == 1
      POT_LABEL
    elsif pot_fraction.to_i == pot_fraction
      "#{pot_fraction.to_i}xPot"
    else
      "#{pot_fraction.round(MAX_POT_FRACTION_PRECISION)}xPot"
    end
  end

  HOTKEY_LABELS_TO_ELEMENTS_TO_CLICK = {
    FOLD_LABEL => PlayerActionsHelper.html_element_name_to_class(PlayerActionsHelper::FOLD_HTML_CLASS),
    PASS_LABEL => PlayerActionsHelper.html_element_name_to_class(PlayerActionsHelper::PASS_HTML_CLASS),
    WAGER_LABEL => PlayerActionsHelper.html_element_name_to_class(PlayerActionsHelper::WAGER_HTML_CLASS),
    NEXT_HAND_LABEL => PlayerActionsHelper.html_element_name_to_class(PlayerActionsHelper::NEXT_HAND_ID),
    LEAVE_MATCH_LABEL => PlayerActionsHelper.html_element_name_to_class(PlayerActionsHelper::NAV_LEAVE_HTML_CLASS)
  }
  META_HOTKEYS = {
    NEXT_HAND_LABEL => 'F',
    LEAVE_MATCH_LABEL => 'Q'
  }
  LIMIT_HOTKEYS = {
    FOLD_LABEL => 'A',
    PASS_LABEL => 'S',
    WAGER_LABEL => 'D'
  }
  NO_LIMIT_HOTKEYS = {
    MIN_WAGER_LABEL => 'Z',
    ALL_IN_WAGER_LABEL => 'N',
    wager_hotkey_label(1/2.to_f) => 'X',
    wager_hotkey_label(3/4.to_f) => 'C',
    wager_hotkey_label(1) => 'V',
    wager_hotkey_label(2) => 'B'
  }

  # @return [Numeric] The pot fraction corresponding to this hotkey label,
  #   or zero if the hotkey doesn't correspond to a pot fraction wager.
  def hotkey_pot_fraction
    (if POT_LABEL == action then 1 else action end).to_f
  end
  def wager_hotkey?
    (
      hotkey_pot_fraction > 0.0 ||
      action == MIN_WAGER_LABEL ||
      action == ALL_IN_WAGER_LABEL
    )
  end
end