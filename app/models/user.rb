require 'mongoid'

require_relative 'hotkey'

class User
  include Mongoid::Document

  embeds_many :hotkeys, class_name: "Hotkey"

  DEFAULT_NAME = 'Guest'

  def self.include_name
    field :name
    validates_presence_of :name
    validates_format_of :name, without: /^\s*$/
    validates_uniqueness_of :name
  end

  include_name

  def reset_hotkeys!
    hotkeys.delete_all
    Hotkey::DEFAULT_HOTKEYS.each do |action, key|
      hotkeys.create! action: action, key: key
    end
    save!

    self
  end
end