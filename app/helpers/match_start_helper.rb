require 'json'

module MatchStartPartialPaths
  def match_start_partial(relative_path)
    File.join('match_start', relative_path)
  end
end

module MatchStartHelper
  include MatchStartPartialPaths

  def self.read_constants
    File.read(
      Rails.root.join('app', 'constants', 'match_start.json')
    )
  end

  JSON.parse(read_constants).each do |constant, val|
    MatchStartHelper.const_set(constant, val) unless const_defined? constant
  end
end