class Group < ApplicationRecord
  belongs_to :stage
  has_many :group_memberships, dependent: :destroy
  has_many :teams, through: :group_memberships
  has_many :matches, dependent: :nullify

  validates :name, presence: true
end
