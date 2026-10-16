class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.references :stage, null: false, foreign_key: true
      t.references :group, foreign_key: true
      t.integer :round
      t.datetime :kicks_off_at
      t.references :home_team, null: false, foreign_key: { to_table: :teams }
      t.references :away_team, null: false, foreign_key: { to_table: :teams }
      t.integer :home_goals
      t.integer :away_goals
      t.integer :home_penalties
      t.integer :away_penalties
      t.string :status, null: false, default: "scheduled"

      t.timestamps
    end
    add_index :matches, [ :stage_id, :round ]
  end
end
