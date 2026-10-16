class Team < ApplicationRecord
  has_many :team_aliases, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :seasons, through: :participations
  has_many :group_memberships, dependent: :destroy
  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, dependent: :destroy
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, dependent: :destroy
  has_many :points_adjustments, dependent: :destroy
  has_many :historical_records, dependent: :destroy
  has_many :external_ids, as: :identifiable, dependent: :destroy

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  def self.find_by_name_or_alias(name)
    find_by(name: name) || joins(:team_aliases).find_by(team_aliases: { name: name })
  end

  def matches = Match.involving(self)

  def display_name = short_name.presence || name

  def to_param = slug
end
