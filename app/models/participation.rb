class Participation < ApplicationRecord
  belongs_to :team
  belongs_to :season

  validates :team_id, uniqueness: { scope: :season_id }
end
