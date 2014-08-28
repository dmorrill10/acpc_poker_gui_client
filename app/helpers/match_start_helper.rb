require 'json'

module MatchStartHelper
  def self.read_constants
    File.read(
      Rails.root.join('app', 'constants', 'match_start.json')
    )
  end

  JSON.parse(read_constants).each do |constant, val|
    MatchStartHelper.const_set(constant, val) unless const_defined? constant
  end
end