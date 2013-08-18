require 'mongoid'

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
  FOLD_LABEL = 'Fold'
  PASS_LABEL = 'Check / Call'
  WAGER_LABEL = 'Bet / Raise'
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
    FOLD_LABEL => ".fold",
    PASS_LABEL => ".pass",
    WAGER_LABEL => ".wager",
    NEXT_HAND_LABEL => ".next_state",
    LEAVE_MATCH_LABEL => ".leave"
  }
  DEFAULT_HOTKEYS = {
    FOLD_LABEL => 'A',
    PASS_LABEL => 'S',
    WAGER_LABEL => 'D',
    NEXT_HAND_LABEL => 'F',
    LEAVE_MATCH_LABEL => 'Q',
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