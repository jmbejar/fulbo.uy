class Stage < ApplicationRecord
  TIEBREAKERS = %w[goal_difference goals_for head_to_head lots].freeze

  belongs_to :season
  has_many :groups, -> { order(:position) }, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :points_adjustments, dependent: :destroy
  has_many :external_ids, as: :identifiable, dependent: :destroy

  enum :format, { round_robin: "round_robin", groups: "groups", knockout: "knockout" }, prefix: true

  attribute :tiebreakers, default: -> { TIEBREAKERS }
  attribute :zones, default: -> { [] }
  attribute :round_names, default: -> { [] }

  validates :name, :slug, presence: true
  validates :slug, uniqueness: { scope: :season_id }
  validate :known_tiebreakers

  def to_param = slug

  def teams
    if format_groups?
      Team.joins(:group_memberships).where(group_memberships: { group_id: groups.select(:id) }).distinct
    elsif matches.exists?
      Team.where(id: matches.select(:home_team_id)).or(Team.where(id: matches.select(:away_team_id)))
    else
      season.teams
    end
  end

  def rounds = matches.distinct.order(:round).pluck(:round).compact

  # Knockout stages name their rounds ("Octavos de final"); others number them.
  def round_name(round)
    round_names[round - 1] if round&.positive?
  end

  private

  def known_tiebreakers
    unknown = Array(tiebreakers) - TIEBREAKERS
    errors.add(:tiebreakers, :unknown, list: unknown.join(", ")) if unknown.any?
  end
end
