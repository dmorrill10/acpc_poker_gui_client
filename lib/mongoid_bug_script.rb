#!/usr/bin/env ruby
require_relative 'database_config'
require_relative '../app/models/user'
# class ModelWithHash
#   include Mongoid::Document

#   field :hash_attr, type: Hash
# end

model = User.new name: 'name'
model.hotkeys = User.default_hotkeys
puts model.save # Prints true
after_update = User.find(model.id)
puts after_update.hotkeys # Prints nil when it should be the hash set above
after_update.hotkeys = {'key without period' => 'arbitrary value'}
puts after_update.save
after_second_update = User.find(after_update.id)
puts after_second_update.hotkeys # Prints