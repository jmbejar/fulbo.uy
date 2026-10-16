class Season < ApplicationRecord
  belongs_to :competition
  has_many :stages, -> { order(:position) }, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :teams, through: :participations
  has_many :matches, through: :stages
  has_many :external_ids, as: :identifiable, dependent: :destroy

  attribute :annual_zones, default: -> { [] }
  attribute :relegation_zones, default: -> { [] }

  validates :year, presence: true, uniqueness: { scope: :competition_id }

  def current_stage
    stages.find_by(current: true) || stages.last
  end

  def annual_stages = stages.where(counts_for_annual: true)

  def annual? = annual_stages.many?

  def relegation? = relegation_years.positive?
end
