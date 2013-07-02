require 'mongoid'

class User
  include Mongoid::Document

  DEFAULT_NAME = 'Guest'

  def self.include_name
    field :name
    validates_presence_of :name
    validates_format_of :name, without: /^\s*$/
    validates_uniqueness_of :name
  end

  def self.include_hotkeys
    # @return [Hash<String, String>] Hotkey labels to key mapping
    field :hotkeys, type: Hash
    validates_presence_of :hotkeys
  end

  include_name
  include_hotkeys

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
  # @return [Numeric] The pot fraction corresponding to this hotkey label,
  #   or zero if the hotkey doesn't correspond to a pot fraction wager.
  def self.hotkey_pot_fraction(label)
    (if POT_LABEL == label then 1 else label end).to_f
  end
  def self.wager_hotkey?(label)
    hotkey_pot_fraction(label) > 0.0 || label == MIN_WAGER_LABEL || label == ALL_IN_WAGER_LABEL
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

  def reset_hotkeys!
    self.hotkeys = self.class::DEFAULT_HOTKEYS
    save!

    self
  end
end