# Points and matches from previous seasons, used for the relegation average.
class HistoricalRecord < ApplicationRecord
  belongs_to :team
  belongs_to :competition

  validates :year, presence: true, uniqueness: { scope: [ :competition_id, :team_id ] }
end
