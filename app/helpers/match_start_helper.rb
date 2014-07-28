require 'json'
require_relative '../../lib/application_defs'

module MatchStartHelper
  def self.read_constants
    ApplicationDefs.read_constants(
      Rails.root.join('app', 'constants', 'match_start.json')
    )
  end

  JSON.parse(read_constants).each do |constant, val|
    MatchStartHelper.const_set(constant, val) unless const_defined? constant
  end

  def self.label_for_required(label)
    "<abbr title='required'>*</abbr> #{label}".html_safe
  end

  def matches_to_join
    @matches_to_join ||= Match.asc(:name).all.select do |m|
      !m.name_from_user.match(/^_+$/) &&
      m.slices.empty? &&
      !m.human_opponent_seats(user.name).empty?
    end
  end
  def seats_to_join
    matches_to_join.inject({}) do |hash, lcl_match|
      hash[lcl_match.name] = lcl_match.rejoinable_seats(user.name).sort
      hash
    end
  end

  def matches_to_rejoin
    @matches_to_rejoin ||= Match.asc(:name).all.select do |m|
      m.user_name == user_name &&
      !m.name_from_user.match(/^_+$/) &&
      !m.finished? &&
      !m.slices.empty?
    end
  end
  def seats_to_rejoin
    matches_to_rejoin.sort_by{ |m| m.name }.inject({}) do |hash, lcl_match|
      hash[lcl_match.name] = lcl_match.human_opponent_seats
      hash[lcl_match.name] << lcl_match.seat unless hash[lcl_match.name].include?(lcl_match.seat)
      hash[lcl_match.name].sort!
      hash
    end
  end
end