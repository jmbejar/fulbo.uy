class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :team

  validates :team_id, uniqueness: { scope: :group_id }
end
