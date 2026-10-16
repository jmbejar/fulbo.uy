class Match < ApplicationRecord
  belongs_to :stage, touch: true
  belongs_to :group, optional: true
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  has_many :external_ids, as: :identifiable, dependent: :destroy

  enum :status, {
    scheduled: "scheduled", live: "live", finished: "finished",
    suspended: "suspended", postponed: "postponed"
  }

  validates :home_goals, :away_goals, presence: true, if: -> { finished? || live? }
  validate :distinct_teams

  scope :involving, ->(team) { where(home_team: team).or(where(away_team: team)) }
  scope :chronological, -> { order(:round, :kicks_off_at, :id) }
  scope :recent_first, -> { order(kicks_off_at: :desc, id: :desc) }

  def score? = home_goals.present? && away_goals.present?

  def penalties? = home_penalties.present? && away_penalties.present?

  private

  def distinct_teams
    errors.add(:away_team, :taken) if home_team_id == away_team_id
  end
end
