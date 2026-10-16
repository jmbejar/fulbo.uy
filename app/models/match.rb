class Match < ApplicationRecord
  belongs_to :stage, touch: true
  belongs_to :group, optional: true
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  has_many :external_ids, as: :identifiable, dependent: :destroy
  has_many :reports, class_name: "MatchReport", dependent: :destroy

  enum :status, {
    scheduled: "scheduled", live: "live", finished: "finished",
    suspended: "suspended", postponed: "postponed", walkover: "walkover"
  }
  enum :walkover_winner, { home: "home", away: "away" }, prefix: true

  validates :home_goals, :away_goals, presence: true, if: -> { finished? || live? }
  validates :walkover_winner, presence: true, if: :walkover?
  validate :distinct_teams

  scope :involving, ->(team) { where(home_team: team).or(where(away_team: team)) }
  scope :chronological, -> { order(:round, :kicks_off_at, :id) }
  scope :recent_first, -> { order(kicks_off_at: :desc, id: :desc) }
  # Matches that count for the standings: played, or awarded by walkover.
  scope :decided, -> { where(status: [ :finished, :walkover ]) }

  def decided? = finished? || walkover?

  def score? = home_goals.present? && away_goals.present?

  def penalties? = home_penalties.present? && away_penalties.present?

  # Points-wise result from the home side's view: 1 win, 0 draw, -1 loss.
  def home_outcome
    return walkover_winner_home? ? 1 : -1 if walkover?

    home_goals <=> away_goals
  end

  private

  def distinct_teams
    errors.add(:away_team, :taken) if home_team_id == away_team_id
  end
end
