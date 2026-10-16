class Competition < ApplicationRecord
  has_many :seasons, -> { order(year: :desc) }, dependent: :destroy
  has_many :historical_records, dependent: :destroy

  validates :name, :slug, :tier, presence: true
  validates :slug, uniqueness: true

  scope :by_tier, -> { order(:tier) }

  def current_season
    seasons.find_by(current: true) || seasons.first
  end

  def to_param = slug
end
