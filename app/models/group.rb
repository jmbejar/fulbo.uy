class Group < ApplicationRecord
  belongs_to :stage
  has_many :group_memberships, dependent: :destroy
  has_many :teams, through: :group_memberships
  has_many :matches, dependent: :nullify
  has_many :external_ids, as: :identifiable, dependent: :destroy

  validates :name, presence: true
end
