# What one external source last said about a match. Sync::Resolver merges
# the reports of every source into the Match itself.
class MatchReport < ApplicationRecord
  SOURCES = %w[auf tenfield wikipedia].freeze

  belongs_to :match

  enum :walkover_winner, { home: "home", away: "away" }, prefix: true

  validates :source, inclusion: { in: SOURCES }, uniqueness: { scope: :match_id }

  def score? = home_goals.present? && away_goals.present?

  def score = [ home_goals, away_goals, home_penalties, away_penalties ]
end
