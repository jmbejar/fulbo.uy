class CreateParticipations < ActiveRecord::Migration[8.0]
  def change
    create_table :participations do |t|
      t.references :team, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true

      t.timestamps
    end
    add_index :participations, [ :season_id, :team_id ], unique: true

    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
    add_index :group_memberships, [ :group_id, :team_id ], unique: true
  end
end
