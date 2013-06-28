
require 'mongoid'

require_relative '../../lib/application_defs'

class User
  include Mongoid::Document

  def self.default_user_name() 'Guest' end

  def self.include_name
    field :name
    validates_presence_of :name
    validates_format_of :name, without: /^\s*$/
  end

  include_name

  # @return [Hash<String, Hash<String, String>] Hotkey labels to hotkey parameters mapping,
  #   where the parameters must at least include +'key'+, the key in JQuery.hotkeys format,
  #   and may include +'element_to_click'+,
  #   which should represent an HTML element to click upon activating the hotkey.
  field :hotkeys, type: Hash

  MIN_WAGER_LABEL = 'Min'
  ALL_IN_WAGER_LABEL = 'All-in'
  def self.wager_hotkey_label(pot_fraction)
    "#{pot_fraction}xPot"
  end
  # @return [Numeric] The pot fraction corresponding to this hotkey label,
  #   or zero if the hotkey doesn't correspond to a pot fraction wager.
  def self.hotkey_pot_fraction(label)
    label.to_f
  end
  def self.wager_hotkey?(label)
    hotkey_pot_fraction(label) > 0.0 || label == MIN_WAGER_LABEL || label == ALL_IN_WAGER_LABEL
  end
  DEFAULT_HOTKEYS = {
    'Fold' => {
      'element_to_click' => ".fold",
      'key' => 'A'
    },
    'Check / Call' => {
      'element_to_click' => ".pass",
      'key' => 'S'
    },
    'Bet / Raise' => {
      'element_to_click' => ".wager",
      'key' => 'D'
    },
    'Next Hand' => {
      'element_to_click' => ".next_state",
      'key' => 'F'
    },
    'Leave Match' => {
      'element_to_click' => ".leave",
      'key' => 'Q'
    },
    MIN_WAGER_LABEL => {
      'key' => 'Z'
    },
    ALL_IN_WAGER_LABEL => {
      'key' => 'N'
    },
    wager_hotkey_label(1/2.to_f) => {
      'key' => 'X'
    },
    wager_hotkey_label(3/4.to_f) => {
      'key' => 'C'
    },
    wager_hotkey_label(1) => {
      'key' => 'V'
    },
    wager_hotkey_label(2) => {
      'key' => 'B'
    }
  }

  def reset_hotkeys!
    self.hotkeys = DEFAULT_HOTKEYS
    save!

    self
  end
end