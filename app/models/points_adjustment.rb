class PointsAdjustment < ApplicationRecord
  belongs_to :team
  belongs_to :stage, touch: true

  validates :points, presence: true, numericality: { other_than: 0 }
end
