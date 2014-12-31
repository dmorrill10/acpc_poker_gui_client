require 'mongoid'

require_relative 'hotkey'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module Hotkeys
  def self.included(klass)
    klass.class_eval do
      exceptions :conflicting_hotkeys
    end
  end

  # Re-define this to set application specific defaults
  # @return [Hash<String, String>] Hash of function-key pairs
  def default_hotkeys() {} end

  def reset_hotkeys!
    hotkeys.delete_all
    default_hotkeys.each do |action, key|
      hotkeys.create! action: action, key: key
    end
    save!
    self
  end

  def update_hotkeys!(hotkey_hash)
    conflicting_hotkeys = []
    hotkey_hash.each do |action_label, new_key|
      if new_key.blank?
        # Delete custom hotkeys that have been left blank
        unless default_hotkeys.include?(action_label)
          hotkeys.where(action: action_label).delete
        end
        next
      end
      next if action_label.blank?
      new_key = new_key.strip.capitalize
      next unless change?(action_label, new_key)

      conflicted_hotkey = hotkeys.select do |hotkey|
        hotkey.key == new_key
      end.first
      if conflicted_hotkey
        conflicted_label = conflicted_hotkey.action
        if conflicted_label
          conflicting_hotkeys << (
            {
              key: new_key,
              current_label: conflicted_label,
              new_label: action_label
            }
          )
          next
        end
      end

      previous_hotkey = hotkeys.where(action: action_label).first
      if previous_hotkey
        previous_hotkey.key = new_key
        previous_hotkey.save!
      else
        hotkeys.create! action: action_label, key: new_key
      end
    end
    save!

    unless conflicting_hotkeys.empty?
      raise(
        self.class::ConflictingHotkeys.new(
          conflicting_hotkeys.map do |conflict|
            "- You tried to set '#{conflict[:new_label]}' " +
            "to '#{conflict[:key]}' when it was already mapped " +
            "to '#{conflict[:current_label]}'"
          end.join("\n")
        )
      )
    end
  end

  protected

  def change?(action_label, new_key)
    old_key = hotkeys.where(action: action_label).first
    old_key.nil? || old_key.key != new_key
  end
end

class UserBase
  include Mongoid::Document
  include Hotkeys

  embeds_many :hotkeys, class_name: "Hotkey"

  DEFAULT_NAME = 'Guest'

  after_create :reset_hotkeys!

  def self.include_name
    field :name
    validates_presence_of :name
    validates_format_of :name, without: /^\s*$/
    validates_uniqueness_of :name
  end

  include_name
  field :password_hash
  field :password_salt

  def encrypt_password!(password)
    self.password_salt = BCrypt::Engine.generate_salt
    self.password_hash = BCrypt::Engine.hash_secret(password, self.password_salt)
    self
  end
  def authentic?(password)
    (
      self.password_salt.nil? ||
      self.password_hash == BCrypt::Engine.hash_secret(password, self.password_salt)
    )
  end

  def default_hotkeys
    Hotkey::META_HOTKEYS.merge Hotkey::LIMIT_HOTKEYS
  end
end

class UserNoLimit < UserBase
  def default_hotkeys
    super.merge Hotkey::NO_LIMIT_HOTKEYS
  end
end
